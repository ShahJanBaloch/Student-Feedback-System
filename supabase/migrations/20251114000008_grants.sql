-- TaleemVoice Phase 2: grants
-- PostgREST uses the authenticated/anon roles. Sensitive tables are select/insert
-- locked; RPCs are the write path for feedback.

grant usage on schema public to anon, authenticated;

grant select, update on public.profiles to authenticated;
grant select, insert, update on public.institutions to authenticated;
grant select, insert, update on public.institution_memberships to authenticated;
grant select, update on public.platform_settings to authenticated;

grant select, insert, update, delete on public.departments to authenticated;
grant select, insert, update, delete on public.academic_sessions to authenticated;
grant select, insert, update, delete on public.academic_programs to authenticated;
grant select, insert, update, delete on public.academic_classes to authenticated;
grant select, insert, update, delete on public.subjects to authenticated;
grant select, insert, update, delete on public.teacher_profiles to authenticated;
grant select, insert, update, delete on public.teacher_assignments to authenticated;
grant select, insert, update, delete on public.student_roster_entries to authenticated;
grant select, insert, update, delete on public.student_enrollments to authenticated;
grant select, insert, update, delete on public.student_class_enrollments to authenticated;

grant select, insert, update, delete on public.evaluation_criteria to authenticated;
grant select, insert, update, delete on public.feedback_campaigns to authenticated;
grant select, insert, update, delete on public.campaign_criteria to authenticated;
grant select, insert, update, delete on public.campaign_targets to authenticated;
grant select on public.feedback_eligibility to authenticated;

-- No grants on submissions/ratings/identity_links for authenticated.
-- Functions run as definer and insert those rows.

grant select, update on public.feedback_comments to authenticated;
grant select, insert, update, delete on public.feedback_moderation to authenticated;
grant select, insert, update on public.feedback_reports to authenticated;
grant select, insert, update, delete on public.improvement_actions to authenticated;
grant select, insert, update, delete on public.institutional_reports to authenticated;
grant select, update on public.notifications to authenticated;
grant select, insert, update, delete on public.announcements to authenticated;
grant select, insert, update, delete on public.notification_preferences to authenticated;
grant select on public.audit_logs to authenticated;
grant select, insert, update on public.access_requests to authenticated;
grant select on public.feedback_identity_links to authenticated;

revoke all on function public.is_super_admin() from public;
revoke all on function public.has_role(uuid, public.app_role[]) from public;
revoke all on function public.is_institution_member(uuid) from public;
revoke all on function public.approve_institution(uuid, uuid) from public;
revoke all on function public.request_student_verification(uuid, text, text) from public;
revoke all on function public.decide_student_verification(uuid, boolean, text) from public;
revoke all on function public.generate_campaign_eligibility(uuid) from public;
revoke all on function public.submit_feedback(uuid, uuid, jsonb, text) from public;
revoke all on function public.get_campaign_target_report(uuid) from public;
revoke all on function public.attach_default_criteria(uuid) from public;
revoke all on function public.bootstrap_super_admin() from public;
revoke all on function public.write_audit(text, text, uuid, uuid, jsonb) from public;
revoke all on function public.notify_user(uuid, uuid, public.notification_type, text, text, jsonb) from public;

grant execute on function public.is_super_admin() to authenticated;
grant execute on function public.has_role(uuid, public.app_role[]) to authenticated;
grant execute on function public.is_institution_member(uuid) to authenticated;
grant execute on function public.approve_institution(uuid, uuid) to authenticated;
grant execute on function public.request_student_verification(uuid, text, text) to authenticated;
grant execute on function public.decide_student_verification(uuid, boolean, text) to authenticated;
grant execute on function public.generate_campaign_eligibility(uuid) to authenticated;
grant execute on function public.submit_feedback(uuid, uuid, jsonb, text) to authenticated;
grant execute on function public.get_campaign_target_report(uuid) to authenticated;
grant execute on function public.attach_default_criteria(uuid) to authenticated;
grant execute on function public.bootstrap_super_admin() to authenticated;

-- Table owner (postgres/supabase_admin) retains full access in SQL Editor.
