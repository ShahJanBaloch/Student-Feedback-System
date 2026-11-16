-- University of Turbat student registration. Existing tenant rows and enrollment
-- data are retained; active registration no longer checks institution approval.

alter table public.academic_programs
  add constraint academic_programs_id_department_key
  unique (id, department_id);

with ranked_current_sessions as (
  select
    id,
    row_number() over (
      partition by institution_id
      order by starts_on desc, created_at desc, id desc
    ) as position
  from public.academic_sessions
  where is_current
)
update public.academic_sessions s
set is_current = false
from ranked_current_sessions ranked
where ranked.id = s.id
  and ranked.position > 1;

create unique index academic_sessions_one_current_per_institution
  on public.academic_sessions (institution_id)
  where is_current;

create table public.academic_semesters (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  department_id uuid not null,
  program_id uuid not null,
  semester_number smallint not null check (semester_number between 1 and 16),
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (id, program_id),
  unique (program_id, semester_number),
  foreign key (department_id, institution_id)
    references public.departments (id, institution_id)
    on delete cascade,
  foreign key (program_id, institution_id)
    references public.academic_programs (id, institution_id)
    on delete cascade,
  foreign key (program_id, department_id)
    references public.academic_programs (id, department_id)
    on delete cascade
);

create trigger academic_semesters_set_updated_at
before update on public.academic_semesters
for each row execute function public.set_updated_at();

alter table public.academic_semesters enable row level security;
alter table public.academic_semesters force row level security;

create policy academic_semesters_select
  on public.academic_semesters for select to authenticated
  using (public.is_institution_member(institution_id));

create policy academic_semesters_write
  on public.academic_semesters for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

grant select, insert, update, delete on public.academic_semesters
  to authenticated;

