create table public.hod_department_assignments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  department_id uuid not null,
  user_id uuid not null references public.profiles (id) on delete cascade,
  assigned_by uuid references public.profiles (id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (institution_id, department_id, user_id),
  foreign key (department_id, institution_id)
    references public.departments (id, institution_id)
    on delete cascade
);

create index hod_department_assignments_user_idx
  on public.hod_department_assignments (user_id, is_active);

create trigger hod_department_assignments_set_updated_at
before update on public.hod_department_assignments
for each row execute function public.set_updated_at();

alter table public.hod_department_assignments enable row level security;
alter table public.hod_department_assignments force row level security;

create policy hod_department_assignments_select
  on public.hod_department_assignments for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.has_role(institution_id, 'institution_admin')
  );

grant select on public.hod_department_assignments to authenticated;
revoke insert, update, delete on public.hod_department_assignments
  from anon, authenticated;

create or replace function public.is_institution_member(p_institution_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_role(
    p_institution_id,
    'student',
    'teacher',
    'hod',
    'institution_admin'
  );
$$;

create or replace function public.assign_hod(
  p_institution_id uuid,
  p_department_id uuid,
  p_user_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_assignment_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if not public.has_role(p_institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.departments d
    where d.id = p_department_id
      and d.institution_id = p_institution_id
      and d.is_active
  ) then
    raise exception 'department not found or inactive' using errcode = 'P0002';
  end if;

  insert into public.institution_memberships (
    user_id, institution_id, role, status, assigned_by
  ) values (
    p_user_id, p_institution_id, 'hod', 'active', auth.uid()
  )
  on conflict (user_id, institution_id, role)
    where institution_id is not null
    do update set status = 'active', assigned_by = auth.uid();

  insert into public.hod_department_assignments (
    institution_id, department_id, user_id, assigned_by, is_active
  ) values (
    p_institution_id, p_department_id, p_user_id, auth.uid(), true
  )
  on conflict (institution_id, department_id, user_id)
    do update set is_active = true, assigned_by = auth.uid()
  returning id into v_assignment_id;

  perform public.write_audit(
    'hod_assigned',
    'hod_department_assignments',
    v_assignment_id,
    p_institution_id,
    jsonb_build_object(
      'department_id', p_department_id,
      'user_id', p_user_id
    )
  );

  return v_assignment_id;
end;
$$;

revoke all on function public.assign_hod(uuid, uuid, uuid) from public;
grant execute on function public.assign_hod(uuid, uuid, uuid) to authenticated;
