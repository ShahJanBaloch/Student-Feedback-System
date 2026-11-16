-- TaleemVoice Phase 2: Row Level Security
-- Enable RLS on every public table. Policies are the permission system.

alter table public.profiles enable row level security;
alter table public.institutions enable row level security;
alter table public.institution_memberships enable row level security;
alter table public.platform_settings enable row level security;
alter table public.departments enable row level security;
alter table public.academic_sessions enable row level security;
alter table public.academic_programs enable row level security;
alter table public.academic_classes enable row level security;
alter table public.subjects enable row level security;
alter table public.teacher_profiles enable row level security;
alter table public.teacher_assignments enable row level security;
alter table public.student_roster_entries enable row level security;
alter table public.student_enrollments enable row level security;
alter table public.student_class_enrollments enable row level security;
alter table public.evaluation_criteria enable row level security;
alter table public.feedback_campaigns enable row level security;
alter table public.campaign_criteria enable row level security;
alter table public.campaign_targets enable row level security;
alter table public.feedback_eligibility enable row level security;
alter table public.feedback_submissions enable row level security;
alter table public.feedback_ratings enable row level security;
alter table public.feedback_comments enable row level security;
alter table public.feedback_identity_links enable row level security;
alter table public.feedback_moderation enable row level security;
alter table public.feedback_reports enable row level security;
alter table public.improvement_actions enable row level security;
alter table public.institutional_reports enable row level security;
alter table public.notifications enable row level security;
alter table public.announcements enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.audit_logs enable row level security;
alter table public.access_requests enable row level security;

-- Force RLS even for table owners when using the API role.
alter table public.profiles force row level security;
alter table public.institutions force row level security;
alter table public.institution_memberships force row level security;
alter table public.platform_settings force row level security;
alter table public.departments force row level security;
alter table public.academic_sessions force row level security;
alter table public.academic_programs force row level security;
alter table public.academic_classes force row level security;
alter table public.subjects force row level security;
alter table public.teacher_profiles force row level security;
alter table public.teacher_assignments force row level security;
alter table public.student_roster_entries force row level security;
alter table public.student_enrollments force row level security;
alter table public.student_class_enrollments force row level security;
alter table public.evaluation_criteria force row level security;
alter table public.feedback_campaigns force row level security;
alter table public.campaign_criteria force row level security;
alter table public.campaign_targets force row level security;
alter table public.feedback_eligibility force row level security;
alter table public.feedback_submissions force row level security;
alter table public.feedback_ratings force row level security;
alter table public.feedback_comments force row level security;
alter table public.feedback_identity_links force row level security;
alter table public.feedback_moderation force row level security;
alter table public.feedback_reports force row level security;
alter table public.improvement_actions force row level security;
alter table public.institutional_reports force row level security;
alter table public.notifications force row level security;
alter table public.announcements force row level security;
alter table public.notification_preferences force row level security;
alter table public.audit_logs force row level security;
alter table public.access_requests force row level security;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

create policy profiles_select_self
  on public.profiles for select
  to authenticated
  using (id = auth.uid() or public.is_super_admin());

create policy profiles_select_institution_peers
  on public.profiles for select
  to authenticated
  using (
    exists (
      select 1
      from public.institution_memberships mine
      join public.institution_memberships theirs
        on theirs.institution_id = mine.institution_id
      where mine.user_id = auth.uid()
        and mine.status = 'active'
        and mine.role in ('institution_admin', 'teacher')
        and theirs.user_id = profiles.id
        and theirs.institution_id is not null
    )
  );

create policy profiles_update_self
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- institutions
-- ---------------------------------------------------------------------------

create policy institutions_select
  on public.institutions for select
  to authenticated
  using (
    public.is_super_admin()
    or status = 'approved'
    or created_by = auth.uid()
    or public.is_institution_member(id)
  );

create policy institutions_insert_pending
  on public.institutions for insert
  to authenticated
  with check (created_by = auth.uid() and status = 'pending');

create policy institutions_update_admin
  on public.institutions for update
  to authenticated
  using (
    public.is_super_admin()
    or public.has_role(id, 'institution_admin')
  )
  with check (
    public.is_super_admin()
    or public.has_role(id, 'institution_admin')
  );

create or replace function public.protect_institution_status()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'UPDATE'
     and new.status is distinct from old.status
     and not public.is_super_admin() then
    raise exception 'only super admin can change institution status'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger institutions_protect_status
before update on public.institutions
for each row execute function public.protect_institution_status();

-- ---------------------------------------------------------------------------
-- memberships
-- ---------------------------------------------------------------------------

