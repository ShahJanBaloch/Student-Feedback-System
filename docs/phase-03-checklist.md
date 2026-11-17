# Phase 3 — Development checklist

## Objective

Create a runnable Flutter shell: Material 3 theme, GoRouter, Riverpod, student bottom navigation, and placeholder dashboards. No real Auth yet.

## Implemented in the repository

- [x] Feature-first `lib/` layout
- [x] `Env` supports public fallback values and `--dart-define-from-file=.env.example` overrides
- [x] Material 3 colors from the product spec
- [x] Splash, login, register, student shell, teacher/admin placeholders
- [x] Debug UI preview (not a security control)
- [x] Widget tests for splash → login and `EmptyState`

## Verified locally (this machine)

- [x] `flutter analyze` after fixing non-const `AppBar` usage
- [x] `flutter test`
- [ ] Chrome run is environment-dependent; use `scripts/run_chrome.ps1`

## Not Phase 3 (do not treat as done)

- [ ] Supabase sign-in
- [ ] Profile / membership reads
- [ ] Student verification
- [ ] Campaigns and analytics

## Compatibility

Phase 3 does not change SQL. Table and RPC names from Phase 2 remain the contract for Phase 4.
