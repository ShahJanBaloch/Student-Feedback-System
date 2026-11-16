-- TaleemVoice Phase 2: helpers and privileged RPCs
-- All security definer functions pin search_path and re-check auth.uid().

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.institution_memberships m
    where m.user_id = auth.uid()
      and m.role = 'super_admin'
      and m.status = 'active'
      and m.institution_id is null
  );
$$;

create or replace function public.has_role(
  p_institution_id uuid,
  variadic p_roles public.app_role[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_super_admin()
    or exists (
      select 1
      from public.institution_memberships m
      where m.user_id = auth.uid()
        and m.institution_id = p_institution_id
        and m.status = 'active'
        and m.role = any (p_roles)
    );
$$;

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
    'institution_admin'
  );
$$;

create or replace function public.write_audit(
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_institution_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_logs (
    actor_id, institution_id, action, entity_type, entity_id, metadata
  ) values (
    auth.uid(), p_institution_id, p_action, p_entity_type, p_entity_id, coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

create or replace function public.notify_user(
  p_user_id uuid,
  p_institution_id uuid,
  p_type public.notification_type,
  p_title text,
  p_body text,
  p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (
    user_id, institution_id, notification_type, title, body, payload
  ) values (
    p_user_id, p_institution_id, p_type, p_title, p_body, coalesce(p_payload, '{}'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Institution approval (Super Admin)
-- ---------------------------------------------------------------------------

create or replace function public.approve_institution(
  p_institution_id uuid,
  p_admin_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_super_admin() then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  update public.institutions
  set status = 'approved'
  where id = p_institution_id
    and status in ('pending', 'suspended');

  if not found then
    raise exception 'institution not found or not approvable' using errcode = 'P0002';
  end if;

  insert into public.institution_memberships (
    user_id, institution_id, role, status, assigned_by
  ) values (
    p_admin_user_id, p_institution_id, 'institution_admin', 'active', auth.uid()
  )
  on conflict do nothing;

  update public.institution_memberships
  set status = 'active', assigned_by = auth.uid()
  where user_id = p_admin_user_id
    and institution_id = p_institution_id
    and role = 'institution_admin';

  perform public.write_audit(
    'institution_approved',
    'institutions',
    p_institution_id,
    p_institution_id,
    jsonb_build_object('admin_user_id', p_admin_user_id)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Student verification request
-- ---------------------------------------------------------------------------

create or replace function public.request_student_verification(
  p_institution_id uuid,
  p_student_number text,
  p_full_name text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_roster public.student_roster_entries%rowtype;
  v_request_id uuid;
  v_enrollment_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if not exists (
    select 1 from public.institutions i
    where i.id = p_institution_id and i.status = 'approved'
  ) then
    raise exception 'institution is not approved' using errcode = 'P0001';
  end if;

  insert into public.access_requests (
    requester_id, institution_id, request_type, status, payload
  ) values (
    auth.uid(),
    p_institution_id,
    'student_verification',
    'pending',
    jsonb_build_object(
      'student_number', p_student_number,
      'full_name', p_full_name
    )
  )
  returning id into v_request_id;

  select * into v_roster
  from public.student_roster_entries r
  where r.institution_id = p_institution_id
    and r.student_number = p_student_number
    and r.is_active
    and r.matched_user_id is null;

  -- Auto-approve only when the roster row is unique and unmatched.
  if found and v_roster.session_id is not null then
    insert into public.institution_memberships (
      user_id, institution_id, role, status, assigned_by
    ) values (
      auth.uid(), p_institution_id, 'student', 'active', auth.uid()
    )
    on conflict do nothing;

    update public.institution_memberships
    set status = 'active'
    where user_id = auth.uid()
      and institution_id = p_institution_id
      and role = 'student';

    insert into public.student_enrollments (
      institution_id, user_id, program_id, session_id, student_number,
      verification_status, roster_entry_id
    ) values (
      p_institution_id,
      auth.uid(),
      v_roster.program_id,
      v_roster.session_id,
      p_student_number,
      'verified',
      v_roster.id
    )
    returning id into v_enrollment_id;

    if v_roster.class_id is not null then
      insert into public.student_class_enrollments (
        institution_id, enrollment_id, class_id
      ) values (
        p_institution_id, v_enrollment_id, v_roster.class_id
      );
    end if;

    update public.student_roster_entries
    set matched_user_id = auth.uid()
    where id = v_roster.id;

    update public.access_requests
    set status = 'approved',
        decided_by = auth.uid(),
        decided_at = now(),
        decision_reason = 'auto_matched_roster'
    where id = v_request_id;

    perform public.write_audit(
      'student_auto_verified',
      'access_requests',
      v_request_id,
      p_institution_id,
      jsonb_build_object('student_number', p_student_number)
    );

    perform public.notify_user(
      auth.uid(),
      p_institution_id,
      'system',
      'Student verification approved',
      'Your student record was matched to the institutional roster.',
      jsonb_build_object('request_id', v_request_id)
    );
  else
    perform public.write_audit(
      'student_verification_requested',
      'access_requests',
      v_request_id,
      p_institution_id,
      jsonb_build_object('student_number', p_student_number)
    );
  end if;

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
set search_path = public
as $$
declare
  v_req public.access_requests%rowtype;
  v_number text;
  v_roster public.student_roster_entries%rowtype;
  v_enrollment_id uuid;
begin
  select * into v_req
  from public.access_requests
  where id = p_request_id
    and request_type = 'student_verification'
    and status = 'pending';

  if not found then
    raise exception 'request not found' using errcode = 'P0002';
  end if;

  if not public.has_role(v_req.institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if not p_approve then
    update public.access_requests
    set status = 'rejected',
        decided_by = auth.uid(),
        decided_at = now(),
        decision_reason = p_reason
    where id = p_request_id;

    perform public.write_audit(
      'student_verification_rejected',
      'access_requests',
      p_request_id,
      v_req.institution_id,
      '{}'::jsonb
    );
    return;
  end if;

  v_number := v_req.payload->>'student_number';

  select * into v_roster
  from public.student_roster_entries r
  where r.institution_id = v_req.institution_id
    and r.student_number = v_number
    and r.is_active;

  if not found or v_roster.session_id is null then
    raise exception 'roster entry missing or has no session' using errcode = 'P0002';
  end if;

  if v_roster.matched_user_id is not null
     and v_roster.matched_user_id <> v_req.requester_id then
    raise exception 'student number already matched' using errcode = '23505';
  end if;

  insert into public.institution_memberships (
    user_id, institution_id, role, status, assigned_by
  ) values (
    v_req.requester_id, v_req.institution_id, 'student', 'active', auth.uid()
  )
  on conflict do nothing;

  update public.institution_memberships
  set status = 'active', assigned_by = auth.uid()
  where user_id = v_req.requester_id
    and institution_id = v_req.institution_id
    and role = 'student';

  insert into public.student_enrollments (
    institution_id, user_id, program_id, session_id, student_number,
    verification_status, roster_entry_id
  ) values (
    v_req.institution_id,
    v_req.requester_id,
    v_roster.program_id,
    v_roster.session_id,
    v_number,
    'verified',
    v_roster.id
  )
  on conflict do nothing
  returning id into v_enrollment_id;

  if v_enrollment_id is null then
    select id into v_enrollment_id
    from public.student_enrollments
    where user_id = v_req.requester_id
      and institution_id = v_req.institution_id
      and session_id = v_roster.session_id;
  end if;

  if v_roster.class_id is not null then
    insert into public.student_class_enrollments (
      institution_id, enrollment_id, class_id
    ) values (
      v_req.institution_id, v_enrollment_id, v_roster.class_id
    )
    on conflict do nothing;
  end if;

  update public.student_roster_entries
  set matched_user_id = v_req.requester_id
  where id = v_roster.id;

  update public.access_requests
  set status = 'approved',
      decided_by = auth.uid(),
      decided_at = now(),
      decision_reason = coalesce(p_reason, 'admin_approved')
  where id = p_request_id;

  update public.student_enrollments
  set verification_status = 'verified'
  where id = v_enrollment_id;

  perform public.write_audit(
    'student_verification_approved',
    'access_requests',
    p_request_id,
    v_req.institution_id,
    jsonb_build_object('student_number', v_number)
  );

  perform public.notify_user(
    v_req.requester_id,
    v_req.institution_id,
    'system',
    'Student verification approved',
    'You can now take part in eligible feedback campaigns.',
    jsonb_build_object('request_id', p_request_id)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Build eligibility from class enrollments
-- ---------------------------------------------------------------------------

create or replace function public.generate_campaign_eligibility(p_campaign_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_campaign public.feedback_campaigns%rowtype;
  v_count integer;
begin
  select * into v_campaign
  from public.feedback_campaigns
  where id = p_campaign_id;

  if not found then
    raise exception 'campaign not found' using errcode = 'P0002';
  end if;

  if not public.has_role(v_campaign.institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  insert into public.feedback_eligibility (
    campaign_id, institution_id, campaign_target_id, student_user_id
  )
  select
    v_campaign.id,
    v_campaign.institution_id,
    t.id,
    se.user_id
  from public.campaign_targets t
  join public.teacher_assignments ta
    on ta.id = t.teacher_assignment_id
  join public.student_class_enrollments sce
    on sce.class_id = ta.class_id
   and sce.institution_id = v_campaign.institution_id
  join public.student_enrollments se
    on se.id = sce.enrollment_id
   and se.verification_status = 'verified'
  join public.institution_memberships m
    on m.user_id = se.user_id
   and m.institution_id = v_campaign.institution_id
   and m.role = 'student'
   and m.status = 'active'
  where t.campaign_id = v_campaign.id
  on conflict do nothing;

  get diagnostics v_count = row_count;

  perform public.write_audit(
    'eligibility_generated',
    'feedback_campaigns',
    p_campaign_id,
    v_campaign.institution_id,
    jsonb_build_object('inserted', v_count)
  );

  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- Atomic feedback submit
-- ---------------------------------------------------------------------------

create or replace function public.submit_feedback(
  p_campaign_id uuid,
  p_campaign_target_id uuid,
  p_ratings jsonb,
  p_comment text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_campaign public.feedback_campaigns%rowtype;
  v_eligibility public.feedback_eligibility%rowtype;
  v_submission_id uuid;
  v_required_count integer;
  v_provided_count integer;
  v_comment_status public.moderation_status;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if p_ratings is null or jsonb_typeof(p_ratings) <> 'array' then
    raise exception 'ratings must be a JSON array' using errcode = '22023';
  end if;

  select * into v_campaign
  from public.feedback_campaigns
  where id = p_campaign_id
  for update;

  if not found then
    raise exception 'campaign not found' using errcode = 'P0002';
  end if;

  if v_campaign.status <> 'open'
     or now() < v_campaign.starts_at
     or now() > v_campaign.ends_at then
    raise exception 'campaign is not open' using errcode = 'P0001';
  end if;

  if not public.has_role(v_campaign.institution_id, 'student') then
    raise exception 'not an active student of this institution' using errcode = '42501';
  end if;

  select * into v_eligibility
  from public.feedback_eligibility e
  where e.campaign_id = p_campaign_id
    and e.campaign_target_id = p_campaign_target_id
    and e.student_user_id = auth.uid()
  for update;

  if not found then
    raise exception 'not eligible for this campaign target' using errcode = '42501';
  end if;

  if v_eligibility.revoked_at is not null then
    raise exception 'eligibility revoked' using errcode = '42501';
  end if;

  if v_eligibility.used_at is not null then
    raise exception 'feedback already submitted' using errcode = '23505';
  end if;

  select count(*) into v_required_count
  from public.campaign_criteria
  where campaign_id = p_campaign_id;

  select count(distinct x.criterion_id) into v_provided_count
  from jsonb_to_recordset(p_ratings) as x(
    criterion_id uuid,
    rating_value smallint,
    is_not_applicable boolean
  );

  if v_provided_count <> v_required_count then
    raise exception 'every campaign criterion must be rated exactly once'
      using errcode = '23514';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_ratings) as x(
      criterion_id uuid,
      rating_value smallint,
      is_not_applicable boolean
    )
    where not exists (
      select 1
      from public.campaign_criteria c
      where c.id = x.criterion_id
        and c.campaign_id = p_campaign_id
    )
  ) then
    raise exception 'rating refers to a criterion outside this campaign'
      using errcode = '23503';
  end if;

  insert into public.feedback_submissions (
    campaign_id, institution_id, campaign_target_id, is_complete
  ) values (
    p_campaign_id, v_campaign.institution_id, p_campaign_target_id, true
  )
  returning id into v_submission_id;

  insert into public.feedback_ratings (
    submission_id, campaign_id, campaign_criterion_id, rating_value, is_not_applicable
  )
  select
    v_submission_id,
    p_campaign_id,
    x.criterion_id,
    case when coalesce(x.is_not_applicable, false) then null else x.rating_value end,
    coalesce(x.is_not_applicable, false)
  from jsonb_to_recordset(p_ratings) as x(
    criterion_id uuid,
    rating_value smallint,
    is_not_applicable boolean
  );

  if p_comment is not null and char_length(trim(p_comment)) >= 3 then
    v_comment_status := case
      when v_campaign.auto_publish_comments then 'published'::public.moderation_status
      else 'pending'::public.moderation_status
    end;

    insert into public.feedback_comments (
      submission_id, campaign_id, institution_id, body, moderation_status
    ) values (
      v_submission_id,
      p_campaign_id,
      v_campaign.institution_id,
      trim(p_comment),
      v_comment_status
    );
  end if;

  update public.feedback_eligibility
  set used_at = now()
  where id = v_eligibility.id;

  if v_campaign.feedback_mode = 'confidential' then
    insert into public.feedback_identity_links (
      submission_id, campaign_id, institution_id, student_user_id
    ) values (
      v_submission_id, p_campaign_id, v_campaign.institution_id, auth.uid()
    );
  end if;

  perform public.write_audit(
    'feedback_submitted',
    'feedback_submissions',
    v_submission_id,
    v_campaign.institution_id,
    jsonb_build_object(
      'campaign_id', p_campaign_id,
      'campaign_target_id', p_campaign_target_id,
      'mode', v_campaign.feedback_mode
    )
  );

  perform public.notify_user(
    auth.uid(),
    v_campaign.institution_id,
    'submission',
    'Feedback submitted',
    'Thank you. Your response was recorded.',
    jsonb_build_object('campaign_id', p_campaign_id)
  );

  return v_submission_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Aggregated report (threshold-aware)
-- ---------------------------------------------------------------------------

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
    left join public.feedback_ratings r
      on r.campaign_criterion_id = cc.id
    left join public.feedback_submissions s
      on s.id = r.submission_id
     and s.campaign_target_id = p_campaign_target_id
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

-- ---------------------------------------------------------------------------
-- Copy catalog criteria into a campaign
-- ---------------------------------------------------------------------------

-- First authenticated user may become Super Admin only when none exists yet.
create or replace function public.bootstrap_super_admin()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if exists (
    select 1
    from public.institution_memberships
    where role = 'super_admin'
      and status = 'active'
  ) then
    raise exception 'a super admin already exists' using errcode = 'P0001';
  end if;

  insert into public.institution_memberships (
    user_id, institution_id, role, status, assigned_by
  ) values (
    auth.uid(), null, 'super_admin', 'active', auth.uid()
  );

  perform public.write_audit(
    'super_admin_bootstrapped',
    'institution_memberships',
    auth.uid(),
    null,
    '{}'::jsonb
  );
end;
$$;

create or replace function public.attach_default_criteria(p_campaign_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_institution_id uuid;
begin
  select institution_id into v_institution_id
  from public.feedback_campaigns
  where id = p_campaign_id;

  if not found then
    raise exception 'campaign not found' using errcode = 'P0002';
  end if;

  if not public.has_role(v_institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  insert into public.campaign_criteria (
    campaign_id, institution_id, catalog_criterion_id, category, title, description, display_order
  )
  select
    p_campaign_id,
    v_institution_id,
    c.id,
    c.category,
    c.title,
    c.description,
    c.display_order
  from public.evaluation_criteria c
  where c.is_active
  on conflict do nothing;
end;
$$;
