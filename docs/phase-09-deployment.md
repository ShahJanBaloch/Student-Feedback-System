# Phase 9 — Validation and deployment

## Automated checks

GitHub Actions runs Flutter analysis, tests with coverage, and a release-mode
web build for pushes and pull requests. The CI build omits Supabase
configuration so it does not need project credentials.

The CI web build validates compilation only; it is not a deployable app because
Supabase configuration is intentionally absent. Phase 6's student submission
UI, hosted RLS validation, and provider-specific deployment are still release
blockers.

Run the same checks locally:

```powershell
flutter analyze --no-fatal-infos
flutter test --coverage
flutter build web --release
```

## Supabase release checks

1. Apply every migration in filename order, including
   `20261116000009_target_report_scope.sql` and
   `20261116000010_phase8_moderation_rpc.sql`, then run `supabase/seed.sql`.
2. Verify login, student verification, campaign submission, role-specific reports,
   comment moderation, notifications, and improvement actions with representative
   accounts on the hosted project.
3. Confirm student and teacher requests are constrained by RLS; teachers must not
   be able to read respondent identities or raw submissions.
4. Confirm moderation and improvement status changes create audit records.

Do not treat a successful local build or a SQL Editor run as proof of these
hosted Auth/RLS checks.

## Static web deployment

1. Copy `.env.example` to `.env` locally and set the hosted Supabase URL and
   anon/publishable key.
2. Build the production app:

   ```powershell
   flutter build web --release --dart-define-from-file=.env --base-href /
   ```

3. Publish the contents of `build/web/` to an HTTPS static host. Configure
   unknown application paths to serve `index.html` so GoRouter routes work on
   refresh and direct navigation.
4. Set the production domain as the Supabase Auth Site URL and add the required
   sign-in redirect URLs and the `/reset-password` route to the Auth redirect
   allowlist.
5. Test sign-in, sign-out, browser refresh, and role-based navigation on the
   deployed domain.

The anon/publishable key is included in the client build and is not a secret.
Never use a `service_role` key in Flutter, CI build variables, or static hosting.
Keep `.env` out of source control. Provider-specific domain, redirect, and
rollback settings must be completed in the chosen hosting provider.
