# Phase 1 — Privacy, Verification, and Access Boundaries

**Status:** Binding rules for Phase 2 SQL. If Flutter and SQL disagree, SQL wins.

## 1. Honest anonymity (read this first)

If a student submits feedback, the database **can** know that this student was eligible and that eligibility was used. That is enough to stop double voting. It is **not** enough for a teacher to open a screen and see “Ahmed said 2/5”.

TaleemVoice therefore uses three layers:

1. **Eligibility** — “this student may rate this target once.”
2. **Submission** — ratings and comments, **no student_id column**.
3. **Identity link** — created **only** for confidential campaigns, stored in a table teachers cannot `SELECT`.

We will never market “nobody can ever know who submitted” because Super Admin emergency access and server backups exist. We **will** guarantee: teachers and ordinary institutional viewers cannot read respondent identities for anonymous campaigns through the product or through PostgREST.

## 2. Feedback modes

| Mode | Identity link row | Who can ever see the student |
| --- | --- | --- |
| `anonymous` | Not created | Nobody through normal product paths. Eligibility only shows `used_at`, not a submission id |
| `confidential` | Created | Super Admin, and only after `access_requests` is `approved`, with an `audit_logs` row |

Institution Admin **cannot** browse identity links. If they believe abuse occurred, they file an access request. Super Admin decides. Every approval writes audit.

## 3. Student verification workflow

```text
Register (Auth) → profile trigger
        ↓
Choose institution + enter student number
        ↓
access_requests (type = student_verification)
        ↓
Match roster student_number
        ↓
     ┌── auto_approved (unique unmatched roster row)
     └── pending_admin → Institution Admin approves/rejects
        ↓
institution_memberships (student, active)
student_enrollments (verified)
student_class_enrollments (if roster has class)
```

Rules:

- Unverified students cannot see campaigns or call `submit_feedback`.
- One student number per institution is unique on the roster.
- A user may be a student at Institution A and a teacher at Institution B (separate memberships).
- Verification does not grant feedback rights for classes the student is not enrolled in.

## 4. Feedback submission workflow (server-side)

Client calls **one** RPC: `submit_feedback(campaign_id, target_id, ratings[], comment, is_anonymous_ack)`.

The function (security definer, locked-down grants) must:

1. Confirm `auth.uid()` is an **active student** of the campaign’s institution.
2. Confirm campaign is `open` and now is between `starts_at` and `ends_at`.
3. Lock the eligibility row (`FOR UPDATE`) for this user + target.
4. Reject if missing, revoked, or `used_at` is not null.
5. Insert `feedback_submissions` (no user id).
6. Insert ratings: every campaign criterion exactly once; values 1–5 or N/A.
7. Insert comment if non-empty; moderation status `pending` unless campaign `auto_publish_comments`.
8. Set eligibility `used_at = now()`.
9. If campaign mode is `confidential`, insert `feedback_identity_links`.
10. Insert a student-facing notification “submitted”.
11. Write audit `feedback_submitted` **without** storing rating content in the audit payload.

Clients cannot `INSERT` into submissions, ratings, comments, or identity links directly.

## 5. Teacher report workflow

RPC `get_campaign_target_report(target_id)`:

1. Caller is the assigned teacher, or Institution Admin of that institution, or Super Admin.
2. Count complete submissions.
3. If count < effective threshold, return `{ "status": "below_threshold", "count": null }` — **do not** return partial averages (even the exact count can sometimes identify a small class; v1 still returns a boolean below-threshold, not the raw count to teachers; admins may see counts).
4. Otherwise return per-criterion mean, distribution, and published comments.

**Teacher vs admin count visibility:** teachers receive `response_count` only when `>= threshold`. Admins receive operational counts always, still without identities.

## 6. Institution-level isolation

- Every academic and feedback table is keyed by `institution_id` (directly or through a parent that is uniquely bound to one institution).
- Composite foreign keys make cross-institution graphs impossible.
- RLS: `institution_id IN (select institution_id from my active memberships)` plus Super Admin override.
- Super Admin sees institution metadata and pending approvals by default; bulk PII (rosters, identity links) still requires a role or an access request as defined on each table.

## 7. Audit policy

`audit_logs` is append-only from the client’s point of view (`INSERT` via security definer functions; no `UPDATE`/`DELETE` for anyone except via dashboard SQL by the project owner).

Must be logged:

- Institution approve/suspend
- Membership role changes
- Roster import
- Verification approve/reject
- Campaign open/close
- Feedback submit (metadata only)
- Moderation publish/reject
- Access request create/approve/deny
- Identity unmask
- Improvement action status changes

## 8. Threats Phase 2 is designed to resist

| Threat | Control |
| --- | --- |
| Student rates a teacher not teaching their class | Eligibility generated from enrollments |
| Double submit | Unique eligibility + row lock in RPC |
| Student updates ratings later | No update policy; RPC insert-only |
| Teacher enumerates `feedback_submissions` | RLS denies; reports only via RPC |
| Admin guesses student from timestamp | Submissions store `submitted_at`; teacher RPC does not return timestamps per row |
| Client skips required criteria | RPC checks set equality with `campaign_criteria` |
| Rating 0 or 99 | Check constraints |
| Campaign end before start | Check constraints |
| Hidden Flutter route for Super Admin | RLS still denies |

## 9. Data retention (v1 policy, not yet automated)

- Feedback remains for institutional history even if a student account is deleted; anonymized submissions stay.
- If a user deletion is requested, `profiles` is deactivated; identity links for confidential campaigns remain until a Super Admin retention job (Phase 9). **Not implemented in Phase 2.**
