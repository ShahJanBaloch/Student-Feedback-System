with revoked as (
  update public.institution_memberships
  set status = 'suspended'
  where role = 'super_admin'
    and status = 'active'
  returning id, user_id
)
insert into public.audit_logs (
  actor_id, institution_id, action, entity_type, entity_id, metadata
)
select
  null,
  null,
  'legacy_super_admin_revoked',
  'institution_memberships',
  id,
  jsonb_build_object('user_id', user_id)
from revoked;

revoke all on function public.bootstrap_super_admin()
  from public, anon, authenticated, service_role;
