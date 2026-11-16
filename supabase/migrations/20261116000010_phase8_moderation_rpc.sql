create or replace function public.moderate_feedback_comment(
  p_comment_id uuid,
  p_decision public.moderation_status,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_comment public.feedback_comments%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if p_decision not in ('published', 'rejected', 'hidden') then
    raise exception 'invalid moderation decision' using errcode = '22023';
  end if;

  select * into v_comment
  from public.feedback_comments
  where id = p_comment_id
  for update;

  if not found then
    raise exception 'comment not found' using errcode = 'P0002';
  end if;

  if not (
    public.has_role(v_comment.institution_id, 'institution_admin')
    or public.is_super_admin()
  ) then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if v_comment.moderation_status <> 'pending' then
    raise exception 'comment is no longer pending' using errcode = 'P0001';
  end if;

  update public.feedback_comments
  set moderation_status = p_decision
  where id = p_comment_id;

  insert into public.feedback_moderation (
    comment_id,
    institution_id,
    reviewer_id,
    decision,
    reason
  ) values (
    p_comment_id,
    v_comment.institution_id,
    auth.uid(),
    p_decision,
    nullif(trim(p_reason), '')
  );

  perform public.write_audit(
    'feedback_moderated',
    'feedback_comments',
    p_comment_id,
    v_comment.institution_id,
    jsonb_build_object('decision', p_decision)
  );
end;
$$;

create or replace function public.update_improvement_action_status(
  p_action_id uuid,
  p_status public.improvement_status
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_action public.improvement_actions%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  if p_status is null then
    raise exception 'invalid improvement status' using errcode = '22023';
  end if;

  select * into v_action
  from public.improvement_actions
  where id = p_action_id
  for update;

  if not found then
    raise exception 'improvement action not found' using errcode = 'P0002';
  end if;

  if not public.has_role(v_action.institution_id, 'institution_admin') then
    raise exception 'not authorized' using errcode = '42501';
  end if;

  if v_action.status = p_status then
    return;
  end if;

  update public.improvement_actions
  set status = p_status
  where id = p_action_id;

  perform public.write_audit(
    'improvement_action_status_changed',
    'improvement_actions',
    p_action_id,
    v_action.institution_id,
    jsonb_build_object('from', v_action.status, 'to', p_status)
  );
end;
$$;

-- Route state changes through RPCs so direct PostgREST updates cannot bypass audit.
revoke update on public.feedback_comments from authenticated;
revoke update on public.improvement_actions from authenticated;
revoke all on function public.moderate_feedback_comment(uuid, public.moderation_status, text) from public;
revoke all on function public.update_improvement_action_status(uuid, public.improvement_status) from public;
grant execute on function public.moderate_feedback_comment(uuid, public.moderation_status, text) to authenticated;
grant execute on function public.update_improvement_action_status(uuid, public.improvement_status) to authenticated;