create policy memberships_select
  on public.institution_memberships for select
  to authenticated
  using (
    user_id = auth.uid()
    or public.is_super_admin()
    or (
      institution_id is not null
      and public.has_role(institution_id, 'institution_admin')
    )
  );

create policy memberships_insert_admin
  on public.institution_memberships for insert
  to authenticated
  with check (
    public.is_super_admin()
    or (
      role <> 'super_admin'
      and institution_id is not null
      and public.has_role(institution_id, 'institution_admin')
    )
  );

create policy memberships_update_admin
  on public.institution_memberships for update
  to authenticated
  using (
    public.is_super_admin()
    or (
      institution_id is not null
      and public.has_role(institution_id, 'institution_admin')
    )
  )
  with check (
    public.is_super_admin()
    or (
      role <> 'super_admin'
      and institution_id is not null
      and public.has_role(institution_id, 'institution_admin')
    )
  );

-- ---------------------------------------------------------------------------
-- platform settings
-- ---------------------------------------------------------------------------

create policy platform_settings_select
  on public.platform_settings for select
  to authenticated
  using (true);

create policy platform_settings_update
  on public.platform_settings for update
  to authenticated
  using (public.is_super_admin())
  with check (public.is_super_admin());

-- ---------------------------------------------------------------------------
-- Academic catalogs (same pattern)
-- ---------------------------------------------------------------------------

create policy departments_select
  on public.departments for select to authenticated
  using (public.is_institution_member(institution_id) or public.is_super_admin());

create policy departments_write
  on public.departments for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy sessions_select
  on public.academic_sessions for select to authenticated
  using (public.is_institution_member(institution_id) or public.is_super_admin());

create policy sessions_write
  on public.academic_sessions for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy programs_select
  on public.academic_programs for select to authenticated
  using (public.is_institution_member(institution_id) or public.is_super_admin());

create policy programs_write
  on public.academic_programs for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy classes_select
  on public.academic_classes for select to authenticated
  using (public.is_institution_member(institution_id) or public.is_super_admin());

create policy classes_write
  on public.academic_classes for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy subjects_select
  on public.subjects for select to authenticated
  using (public.is_institution_member(institution_id) or public.is_super_admin());

create policy subjects_write
  on public.subjects for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy teacher_profiles_select
  on public.teacher_profiles for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_institution_member(institution_id)
    or public.is_super_admin()
  );

create policy teacher_profiles_write
  on public.teacher_profiles for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy teacher_assignments_select
  on public.teacher_assignments for select to authenticated
  using (public.is_institution_member(institution_id) or public.is_super_admin());

create policy teacher_assignments_write
  on public.teacher_assignments for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

-- Roster: admins only
create policy roster_admin
  on public.student_roster_entries for all to authenticated
  using (
    public.has_role(institution_id, 'institution_admin')
    or public.is_super_admin()
  )
  with check (public.has_role(institution_id, 'institution_admin') or public.is_super_admin());

create policy enrollments_select
  on public.student_enrollments for select to authenticated
  using (
    user_id = auth.uid()
    or public.has_role(institution_id, 'institution_admin')
    or public.is_super_admin()
  );

create policy enrollments_write
  on public.student_enrollments for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy class_enrollments_select
  on public.student_class_enrollments for select to authenticated
  using (
    public.has_role(institution_id, 'institution_admin')
    or public.is_super_admin()
    or exists (
      select 1
      from public.student_enrollments se
      where se.id = student_class_enrollments.enrollment_id
        and se.user_id = auth.uid()
    )
  );

create policy class_enrollments_write
  on public.student_class_enrollments for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

-- ---------------------------------------------------------------------------
-- Criteria catalog and campaigns
-- ---------------------------------------------------------------------------

create policy evaluation_criteria_select
  on public.evaluation_criteria for select to authenticated
  using (true);

create policy evaluation_criteria_write
  on public.evaluation_criteria for all to authenticated
  using (public.is_super_admin())
  with check (public.is_super_admin());

create policy campaigns_select
  on public.feedback_campaigns for select to authenticated
  using (
    public.has_role(institution_id, 'institution_admin')
    or public.is_super_admin()
    or (
      public.is_institution_member(institution_id)
      and status in ('open', 'closed', 'archived')
    )
  );

create policy campaigns_write
  on public.feedback_campaigns for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy campaign_criteria_select
  on public.campaign_criteria for select to authenticated
  using (
    public.is_institution_member(institution_id)
    or public.is_super_admin()
  );

create policy campaign_criteria_write
  on public.campaign_criteria for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy campaign_targets_select
  on public.campaign_targets for select to authenticated
  using (
    public.is_institution_member(institution_id)
    or public.is_super_admin()
  );

