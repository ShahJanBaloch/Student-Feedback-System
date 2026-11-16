-- TaleemVoice Phase 2: moderation, improvement, notifications, audit

create table public.feedback_moderation (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.feedback_comments (id) on delete cascade,
  institution_id uuid not null references public.institutions (id) on delete cascade,
  reviewer_id uuid not null references public.profiles (id),
  decision public.moderation_status not null,
  reason text,
  decided_at timestamptz not null default now()
);

create table public.feedback_reports (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.feedback_comments (id) on delete cascade,
  institution_id uuid not null references public.institutions (id) on delete cascade,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reason text not null,
  status public.access_request_status not null default 'pending',
  created_at timestamptz not null default now(),
  unique (comment_id, reporter_id)
);

create table public.improvement_actions (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  teacher_profile_id uuid,
  campaign_id uuid,
  title text not null,
  description text,
  status public.improvement_status not null default 'planned',
  owner_id uuid references public.profiles (id),
  due_on date,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (teacher_profile_id, institution_id)
    references public.teacher_profiles (id, institution_id)
    on delete set null,
  foreign key (campaign_id, institution_id)
    references public.feedback_campaigns (id, institution_id)
    on delete set null
);

create trigger improvement_actions_set_updated_at
before update on public.improvement_actions
for each row execute function public.set_updated_at();

create table public.institutional_reports (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  campaign_id uuid,
  title text not null,
  report_kind text not null default 'campaign_summary',
  payload jsonb not null default '{}'::jsonb,
  generated_by uuid references public.profiles (id),
  generated_at timestamptz not null default now(),
  foreign key (campaign_id, institution_id)
    references public.feedback_campaigns (id, institution_id)
    on delete set null
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  institution_id uuid references public.institutions (id) on delete cascade,
  notification_type public.notification_type not null default 'system',
  title text not null,
  body text not null,
  is_read boolean not null default false,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index notifications_user_idx on public.notifications (user_id, is_read, created_at desc);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid references public.institutions (id) on delete cascade,
  title text not null,
  body text not null,
  is_published boolean not null default false,
  published_at timestamptz,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (institution_id is null) -- platform-wide
    or (institution_id is not null)
  )
);

create trigger announcements_set_updated_at
before update on public.announcements
for each row execute function public.set_updated_at();

create table public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  campaigns boolean not null default true,
  announcements boolean not null default true,
  submissions boolean not null default true,
  updated_at timestamptz not null default now()
);

create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row execute function public.set_updated_at();

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles (id),
  institution_id uuid references public.institutions (id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_institution_idx on public.audit_logs (institution_id, created_at desc);

create table public.access_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  institution_id uuid references public.institutions (id) on delete cascade,
  request_type public.access_request_type not null,
  status public.access_request_status not null default 'pending',
  payload jsonb not null default '{}'::jsonb,
  decision_reason text,
  decided_by uuid references public.profiles (id),
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger access_requests_set_updated_at
before update on public.access_requests
for each row execute function public.set_updated_at();
