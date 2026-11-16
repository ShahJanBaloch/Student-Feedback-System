-- TaleemVoice Phase 2: campaigns, eligibility, submissions

create table public.evaluation_criteria (
  id uuid primary key default gen_random_uuid(),
  category public.criterion_category not null unique,
  title text not null,
  description text not null,
  display_order integer not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.feedback_campaigns (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  session_id uuid not null,
  title text not null,
  description text,
  status public.campaign_status not null default 'draft',
  feedback_mode public.feedback_mode not null default 'anonymous',
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  min_response_threshold integer not null default 5 check (min_response_threshold >= 3),
  auto_publish_comments boolean not null default false,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  check (ends_at > starts_at),
  foreign key (session_id, institution_id)
    references public.academic_sessions (id, institution_id)
    on delete restrict
);

create trigger feedback_campaigns_set_updated_at
before update on public.feedback_campaigns
for each row execute function public.set_updated_at();

create table public.campaign_criteria (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null,
  institution_id uuid not null,
  catalog_criterion_id uuid references public.evaluation_criteria (id),
  category public.criterion_category not null,
  title text not null,
  description text not null,
  display_order integer not null,
  weight numeric(6, 3) not null default 1.0 check (weight > 0),
  unique (id, campaign_id),
  unique (campaign_id, category),
  unique (campaign_id, display_order),
  foreign key (campaign_id, institution_id)
    references public.feedback_campaigns (id, institution_id)
    on delete cascade
);

create table public.campaign_targets (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null,
  institution_id uuid not null,
  teacher_assignment_id uuid not null,
  created_at timestamptz not null default now(),
  unique (id, campaign_id),
  unique (campaign_id, teacher_assignment_id),
  foreign key (campaign_id, institution_id)
    references public.feedback_campaigns (id, institution_id)
    on delete cascade,
  foreign key (teacher_assignment_id, institution_id)
    references public.teacher_assignments (id, institution_id)
    on delete restrict
);

create table public.feedback_eligibility (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null,
  institution_id uuid not null,
  campaign_target_id uuid not null,
  student_user_id uuid not null references public.profiles (id) on delete cascade,
  used_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  unique (campaign_id, campaign_target_id, student_user_id),
  foreign key (campaign_id, institution_id)
    references public.feedback_campaigns (id, institution_id)
    on delete cascade,
  foreign key (campaign_target_id, campaign_id)
    references public.campaign_targets (id, campaign_id)
    on delete cascade
);

create index feedback_eligibility_student_idx
  on public.feedback_eligibility (student_user_id, campaign_id);

create table public.feedback_submissions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null,
  institution_id uuid not null,
  campaign_target_id uuid not null,
  submitted_at timestamptz not null default now(),
  is_complete boolean not null default true,
  unique (id, campaign_id),
  foreign key (campaign_id, institution_id)
    references public.feedback_campaigns (id, institution_id)
    on delete cascade,
  foreign key (campaign_target_id, campaign_id)
    references public.campaign_targets (id, campaign_id)
    on delete restrict
);

create index feedback_submissions_target_idx
  on public.feedback_submissions (campaign_target_id);

-- Intentionally no student_id on submissions.

create table public.feedback_ratings (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.feedback_submissions (id) on delete cascade,
  campaign_id uuid not null,
  campaign_criterion_id uuid not null,
  rating_value smallint,
  is_not_applicable boolean not null default false,
  unique (submission_id, campaign_criterion_id),
  check (
    (is_not_applicable = true and rating_value is null)
    or (is_not_applicable = false and rating_value between 1 and 5)
  ),
  foreign key (submission_id, campaign_id)
    references public.feedback_submissions (id, campaign_id)
    on delete cascade,
  foreign key (campaign_criterion_id, campaign_id)
    references public.campaign_criteria (id, campaign_id)
    on delete restrict
);

create table public.feedback_comments (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique references public.feedback_submissions (id) on delete cascade,
  campaign_id uuid not null,
  institution_id uuid not null,
  body text not null check (char_length(trim(body)) >= 3),
  moderation_status public.moderation_status not null default 'pending',
  created_at timestamptz not null default now(),
  foreign key (submission_id, campaign_id)
    references public.feedback_submissions (id, campaign_id)
    on delete cascade
);

create table public.feedback_identity_links (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique references public.feedback_submissions (id) on delete cascade,
  campaign_id uuid not null,
  institution_id uuid not null,
  student_user_id uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now(),
  unmasked_at timestamptz,
  unmasked_by uuid references public.profiles (id)
);
