-- TaleemVoice Phase 2: identity, institutions, memberships

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text not null default '',
  phone text,
  locale text not null default 'en',
  avatar_path text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create table public.institutions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  short_code text not null,
  institution_type public.institution_type not null,
  status public.institution_status not null default 'pending',
  district text,
  tehsil text,
  city text,
  address text,
  province text not null default 'Balochistan',
  contact_email text,
  min_response_threshold integer not null default 5
    check (min_response_threshold >= 3),
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (short_code)
);

create trigger institutions_set_updated_at
before update on public.institutions
for each row execute function public.set_updated_at();

-- Composite uniqueness so children can FK (id, id) is trivial; used as
-- (id) only. Children store institution_id and FK institutions(id).
-- Cross-institution protection is on academic composite keys.

create table public.institution_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  institution_id uuid references public.institutions (id) on delete cascade,
  role public.app_role not null,
  status public.membership_status not null default 'pending',
  assigned_by uuid references public.profiles (id),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint membership_institution_scope check (
    (role = 'super_admin' and institution_id is null)
    or (role <> 'super_admin' and institution_id is not null)
  )
);

create unique index institution_memberships_super_admin_uniq
  on public.institution_memberships (user_id, role)
  where institution_id is null;

create unique index institution_memberships_scoped_uniq
  on public.institution_memberships (user_id, institution_id, role)
  where institution_id is not null;

create index institution_memberships_institution_idx
  on public.institution_memberships (institution_id, role, status);

create trigger institution_memberships_set_updated_at
before update on public.institution_memberships
for each row execute function public.set_updated_at();

create table public.platform_settings (
  id smallint primary key default 1 check (id = 1),
  student_self_registration boolean not null default true,
  institution_self_onboarding boolean not null default true,
  default_min_response_threshold integer not null default 5,
  allow_confidential_mode boolean not null default true,
  maintenance_message text,
  updated_at timestamptz not null default now()
);

insert into public.platform_settings (id) values (1)
on conflict (id) do nothing;

create trigger platform_settings_set_updated_at
before update on public.platform_settings
for each row execute function public.set_updated_at();

-- New Auth users get a profile row automatically.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
