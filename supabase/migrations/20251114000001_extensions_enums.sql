-- TaleemVoice Phase 2: extensions and enumerations
-- Run first.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enumerations
-- ---------------------------------------------------------------------------

create type public.institution_type as enum ('school', 'college', 'university');

create type public.institution_status as enum ('pending', 'approved', 'suspended');

create type public.app_role as enum (
  'student',
  'teacher',
  'institution_admin',
  'super_admin'
);

create type public.membership_status as enum (
  'pending',
  'active',
  'suspended',
  'rejected'
);

create type public.verification_status as enum (
  'unverified',
  'pending',
  'verified',
  'rejected'
);

create type public.campaign_status as enum (
  'draft',
  'open',
  'closed',
  'archived'
);

create type public.feedback_mode as enum ('anonymous', 'confidential');

create type public.criterion_category as enum (
  'teaching_methodology',
  'subject_knowledge',
  'classroom_behaviour',
  'punctuality_responsibility',
  'student_engagement',
  'assessment_fairness',
  'overall_effectiveness'
);

create type public.moderation_status as enum (
  'pending',
  'published',
  'rejected',
  'hidden'
);

create type public.improvement_status as enum (
  'planned',
  'in_progress',
  'completed',
  'cancelled'
);

create type public.access_request_type as enum (
  'student_verification',
  'identity_unmask',
  'institution_onboarding'
);

create type public.access_request_status as enum (
  'pending',
  'approved',
  'rejected',
  'cancelled'
);

create type public.notification_type as enum (
  'system',
  'campaign',
  'submission',
  'moderation',
  'announcement',
  'improvement'
);

-- ---------------------------------------------------------------------------
-- Shared updated_at trigger
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
