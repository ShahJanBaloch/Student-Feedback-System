# Phase 1 — System Architecture

**Status:** Design complete. Implementation of tables begins in Phase 2 SQL. Flutter is Phase 3+.

## 1. Objective in simple language

TaleemVoice is a mobile + web system where a **verified student** of a **Balochistan institution** can rate **their teachers for specific subjects**, privately. The institution then sees **aggregated, threshold-protected** results and can plan improvements. Teachers see how students experienced their teaching, not who said what.

## 2. High-level architecture

```text
┌────────────────────────────┐     HTTPS + JWT      ┌─────────────────────────────┐
│  Flutter app (Android/Web) │ ───────────────────► │  Supabase Auth              │
│  Riverpod + GoRouter       │                      │  PostgreSQL + RLS           │
│  Material 3                │  RPC / REST          │  Storage (later)            │
│  fl_chart (Phase 7–8)      │ ───────────────────► │  Edge Functions (privileged)│
└────────────────────────────┘                      └─────────────────────────────┘
        │                                                        │
        │ env: SUPABASE_URL, SUPABASE_ANON_KEY                   │
        │ never: service_role                                    │
        ▼                                                        ▼
  Role-aware UI only.                              Real authorization in SQL.
```

### Why this split?

A student who knows a little Dart could hide a button, but they cannot hide a PostgreSQL policy. Every sensitive read/write is enforced in the database. Flutter uses the **anon** key plus the user’s JWT. Privileged operations (submit feedback atomically, unmask with audit, publish aggregates) are `SECURITY DEFINER` SQL functions or later Edge Functions that still run as constrained database roles—not as a service-role key shipped in the app.

## 3. Client architecture (Flutter, from Phase 3)

Feature-first folders so a student developer can find “feedback” in one place:

- `lib/core` — theme, router, env, errors, shared widgets
- `lib/features/<name>` — screens, controllers, data sources for one capability
- `lib/shared` — DTOs and providers used by more than one feature

State: **Riverpod**. Navigation: **GoRouter** with redirects based on session + active role.

## 4. Backend architecture (Supabase)

| Piece | Role |
| --- | --- |
| Auth | Email/password (v1). Profile row created by a trigger on `auth.users` |
| PostgreSQL | System of record for people, academics, campaigns, feedback, audit |
| RLS | Institution isolation and role checks on every table |
| SQL RPCs | Atomic feedback submit, roster match, unmask request handling |
| Edge Functions | Reserved for operations that need secrets (email provider, later NLP). None required to submit feedback in v1 |
| Storage | Not enabled in Phase 2 |

## 5. Role model

```text
auth.users 1──1 profiles
                │
                └──< institution_memberships
                         ├── Super Admin (institution_id IS NULL)
                         ├── Institution Admin (one institution)
                         ├── Teacher (one institution; may also have teacher_profiles)
                         └── Student (one institution; enrollments + eligibility)
```

Active role in the app is a client convenience (Riverpod). Authorization always re-checks `institution_memberships`.

## 6. Core workflows (v1)

### A. Institution onboarding

1. Someone registers and submits an institution record (`pending`).
2. Super Admin approves (`approved`) and grants Institution Admin membership.
3. Institution Admin creates departments, sessions, programs, classes, subjects, teachers, roster.

### B. Student verification

See `docs/phase-01-privacy-model.md`. Outcome: `active` Student membership + enrollment.

### C. Campaign and feedback

1. Admin opens a campaign, selects criteria (copied to snapshot rows), selects teacher assignments as targets.
2. System builds `feedback_eligibility` from class enrollments.
3. Student submits through `submit_feedback(...)` RPC (one transaction).
4. After close + threshold, teachers and admins read aggregates via `get_campaign_target_report(...)`.

### D. Improvement

Admin records `improvement_actions` against a teacher/campaign. This is operational tracking, not an automated HR score.

## 7. Privacy boundaries (summary)

| Actor | May see |
| --- | --- |
| Student | Own profile, own institution academics, own eligibility, own submission **receipts** (not a copy of others), own notifications |
| Teacher | Own assignments, aggregate reports at/above threshold, de-identified published comments |
| Institution Admin | All academic data and campaigns **for that institution**, moderation, rosters, aggregates; **not** identity links |
| Super Admin | Institution lifecycle, platform settings, audit logs, identity links **only after** an approved `access_requests` row (still logged) |

## 8. Environment and secrets

- Flutter reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define` / `.env` (Phase 3).
- `.env` is gitignored. `.env.example` has placeholders.
- Service-role key, database password, and Dashboard access stay with the project owner only.

## 9. What is implemented vs proposed

| Item | State after this phase |
| --- | --- |
| Architecture + ERD + privacy rules | Written in `docs/` |
| Hosted schema | Not applied until you run Phase 2 SQL in Supabase |
| Flutter app | Not created (Phase 3) |
| Live Auth connection | Not verified |
| Edge Functions | Proposed only |
| NLP / push / i18n | Proposed only |
