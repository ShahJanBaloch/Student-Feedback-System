alter type public.access_request_type add value if not exists 'role_access';

create or replace function public.request_role_access(
  p_institution_id uuid,
  p_role public.app_role,
  p_payload jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if p_role not in (
    'teacher'::public.app_role,
    'hod'::public.app_role,
    'institution_admin'::public.app_role
  ) then
    raise exception 'this role cannot be requested through onboarding'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.institutions
    where id = p_institution_id
      and status = 'approved'::public.institution_status
  ) then
    raise exception 'institution not found or not approved'
      using errcode = 'P0002';
  end if;

  if exists (
    select 1
    from public.institution_memberships
    where user_id = auth.uid()
      and institution_id = p_institution_id
      and role = p_role
      and status = 'active'::public.membership_status
  ) then
    raise exception 'this role is already active'
      using errcode = '23505';
  end if;

  update public.access_requests
  set status = 'cancelled'::public.access_request_status,
      updated_at = now()
  where requester_id = auth.uid()
    and institution_id = p_institution_id
    and request_type = 'role_access'::public.access_request_type
    and status = 'pending'::public.access_request_status;

  insert into public.access_requests (
    requester_id,
    institution_id,
    request_type,
    payload
  )
  values (
    auth.uid(),
    p_institution_id,
    'role_access'::public.access_request_type,
    coalesce(p_payload, '{}'::jsonb)
      || jsonb_build_object('requested_role', p_role::text)
  )
  returning id into v_request_id;

  return v_request_id;
end;
$$;

create or replace function public.decide_role_access(
  p_request_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.access_requests%rowtype;
  v_role public.app_role;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select *
  into v_request
  from public.access_requests
  where id = p_request_id
    and request_type = 'role_access'::public.access_request_type
    and status = 'pending'::public.access_request_status
  for update;

  if not found then
    raise exception 'pending role request not found' using errcode = 'P0002';
  end if;

  if not public.has_role(v_request.institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  v_role := (v_request.payload ->> 'requested_role')::public.app_role;

  if v_role not in (
    'teacher'::public.app_role,
    'hod'::public.app_role,
    'institution_admin'::public.app_role
  ) then
    raise exception 'invalid requested role' using errcode = '22023';
  end if;

  if p_approve then
    update public.institution_memberships
    set status = 'active'::public.membership_status,
        assigned_by = auth.uid(),
        updated_at = now()
    where user_id = v_request.requester_id
      and institution_id = v_request.institution_id
      and role = v_role;

    if not found then
      insert into public.institution_memberships (
        user_id,
        institution_id,
        role,
        status,
        assigned_by
      )
      values (
        v_request.requester_id,
        v_request.institution_id,
        v_role,
        'active'::public.membership_status,
        auth.uid()
      );
    end if;

    if v_role = 'hod'::public.app_role then
      if nullif(v_request.payload ->> 'department_id', '') is null
        or not exists (
          select 1
          from public.departments
          where id = (v_request.payload ->> 'department_id')::uuid
            and institution_id = v_request.institution_id
            and is_active
        ) then
        raise exception 'an active department is required for HOD approval'
          using errcode = '22023';
      end if;

      insert into public.hod_department_assignments (
        institution_id,
        department_id,
        user_id,
        assigned_by,
        is_active
      )
      values (
        v_request.institution_id,
        (v_request.payload ->> 'department_id')::uuid,
        v_request.requester_id,
        auth.uid(),
        true
      )
      on conflict (institution_id, department_id, user_id)
      do update set
        is_active = true,
        assigned_by = auth.uid(),
        updated_at = now();
    end if;

    if v_role = 'teacher'::public.app_role then
      insert into public.teacher_profiles (
        institution_id,
        user_id,
        employee_code,
        designation,
        is_active
      )
      values (
        v_request.institution_id,
        v_request.requester_id,
        nullif(trim(v_request.payload ->> 'employee_code'), ''),
        nullif(trim(v_request.payload ->> 'designation'), ''),
        true
      )
      on conflict (institution_id, user_id)
      do update set
        is_active = true,
        updated_at = now();
    end if;
  end if;

  update public.access_requests
  set status = case
        when p_approve then 'approved'::public.access_request_status
        else 'rejected'::public.access_request_status
      end,
      decision_reason = nullif(trim(p_reason), ''),
      decided_by = auth.uid(),
      decided_at = now(),
      updated_at = now()
  where id = v_request.id;
end;
$$;

revoke all on function public.request_role_access(uuid, public.app_role, jsonb)
from public;
grant execute on function public.request_role_access(uuid, public.app_role, jsonb)
to authenticated;

revoke all on function public.decide_role_access(uuid, boolean, text)
from public;
grant execute on function public.decide_role_access(uuid, boolean, text)
to authenticated;
