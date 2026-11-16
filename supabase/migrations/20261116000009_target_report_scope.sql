-- Keep category scores scoped to the target being reported.
create or replace function public.get_campaign_target_report(p_campaign_target_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_target public.campaign_targets%rowtype;
  v_campaign public.feedback_campaigns%rowtype;
  v_assignment public.teacher_assignments%rowtype;
  v_teacher public.teacher_profiles%rowtype;
  v_count integer;
  v_threshold integer;
  v_is_teacher boolean;
  v_is_admin boolean;
  v_criteria jsonb;
  v_comments jsonb;
begin
  select * into v_target
  from public.campaign_targets
  where id = p_campaign_target_id;

  if not found then
    raise exception 'target not found' using errcode = 'P0002';
  end if;

  select * into v_campaign
  from public.feedback_campaigns
  where id = v_target.campaign_id;

  select * into v_assignment
  from public.teacher_assignments
  where id = v_target.teacher_assignment_id;

  select * into v_teacher
  from public.teacher_profiles
  where id = v_assignment.teacher_profile_id;

  v_is_admin := public.has_role(v_campaign.institution_id, 'institution_admin');
  v_is_teacher := exists (
    select 1
    from public.teacher_profiles tp
    where tp.id = v_teacher.id
      and tp.user_id = auth.uid()
      and public.has_role(v_campaign.institution_id, 'teacher')
  );

  if not (v_is_admin or v_is_teacher or public.is_super_admin()) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  select count(*) into v_count
  from public.feedback_submissions s
  where s.campaign_target_id = p_campaign_target_id
    and s.is_complete;

  select greatest(i.min_response_threshold, v_campaign.min_response_threshold)
  into v_threshold
  from public.institutions i
  where i.id = v_campaign.institution_id;

  if v_count < v_threshold then
    return jsonb_build_object(
      'status', 'below_threshold',
      'threshold', v_threshold,
      'response_count', case when v_is_admin or public.is_super_admin() then v_count else null end,
      'disclaimer', 'Scores appear only after the minimum number of responses so individuals cannot be identified easily.'
    );
  end if;

  select coalesce(jsonb_agg(row_to_json(c)::jsonb order by c.display_order), '[]'::jsonb)
  into v_criteria
  from (
    select
      cc.id,
      cc.category,
      cc.title,
      cc.description,
      cc.display_order,
      round(avg(r.rating_value)::numeric, 2) as mean_rating,
      count(r.rating_value) as numeric_responses,
      count(*) filter (where r.is_not_applicable) as na_count
    from public.campaign_criteria cc
    left join public.feedback_submissions s
      on s.campaign_target_id = p_campaign_target_id
     and s.is_complete
    left join public.feedback_ratings r
      on r.submission_id = s.id
     and r.campaign_criterion_id = cc.id
    where cc.campaign_id = v_campaign.id
    group by cc.id
  ) c;

  select coalesce(jsonb_agg(jsonb_build_object('id', fc.id, 'body', fc.body)), '[]'::jsonb)
  into v_comments
  from public.feedback_comments fc
  join public.feedback_submissions s on s.id = fc.submission_id
  where s.campaign_target_id = p_campaign_target_id
    and fc.moderation_status = 'published';

  return jsonb_build_object(
    'status', 'ok',
    'response_count', v_count,
    'threshold', v_threshold,
    'criteria', v_criteria,
    'published_comments', v_comments,
    'disclaimer', 'These figures summarise student perceptions for this subject and class. They are not a complete measure of a teacher''s professional competence.'
  );
end;
$$;
