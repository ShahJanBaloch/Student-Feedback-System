do $$
declare
  v_uot_count integer;
  v_uot_id uuid;
begin
  select count(*)
  into v_uot_count
  from public.institutions
  where lower(short_code) = 'uot';

  if v_uot_count > 1 then
    raise exception 'expected at most one UOT institution; found %', v_uot_count;
  end if;

  if v_uot_count = 0 then
    insert into public.institutions (
      name, short_code, institution_type, status, province, city
    ) values (
      'University of Turbat', 'UOT', 'university', 'pending',
      'Balochistan', 'Turbat'
    );
  end if;

  select id
  into v_uot_id
  from public.institutions
  where lower(short_code) = 'uot';

  insert into public.institution_memberships (
    user_id, institution_id, role, status
  )
  select distinct
    user_id, v_uot_id, 'institution_admin', 'active'
  from public.institution_memberships
  where role = 'institution_admin'
    and status = 'active'
  on conflict (user_id, institution_id, role)
    where institution_id is not null
    do update set status = 'active';

  with moved as (
    update public.institution_memberships
    set status = 'suspended'
    where role = 'institution_admin'
      and institution_id <> v_uot_id
    returning id, user_id
  )
  insert into public.audit_logs (
    actor_id, institution_id, action, entity_type, entity_id, metadata
  )
  select
    null,
    v_uot_id,
    'institution_admin_scope_restricted',
    'institution_memberships',
    id,
    jsonb_build_object('user_id', user_id, 'institution_id', v_uot_id)
  from moved;
end;
$$;
