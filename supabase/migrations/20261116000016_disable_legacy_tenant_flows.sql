-- Keep legacy rows and schema for history, but remove their active write paths.

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select false;
$$;

revoke all on function public.approve_institution(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.bootstrap_super_admin()
  from public, anon, authenticated, service_role;
revoke all on function public.request_student_verification(uuid, text, text)
  from public, anon, authenticated;

revoke insert, update, delete on public.institutions
  from anon, authenticated;
revoke insert, update, delete on public.institution_memberships
  from anon, authenticated;
revoke insert, update, delete on public.access_requests
  from anon, authenticated;
revoke insert, update, delete on public.academic_sessions
  from anon, authenticated;

grant select on public.institutions to authenticated;
grant select on public.institution_memberships to authenticated;
grant select on public.access_requests to authenticated;

update public.platform_settings
set institution_self_onboarding = false
where id = 1;
