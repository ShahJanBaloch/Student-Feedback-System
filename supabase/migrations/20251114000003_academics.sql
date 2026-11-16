-- TaleemVoice Phase 2: academic structure
-- Composite unique (id, institution_id) lets children pin both ends to one institution.

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  name text not null,
  code text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (institution_id, name)
);

create trigger departments_set_updated_at
before update on public.departments
for each row execute function public.set_updated_at();

create table public.academic_sessions (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  name text not null,
  starts_on date not null,
  ends_on date not null,
  is_current boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (institution_id, name),
  check (ends_on >= starts_on)
);

create trigger academic_sessions_set_updated_at
before update on public.academic_sessions
for each row execute function public.set_updated_at();

create table public.academic_programs (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  department_id uuid not null,
  name text not null,
  level text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (institution_id, department_id, name),
  foreign key (department_id, institution_id)
    references public.departments (id, institution_id)
    on delete restrict
);

create trigger academic_programs_set_updated_at
before update on public.academic_programs
for each row execute function public.set_updated_at();

create table public.academic_classes (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  program_id uuid not null,
  session_id uuid not null,
  name text not null,
  section text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (program_id, session_id, name, section),
  foreign key (program_id, institution_id)
    references public.academic_programs (id, institution_id)
    on delete restrict,
  foreign key (session_id, institution_id)
    references public.academic_sessions (id, institution_id)
    on delete restrict
);

create trigger academic_classes_set_updated_at
before update on public.academic_classes
for each row execute function public.set_updated_at();

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  department_id uuid not null,
  code text not null,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (institution_id, code),
  foreign key (department_id, institution_id)
    references public.departments (id, institution_id)
    on delete restrict
);

create trigger subjects_set_updated_at
before update on public.subjects
for each row execute function public.set_updated_at();

create table public.teacher_profiles (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  employee_code text,
  designation text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (institution_id, user_id),
  unique (institution_id, employee_code)
);

create trigger teacher_profiles_set_updated_at
before update on public.teacher_profiles
for each row execute function public.set_updated_at();

create table public.teacher_assignments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  teacher_profile_id uuid not null,
  subject_id uuid not null,
  class_id uuid not null,
  session_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (teacher_profile_id, subject_id, class_id, session_id),
  foreign key (teacher_profile_id, institution_id)
    references public.teacher_profiles (id, institution_id)
    on delete restrict,
  foreign key (subject_id, institution_id)
    references public.subjects (id, institution_id)
    on delete restrict,
  foreign key (class_id, institution_id)
    references public.academic_classes (id, institution_id)
    on delete restrict,
  foreign key (session_id, institution_id)
    references public.academic_sessions (id, institution_id)
    on delete restrict
);

create index teacher_assignments_class_idx
  on public.teacher_assignments (class_id);

create trigger teacher_assignments_set_updated_at
before update on public.teacher_assignments
for each row execute function public.set_updated_at();

create table public.student_roster_entries (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  student_number text not null,
  full_name text not null,
  class_id uuid,
  program_id uuid,
  session_id uuid,
  cnic_hash text,
  matched_user_id uuid references public.profiles (id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (institution_id, student_number),
  foreign key (class_id, institution_id)
    references public.academic_classes (id, institution_id)
    on delete set null,
  foreign key (program_id, institution_id)
    references public.academic_programs (id, institution_id)
    on delete set null,
  foreign key (session_id, institution_id)
    references public.academic_sessions (id, institution_id)
    on delete set null
);

create trigger student_roster_entries_set_updated_at
before update on public.student_roster_entries
for each row execute function public.set_updated_at();

create table public.student_enrollments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  program_id uuid,
  session_id uuid not null,
  student_number text not null,
  verification_status public.verification_status not null default 'pending',
  roster_entry_id uuid references public.student_roster_entries (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, institution_id),
  unique (user_id, institution_id, session_id),
  unique (institution_id, session_id, student_number),
  foreign key (program_id, institution_id)
    references public.academic_programs (id, institution_id)
    on delete set null,
  foreign key (session_id, institution_id)
    references public.academic_sessions (id, institution_id)
    on delete restrict
);

create trigger student_enrollments_set_updated_at
before update on public.student_enrollments
for each row execute function public.set_updated_at();

create table public.student_class_enrollments (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid not null references public.institutions (id) on delete cascade,
  enrollment_id uuid not null,
  class_id uuid not null,
  created_at timestamptz not null default now(),
  unique (enrollment_id, class_id),
  foreign key (enrollment_id, institution_id)
    references public.student_enrollments (id, institution_id)
    on delete cascade,
  foreign key (class_id, institution_id)
    references public.academic_classes (id, institution_id)
    on delete restrict
);
