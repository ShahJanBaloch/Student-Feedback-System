# TaleemVoice

**Student Voices. Better Education.**

Student feedback and educational quality improvement for the University of Turbat (UOT).

This repository is built in phases. The original multi-institution design documents are historical; the active app is UOT-only with Student, Teacher, HOD, and VC/Admin roles. Hosted Supabase setup, end-to-end data verification, and production deployment remain manual.

## What exists today

| Path | Meaning |
| --- | --- |
| `docs/phase-01-*.md` | Architecture, ERD, privacy, requirement gaps |
| `docs/phase-02-*.md` | How to apply SQL |
| `docs/phase-03-checklist.md` | Flutter shell |
| `docs/phase-04-checklist.md` | Auth, profiles, institutions, verification |
| `supabase/migrations/` | PostgreSQL schema, RLS, RPCs |
| `lib/` | Flutter app (Android / Chrome / Windows) |
| `.env.example` | Supabase project URL and anon-key placeholder |

## Current phase status

- Phase 5 academic structure, semesters, and roster import are implemented in `lib/`.
- UOT student registration is self-service and awaits manual VC/Admin review; no institution approval or student roster match is required.
- Phase 6 campaign listing is implemented; campaign creation and student submission UI are still pending.
- Phase 7 teacher aggregate reports are implemented; the hosted migration and real campaign data are required to verify them end to end.
- Phase 8 in-app notifications, comment moderation, and improvement-action tracking are implemented; hosted migration and data verification remain.
- Phase 9 adds CI checks and static web deployment guidance; hosted Auth/RLS verification and provider-specific deployment remain manual. Load tests, NLP, push, and Urdu/Balochi are later work.
- Hosted Supabase Auth and data flows have not been verified until you apply SQL and create users/data.

## Run the Flutter app

SDK used here: `S:\flutter`.

```powershell
$env:PATH = "S:\flutter\bin;" + $env:PATH
cd "C:\Users\shahj\Downloads\Student Feedback System"
copy .env.example .env   # then paste the anon key into .env
flutter pub get
flutter run -d chrome --dart-define-from-file=.env
```

Or `scripts/run_chrome.ps1`. In VS Code / Cursor use launch configuration **TaleemVoice (Chrome)**.

Never put the **service_role** key in Flutter, GitHub, or this folder.

## Apply Phase 2 SQL (required before Phase 4 data works)

1. Open the Supabase Dashboard for project `ydfprhodrltkykqxhvnc`.
2. SQL Editor → run each file in `supabase/migrations/` **in filename order**.
   This includes `20261116000009_target_report_scope.sql`, which ensures teacher scores only include submissions for that teacher's target.
   It also includes `20261116000010_phase8_moderation_rpc.sql`, which adds the authorized, audited comment moderation operation.
3. Run `supabase/seed.sql`.
4. Sign up from the app (or Auth → add a user).
5. Table Editor → `profiles` should contain that user (trigger on `auth.users`).
6. Do not create a Super Admin. Migrations 14–16 set up the UOT tenant and disable legacy Super Admin and institution-onboarding write paths.
7. Provision the first VC/Admin membership through a trusted Supabase SQL/server-side workflow; the client cannot grant roles. Then configure a current academic session, departments, programs, and semesters in Academic structure.

If you skip SQL, login may succeed while profile/membership queries fail. That is expected.

## Rating scale

1 Very Poor · 2 Poor · 3 Average · 4 Good · 5 Excellent · plus Not Applicable.

Results are shown only after a minimum number of responses. They describe student perception for a subject and class. They are not a complete measure of a teacher’s competence.

## Phases

1. Requirements, architecture, ERD, privacy — **documented**
2. Supabase schema + RLS + RPCs — **files ready; hosted apply is manual**
3. Flutter shell, theme, navigation — **in `lib/`**
4. Auth, profiles, UOT student registration, and manual verification — **in `lib/`**
5. Academic structure and roster — **implemented in `lib/`; hosted data setup remains**
6. Campaign listing — **implemented; secure submission flow remains**
7. Teacher aggregate analytics — **implemented; hosted migration/data verification remains**
8. Notifications, comment moderation, improvement actions — **implemented; hosted migration/data verification remains**
9. Tests, security checks, and static web release preparation — **CI and deployment guide added; hosted verification and deployment remain manual**