create or replace function public.create_uot_academic_session(
  p_name text,
  p_starts_on date,
  p_ends_on date,
  p_is_current boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_institution_id uuid;
  v_session_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select i.id into v_institution_id
  from public.institutions i
  where lower(i.short_code) = 'uot';

  if v_institution_id is null
     or not public.has_role(v_institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if length(trim(coalesce(p_name, ''))) = 0 or p_ends_on < p_starts_on then
    raise exception 'academic session name and valid dates are required'
      using errcode = '22023';
  end if;

  if p_is_current then
    update public.academic_sessions
    set is_current = false
    where institution_id = v_institution_id
      and is_current;
  end if;

  insert into public.academic_sessions (
    institution_id, name, starts_on, ends_on, is_current
  ) values (
    v_institution_id, trim(p_name), p_starts_on, p_ends_on, p_is_current
  )
  returning id into v_session_id;

  perform public.write_audit(
    'uot_academic_session_created',
    'academic_sessions',
    v_session_id,
    v_institution_id,
    jsonb_build_object('is_current', p_is_current)
  );

  return v_session_id;
end;
$$;

alter table public.academic_classes
  add column semester_id uuid;

alter table public.academic_classes
  add constraint academic_classes_semester_program_fkey
  foreign key (semester_id, program_id)
  references public.academic_semesters (id, program_id)
  on delete restrict;

alter table public.student_enrollments
  add column department_id uuid,
  add column semester_id uuid;

alter table public.student_enrollments
  add constraint student_enrollments_department_fkey
    foreign key (department_id, institution_id)
    references public.departments (id, institution_id)
    on delete restrict,
  add constraint student_enrollments_program_department_fkey
    foreign key (program_id, department_id)
    references public.academic_programs (id, department_id)
    on delete restrict,
  add constraint student_enrollments_semester_program_fkey
    foreign key (semester_id, program_id)
    references public.academic_semesters (id, program_id)
    on delete restrict;

create or replace function public.uot_student_registration_options()
returns table (
  department_id uuid,
  department_name text,
  program_id uuid,
  program_name text,
  semester_id uuid,
  semester_number smallint,
  semester_name text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    d.id,
    d.name,
    p.id,
    p.name,
    s.id,
    s.semester_number,
    s.name
  from public.institutions i
  join public.departments d on d.institution_id = i.id and d.is_active
  join public.academic_programs p
    on p.institution_id = i.id
   and p.department_id = d.id
   and p.is_active
  join public.academic_semesters s
    on s.institution_id = i.id
   and s.department_id = d.id
   and s.program_id = p.id
   and s.is_active
  where lower(i.short_code) = 'uot'
  order by d.name, p.name, s.semester_number;
$$;

create or replace function public.request_uot_student_verification(
  p_department_id uuid,
  p_program_id uuid,
  p_semester_id uuid,
  p_student_number text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_institution_id uuid;
  v_session_id uuid;
  v_enrollment_id uuid;
  v_existing_status public.verification_status;
  v_request_id uuid;
  v_full_name text;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if length(trim(coalesce(p_student_number, ''))) < 3 then
    raise exception 'student registration number is required'
      using errcode = '22023';
  end if;

  select i.id into v_institution_id
  from public.institutions i
  where lower(i.short_code) = 'uot';

  if v_institution_id is null then
    raise exception 'University of Turbat is not configured'
      using errcode = 'P0002';
  end if;

  if not exists (
    select 1
    from public.academic_semesters s
    join public.academic_programs p
      on p.id = s.program_id
     and p.institution_id = s.institution_id
    join public.departments d
      on d.id = s.department_id
     and d.institution_id = s.institution_id
    where s.id = p_semester_id
      and s.program_id = p_program_id
      and s.department_id = p_department_id
      and s.institution_id = v_institution_id
      and s.is_active
      and p.is_active
      and d.is_active
  ) then
    raise exception 'selected UOT department, program, or semester is invalid'
      using errcode = '22023';
  end if;

  select s.id into v_session_id
  from public.academic_sessions s
  where s.institution_id = v_institution_id
    and s.is_current
  order by s.starts_on desc
  limit 1;

  if v_session_id is null then
    raise exception 'UOT must configure a current academic session'
      using errcode = 'P0001';
  end if;

  select p.full_name into v_full_name
  from public.profiles p
  where p.id = auth.uid();

  select e.id, e.verification_status
  into v_enrollment_id, v_existing_status
  from public.student_enrollments e
  where e.user_id = auth.uid()
    and e.institution_id = v_institution_id
    and e.session_id = v_session_id
  for update;

  if v_existing_status = 'verified' then
    raise exception 'student enrollment is already verified'
      using errcode = 'P0001';
  end if;

  if v_enrollment_id is null then
    insert into public.student_enrollments (
      institution_id,
      user_id,
      department_id,
      program_id,
      semester_id,
      session_id,
      student_number,
      verification_status
    ) values (
      v_institution_id,
      auth.uid(),
      p_department_id,
      p_program_id,
      p_semester_id,
      v_session_id,
      trim(p_student_number),
      'pending'
    )
    returning id into v_enrollment_id;
  else
    update public.student_enrollments
    set department_id = p_department_id,
        program_id = p_program_id,
        semester_id = p_semester_id,
        student_number = trim(p_student_number),
        verification_status = 'pending',
        roster_entry_id = null
    where id = v_enrollment_id;
  end if;

  insert into public.institution_memberships (
    user_id, institution_id, role, status
  ) values (
    auth.uid(), v_institution_id, 'student', 'pending'
  )
  on conflict (user_id, institution_id, role)
    where institution_id is not null
    do nothing;

  update public.access_requests
  set status = 'cancelled',
      decided_by = auth.uid(),
      decided_at = now(),
      decision_reason = 'superseded_by_new_registration'
  where requester_id = auth.uid()
    and institution_id = v_institution_id
    and request_type = 'student_verification'
    and status = 'pending'
    and payload->>'enrollment_id' = v_enrollment_id::text;

  insert into public.access_requests (
    requester_id, institution_id, request_type, status, payload
  ) values (
    auth.uid(),
    v_institution_id,
    'student_verification',
    'pending',
    jsonb_build_object(
      'enrollment_id', v_enrollment_id,
      'student_number', trim(p_student_number),
      'full_name', coalesce(v_full_name, ''),
      'department_id', p_department_id,
      'program_id', p_program_id,
      'semester_id', p_semester_id,
      'department_name', (
        select d.name from public.departments d where d.id = p_department_id
      ),
      'program_name', (
        select p.name from public.academic_programs p where p.id = p_program_id
      ),
      'semester_name', (
        select s.name from public.academic_semesters s where s.id = p_semester_id
      )
    )
  )
  returning id into v_request_id;

  perform public.write_audit(
    'uot_student_registration_submitted',
    'student_enrollments',
    v_enrollment_id,
    v_institution_id,
    jsonb_build_object('request_id', v_request_id)
  );

  return v_request_id;
end;
$$;

create or replace function public.decide_student_verification(
  p_request_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_request public.access_requests%rowtype;
  v_enrollment_id uuid;
  v_enrollment public.student_enrollments%rowtype;
begin
  select * into v_request
  from public.access_requests
  where id = p_request_id
    and request_type = 'student_verification'
    and status = 'pending'
  for update;

  if not found then
    raise exception 'pending UOT student request not found'
      using errcode = 'P0002';
  end if;

  if not exists (
    select 1
    from public.institutions i
    where i.id = v_request.institution_id
      and lower(i.short_code) = 'uot'
  ) or not public.has_role(v_request.institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  begin
    v_enrollment_id := (v_request.payload->>'enrollment_id')::uuid;
  exception when invalid_text_representation then
    raise exception 'invalid enrollment reference' using errcode = '22023';
  end;

  select * into v_enrollment
  from public.student_enrollments e
  where e.id = v_enrollment_id
    and e.user_id = v_request.requester_id
    and e.institution_id = v_request.institution_id
    and e.verification_status = 'pending'
  for update;

  if not found then
    raise exception 'pending student enrollment not found'
      using errcode = 'P0002';
  end if;

  update public.access_requests
  set status = case when p_approve then 'approved' else 'rejected' end,
      decided_by = auth.uid(),
      decided_at = now(),
      decision_reason = coalesce(p_reason, case when p_approve then 'verified' else 'rejected' end)
  where id = p_request_id;

  update public.student_enrollments
  set verification_status = case when p_approve then 'verified' else 'rejected' end
  where id = v_enrollment_id;

  if p_approve then
    insert into public.institution_memberships (
      user_id, institution_id, role, status, assigned_by
    ) values (
      v_request.requester_id,
      v_request.institution_id,
      'student',
      'active',
      auth.uid()
    )
    on conflict (user_id, institution_id, role)
      where institution_id is not null
      do update set status = 'active', assigned_by = auth.uid();

    insert into public.student_class_enrollments (
      institution_id, enrollment_id, class_id
    )
    select v_enrollment.institution_id, v_enrollment.id, c.id
    from public.academic_classes c
    where c.institution_id = v_enrollment.institution_id
      and c.program_id = v_enrollment.program_id
      and c.session_id = v_enrollment.session_id
      and c.semester_id = v_enrollment.semester_id
    on conflict (enrollment_id, class_id) do nothing;
  else
    update public.institution_memberships
    set status = 'rejected', assigned_by = auth.uid()
    where user_id = v_request.requester_id
      and institution_id = v_request.institution_id
      and role = 'student'
      and status = 'pending';
  end if;

  perform public.write_audit(
    case when p_approve then 'uot_student_verified' else 'uot_student_rejected' end,
    'access_requests',
    p_request_id,
    v_request.institution_id,
    jsonb_build_object(
      'enrollment_id', v_enrollment_id,
      'reason', coalesce(p_reason, '')
    )
  );

  perform public.notify_user(
    v_request.requester_id,
    v_request.institution_id,
    'system',
    case when p_approve then 'Student registration verified' else 'Student registration rejected' end,
    case when p_approve
      then 'Your University of Turbat student registration is verified.'
      else coalesce(p_reason, 'Your student registration requires correction.')
    end,
    jsonb_build_object('request_id', p_request_id)
  );
end;
$$;

revoke all on function public.uot_student_registration_options()
  from public, anon;
revoke all on function public.create_uot_academic_session(text, date, date, boolean)
  from public, anon;
revoke all on function public.request_uot_student_verification(uuid, uuid, uuid, text)
  from public, anon;
grant execute on function public.uot_student_registration_options()
  to authenticated;
grant execute on function public.create_uot_academic_session(text, date, date, boolean)
  to authenticated;
grant execute on function public.request_uot_student_verification(uuid, uuid, uuid, text)
  to authenticated;

revoke all on function public.request_student_verification(uuid, text, text)
  from public, anon, authenticated;
revoke update on public.access_requests from authenticated;