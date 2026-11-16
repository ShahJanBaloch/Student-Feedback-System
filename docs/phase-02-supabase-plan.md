# Phase 2 — Supabase Implementation Plan

**Status:** SQL is in `supabase/migrations/` and `supabase/seed.sql`. It is **not** automatically applied to the hosted project.

## 1. Existing project

- URL: `https://ydfprhodrltkykqxhvnc.supabase.co`
- Project ID: `ydfprhodrltkykqxhvnc`
- Flutter will use the **anon** key only, from local `.env.example` configuration.

## 2. How to apply (owner machine)

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → project `ydfprhodrltkykqxhvnc` → SQL Editor.
2. Run migration files **in filename order** (timestamp prefix).
3. Run `supabase/seed.sql` once on an empty catalog (it inserts global criteria and platform settings).
4. Authentication → Providers: keep Email enabled.
5. Confirm Table Editor shows RLS enabled (shield icon) on every public table.

Do not paste the service-role key into this repository, chat logs you will commit, or Flutter.

## 3. File order

| File | Contents |
| --- | --- |
| `20251114000001_extensions_enums.sql` | Extensions, enums, `set_updated_at` |
| `20251114000002_identity.sql` | Profiles, institutions, memberships, settings, auth trigger |
| `20251114000003_academics.sql` | Departments through enrollments |
| `20251114000004_campaigns_feedback.sql` | Campaigns through identity links |
| `20251114000005_admin_comms.sql` | Moderation, reports, notifications, audit |
| `20251114000006_functions.sql` | Role helpers, submit/report/verify RPCs |
| `20251114000007_rls.sql` | Enable RLS + policies |
| `20251114000008_grants.sql` | Grants: revoke direct writes on sensitive tables |
| `20261116000009_target_report_scope.sql` | Scope report ratings to their campaign target |
| `20261116000010_phase8_moderation_rpc.sql` | Audited moderation and improvement status RPCs; revoke direct status updates |
| `20261116000011_add_hod_role.sql` | Add the HOD role enum value |
| `20261116000012_hod_department_assignments.sql` | Department-scoped HOD assignments and admin-only assignment RPC |
| `20261116000013_revoke_legacy_super_admin.sql` | Suspend active global Super Admin memberships and disable first-user bootstrap |
| `20261116000014_scope_admins_to_uot.sql` | Ensure one internal UOT tenant exists, move active admins to it, and suspend other admin scopes without requiring institution approval |
| `20261116000015_uot_student_verification.sql` | Add UOT academic semesters and student registration/verification RPCs |
| `20261116000016_disable_legacy_tenant_flows.sql` | Disable active Super Admin and institution onboarding/role-write paths while retaining legacy records |

## 4. Testing Phase 2 (without Flutter)

After migrations:

1. Dashboard → Authentication → Add user (email).
2. SQL: `select * from public.profiles` — trigger should have created a row.
3. Migration 14 creates the internal UOT tenant if needed; no institution approval is required. Provision scoped VC/Admin (`institution_admin`) memberships through trusted Supabase SQL/server-side administration; the client cannot grant roles. Do not create a global Super Admin.
4. In SQL Editor, `set request.jwt.claim.sub` is not how the dashboard works; RLS tests need the Flutter client or `auth.uid()` from a logged-in session. **Do not claim RLS is battle-tested until Phase 4 login exists.**
5. `select * from public.evaluation_criteria` after seed should return 7 rows.
6. Assign HOD roles only after migration 12; the `assign_hod` RPC requires an active institution admin and an active department.

## 5. Compatibility with Phase 1

SQL names match the ERD. Extra table vs the original brief: `student_roster_entries` and `platform_settings` (required for verification and defaults). These were identified as gaps in Phase 1.

## 6. What Phase 2 does not do

- Does not create Flutter widgets
- Does not upload Edge Functions
- Does not configure Storage buckets
- Does not prove a live RPC call from a phone
- Does not create demo students (that needs Auth users)
