# Supabase (Phase 2)

Run files in this order in the SQL Editor of project `ydfprhodrltkykqxhvnc`:

1. `migrations/20251114000001_extensions_enums.sql`
2. `migrations/20251114000002_identity.sql`
3. `migrations/20251114000003_academics.sql`
4. `migrations/20251114000004_campaigns_feedback.sql`
5. `migrations/20251114000005_admin_comms.sql`
6. `migrations/20251114000006_functions.sql`
7. `migrations/20251114000007_rls.sql`
8. `migrations/20251114000008_grants.sql`
9. `migrations/20261116000009_target_report_scope.sql`
10. `migrations/20261116000010_phase8_moderation_rpc.sql`
11. `seed.sql`

If a file errors, stop. Do not skip ahead. Fix the error, then continue.

Applying SQL does not by itself prove Auth or RLS with a student JWT. Verify the app with representative student, teacher, and institution-admin accounts after migration.
