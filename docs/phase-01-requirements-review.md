# Phase 1 — Requirements Review (TaleemVoice)

**Status:** Completed as a design deliverable. No live database or Flutter app exists yet.

This document records what the master brief already decides, what it leaves open, and how TaleemVoice will treat those gaps so Phase 2 SQL is internally consistent.

## 1. Settled product decisions

| Topic | Decision |
| --- | --- |
| Purpose | Institutional teaching-quality improvement, not public ranking or teacher shaming |
| Coverage | Schools, colleges, and universities in Balochistan |
| Who may submit feedback | Only verified students of the relevant institution |
| Rating scale | 1–5 plus Not Applicable |
| Categories | Seven teaching-quality categories listed in the brief |
| Identity of respondents | Teachers never see anonymous student identities |
| Security | PostgreSQL RLS is the real permission layer; Flutter screens are not security |
| Stack | Flutter (mobile + web), Riverpod, GoRouter, Supabase |
| AI / NLP | Deferred. Do not block the core product |

## 2. Missing or conflicting requirements (and the decision used)

### 2.1 Super Admin vs “all roles are institution-scoped”

The brief says roles are institution-scoped, then defines Super Admin as a platform operator (approve institutions, platform settings, audit).

**Decision:** Super Admin is the only platform-scoped role. `institution_id` is `NULL` on that membership. Student, Teacher, and Institution Admin always belong to one institution per membership row. The same person may hold different roles at different institutions.

### 2.2 Absolute anonymity vs duplicate-prevention and audits

The brief asks for anonymous feedback and also for identity mapping, eligibility checks, and exceptional audited access.

**Decision:** TaleemVoice does **not** claim cryptographic or absolute anonymity.

- **Anonymous campaigns:** the submission row has no `student_id`. Eligibility is marked used in the same transaction so a student cannot submit twice. An identity-link row is **not** created.
- **Confidential campaigns:** an identity-link row is stored, readable only by Super Admin (and by a documented, audited unmask procedure). Teachers and ordinary Institution Admins cannot read it.
- Duplicate prevention uses `feedback_eligibility`, not a student column on the submission.

### 2.3 How a student becomes “verified”

The brief requires verification but does not specify the credential (email domain, CNIC, roll number, LMS export).

**Decision for v1:**

1. Institution Admin imports a **roster** (student number, name, class, optional CNIC hash).
2. The student registers with email/password (Supabase Auth).
3. The student requests verification for one institution and supplies student number (+ optional CNIC).
4. Auto-match if the student number is unique and unmatched on that roster; otherwise Institution Admin approves.
5. Approval creates an active Student membership, a `student_enrollments` row, and class enrollment when the roster names a class.

Email-domain auto-join is a future option, not v1.

### 2.4 One app or two apps

Mobile student app and Flutter Web admin dashboards are the **same Flutter project**, with role-aware routing. Teachers and admins can use web first; students can use Android first.

### 2.5 Who sees written comments

Unspecified.

**Decision:** Comments are stored separately from ratings. They are hidden until moderation status is `published` (or auto-published if the campaign allows it). Teachers see **de-identified** published comments only after the response threshold is met. They never see a student name on anonymous comments.

### 2.6 Minimum response threshold

Unspecified numeric default.

**Decision:** Institution default `min_response_threshold = 5`. A campaign may raise (not lower below the institution floor) this value. Aggregate teacher reports return no scores until the threshold is met.

### 2.7 Campaign target grain

Unspecified whether feedback is per teacher, per subject, or per class.

**Decision:** A campaign target is one **teacher assignment** (teacher + subject + class + session). That is the unit students rate and the unit teachers review.

### 2.8 Historical meaning of criteria

**Decision:** `evaluation_criteria` is a global catalog. Each campaign copies selected criteria into `campaign_criteria` (label, help text, category, display order, weight). Ratings point at `campaign_criteria`, never at a catalog row that might later be renamed.

### 2.9 Cross-institution data

**Decision:** Academic rows carry `institution_id`. Composite foreign keys (`id, institution_id`) prevent a class in Institution A from referencing a department in Institution B.

### 2.10 Notifications and storage

Push notifications and file-heavy Storage workflows are Phase 8+. v1 stores in-app `notifications` rows. Avatars may use Storage later; Phase 2 does not require buckets.

### 2.11 Localization

English UI copy in v1. Schema includes `locale` on profiles so Urdu/Balochi can be added without a redesign.

### 2.12 Service-role key

The brief supplies the project URL and **anon** key only. That is correct for Flutter. Applying SQL to the hosted project must be done in the Supabase SQL Editor (or CLI logged in as the project owner). This repository will **never** contain a service-role key.

## 3. Non-goals for v1 (University of Turbat Gala 2026 demo)

- Public league tables of teachers
- NLP sentiment service
- SMS/WhatsApp blasting
- Multi-factor auth beyond Supabase email
- Offline-first sync
- Student-to-student social features
