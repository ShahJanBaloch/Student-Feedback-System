# Phase 2 — Development checklist

## Design (Phase 1) — done in repo docs

- [x] Requirements gaps recorded
- [x] Architecture written
- [x] Privacy model written (honest anonymity)
- [x] ERD and table dictionary written
- [x] Supabase implementation plan written

## SQL in this repository — done

- [x] Enums and `updated_at` trigger
- [x] Identity, institutions, memberships, auth profile trigger
- [x] Academic tables with composite FKs
- [x] Campaigns, eligibility, submissions, ratings, comments, identity links
- [x] Moderation, reports, notifications, audit, access requests
- [x] RPCs: UOT student registration and verification, submit feedback, reports
- [x] RLS on all tables; no client write path to raw submissions
- [x] Follow-up migrations disable active Super Admin and institution-onboarding paths while retaining legacy records
- [x] Seed of seven evaluation criteria
- [x] `.env.example` without the live key; local `.env` gitignored

## You still need to do on the hosted project

- [ ] Open Supabase SQL Editor for `ydfprhodrltkykqxhvnc`
- [ ] Run every migration in filename order, including the Phase 7/8 follow-up migrations
- [ ] Run `supabase/seed.sql`
- [ ] Authentication: create your own user
- [ ] Confirm a row appeared in `profiles`
- [ ] Create scoped VC/Admin, HOD, and teacher memberships using an authorized administrative workflow
- [ ] Do **not** store the service-role key in this folder

## Still needs hosted verification

- [ ] Confirm RLS and role-specific access using real authenticated users
- [ ] Edge Functions and Storage
- [ ] Production deployment

## Compatibility with Phase 3

Phase 3 may create the Flutter app and read `SUPABASE_URL` / `SUPABASE_ANON_KEY`. It must not add a service-role key. Table and RPC names in this phase are the contract.
