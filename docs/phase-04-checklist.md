# Phase 4 — Development checklist

## Objective

Connect Flutter to Supabase Auth and PostgreSQL for profiles, four-role UOT access, and manual student verification.

## Implemented in the repository

- [x] Email/password sign up and sign in
- [x] Profile read/update (`profiles`)
- [x] Membership-driven role layout (`institution_memberships`)
- [x] UOT-only login role choices: Student, Teacher, HOD, and VC/Admin
- [x] Student self-registration using UOT department, program, semester, and registration number
- [x] VC/Admin verification queue calling `decide_student_verification`
- [x] Legacy institution onboarding and Super Admin access disabled by follow-up migrations
- [x] Honest copy: UI is not authorization; RLS and RPCs are

## Must be true on the hosted project (manual)

- [ ] Phase 2 SQL applied on `ydfprhodrltkykqxhvnc`
- [ ] Auth email settings understood (confirmation on/off)
- [ ] At least one user can sign in
- [ ] Apply migrations 11–16 in order; no Super Admin bootstrap or institution approval is used
- [ ] Configure UOT departments, programs, semesters, and a current academic session
- [ ] Create authorized staff memberships and verify role-specific sign-in

## Later-phase implementation status

- [x] Departments, classes, subjects, teacher assignments, roster import (Phase 5; hosted data setup remains)
- [x] Student verification is manual and does not depend on a roster match
- [ ] Secure campaign submission flow (Phase 6; campaign listing is implemented)
- [x] Teacher aggregate analytics UI (Phase 7; requires campaign data and the target-scoped report migration)
- [x] In-app notifications, comment moderation, and improvement-action UI (Phase 8; requires hosted SQL migrations and data)

## Security notes

- Flutter still uses only the anon/publishable key.
- Hiding a screen does not grant or deny data. PostgreSQL RLS does.
- Teachers never receive identity-link rows from these screens.
