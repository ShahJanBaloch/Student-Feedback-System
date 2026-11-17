create or replace function public.create_feedback_campaign(
  p_institution_id uuid,
  p_session_id uuid,
  p_title text,
  p_description text default null,
  p_ends_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_campaign_id uuid;
  v_ends_at timestamptz := coalesce(
    p_ends_at,
    now() + interval '30 days'
  );
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if not public.has_role(p_institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if nullif(trim(p_title), '') is null then
    raise exception 'campaign title is required' using errcode = '22023';
  end if;

  if v_ends_at <= now() then
    raise exception 'campaign end date must be in the future' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.academic_sessions
    where id = p_session_id
      and institution_id = p_institution_id
  ) then
    raise exception 'academic session not found' using errcode = 'P0002';
  end if;

  insert into public.feedback_campaigns (
    institution_id,
    session_id,
    title,
    description,
    status,
    feedback_mode,
    starts_at,
    ends_at,
    created_by
  )
  values (
    p_institution_id,
    p_session_id,
    trim(p_title),
    nullif(trim(p_description), ''),
    'open',
    'anonymous',
    now(),
    v_ends_at,
    auth.uid()
  )
  returning id into v_campaign_id;

  insert into public.campaign_criteria (
    campaign_id,
    institution_id,
    category,
    title,
    description,
    display_order
  )
  select
    v_campaign_id,
    p_institution_id,
    category,
    title,
    description,
    display_order
  from public.evaluation_criteria
  where is_active
  order by display_order;

  if not found then
    raise exception 'no active evaluation criteria configured'
      using errcode = 'P0002';
  end if;

  insert into public.campaign_targets (
    campaign_id,
    institution_id,
    teacher_assignment_id
  )
  select
    v_campaign_id,
    p_institution_id,
    id
  from public.teacher_assignments
  where institution_id = p_institution_id
    and session_id = p_session_id;

  perform public.generate_campaign_eligibility(v_campaign_id);
  return v_campaign_id;
end;
$$;

revoke all on function public.create_feedback_campaign(
  uuid,
  uuid,
  text,
  text,
  timestamptz
) from public;

grant execute on function public.create_feedback_campaign(
  uuid,
  uuid,
  text,
  text,
  timestamptz
) to authenticated;