create policy campaign_targets_write
  on public.campaign_targets for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy eligibility_select
  on public.feedback_eligibility for select to authenticated
  using (
    student_user_id = auth.uid()
    or public.has_role(institution_id, 'institution_admin')
    or public.is_super_admin()
  );

-- No client insert/update on eligibility; RPC only.

-- Submissions, ratings, identity links: no policies for authenticated
-- (default deny). RPCs use security definer.

create policy comments_select_admin
  on public.feedback_comments for select to authenticated
  using (
    public.has_role(institution_id, 'institution_admin')
    or public.is_super_admin()
  );

create policy comments_update_admin
  on public.feedback_comments for update to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy moderation_admin
  on public.feedback_moderation for all to authenticated
  using (public.has_role(institution_id, 'institution_admin') or public.is_super_admin())
  with check (public.has_role(institution_id, 'institution_admin') or public.is_super_admin());

create policy reports_insert_self
  on public.feedback_reports for insert to authenticated
  with check (reporter_id = auth.uid() and public.is_institution_member(institution_id));

create policy reports_select
  on public.feedback_reports for select to authenticated
  using (
    reporter_id = auth.uid()
    or public.has_role(institution_id, 'institution_admin')
    or public.is_super_admin()
  );

create policy reports_update_admin
  on public.feedback_reports for update to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

-- Identity links: Super Admin only, and only when an approved unmask request exists.
create policy identity_links_super_admin_select
  on public.feedback_identity_links for select
  to authenticated
  using (
    public.is_super_admin()
    and exists (
      select 1
      from public.access_requests ar
      where ar.institution_id = feedback_identity_links.institution_id
        and ar.request_type = 'identity_unmask'
        and ar.status = 'approved'
        and (ar.payload->>'submission_id')::uuid = feedback_identity_links.submission_id
    )
  );

-- ---------------------------------------------------------------------------
-- Improvement, reports, comms
-- ---------------------------------------------------------------------------

create policy improvement_select
  on public.improvement_actions for select to authenticated
  using (
    public.has_role(institution_id, 'institution_admin')
    or public.is_super_admin()
    or (
      public.has_role(institution_id, 'teacher')
      and exists (
        select 1 from public.teacher_profiles tp
        where tp.id = improvement_actions.teacher_profile_id
          and tp.user_id = auth.uid()
      )
    )
  );

create policy improvement_write
  on public.improvement_actions for all to authenticated
  using (public.has_role(institution_id, 'institution_admin'))
  with check (public.has_role(institution_id, 'institution_admin'));

create policy inst_reports_admin
  on public.institutional_reports for all to authenticated
  using (public.has_role(institution_id, 'institution_admin') or public.is_super_admin())
  with check (public.has_role(institution_id, 'institution_admin') or public.is_super_admin());

create policy notifications_select_self
  on public.notifications for select to authenticated
  using (user_id = auth.uid());

create policy notifications_update_self
  on public.notifications for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy announcements_select
  on public.announcements for select to authenticated
  using (
    (is_published and institution_id is null)
    or (is_published and institution_id is not null and public.is_institution_member(institution_id))
    or (institution_id is not null and public.has_role(institution_id, 'institution_admin'))
    or public.is_super_admin()
  );

create policy announcements_write_inst
  on public.announcements for all to authenticated
  using (
    public.is_super_admin()
    or (institution_id is not null and public.has_role(institution_id, 'institution_admin'))
  )
  with check (
    public.is_super_admin()
    or (institution_id is not null and public.has_role(institution_id, 'institution_admin'))
  );

create policy prefs_self
  on public.notification_preferences for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy audit_select
  on public.audit_logs for select to authenticated
  using (
    public.is_super_admin()
    or (
      institution_id is not null
      and public.has_role(institution_id, 'institution_admin')
    )
  );

create policy access_requests_select
  on public.access_requests for select to authenticated
  using (
    requester_id = auth.uid()
    or public.is_super_admin()
    or (
      institution_id is not null
      and public.has_role(institution_id, 'institution_admin')
    )
  );

create policy access_requests_insert_self
  on public.access_requests for insert to authenticated
  with check (requester_id = auth.uid());

create policy access_requests_update_privileged
  on public.access_requests for update to authenticated
  using (
    public.is_super_admin()
    or (
      institution_id is not null
      and public.has_role(institution_id, 'institution_admin')
      and request_type = 'student_verification'
    )
  )
  with check (
    public.is_super_admin()
    or (
      institution_id is not null
      and public.has_role(institution_id, 'institution_admin')
      and request_type = 'student_verification'
    )
  );
