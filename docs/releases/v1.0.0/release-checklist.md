# Release Checklist

## Code Readiness

- [ ] Confirm the release branch or `main` HEAD matches the intended 1.0.0 release commit.
- [ ] Confirm `pubspec.yaml` version is `1.0.0+1`.
- [ ] Confirm generated files are up to date.
- [ ] Confirm no debug-only code, stray temporary files, or forbidden `print()` calls remain.
- [ ] Confirm no undocumented schema or environment changes are included.

## Dependency And Environment Validation

- [ ] Run `flutter pub get`.
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`.
- [ ] Confirm Node dependencies install cleanly in `ci/smoke`, `ci/e2e`, and `server` where required.
- [ ] Confirm Supabase configuration and migration files are present and ordered correctly.
- [ ] Confirm required secrets are available for CI and deployment environments.

## Testing Verification

- [ ] Run `dart format .`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `./ci/check_coverage.sh` and verify diff coverage meets project policy.
- [ ] Run golden tests or verify goldens are unchanged when UI changes are included.
- [ ] Run web smoke tests against a release web build.
- [ ] Run authenticated Playwright E2E tests with valid Supabase credentials.

## Build Validation

- [ ] Build Flutter web in release mode with production `--dart-define` values.
- [ ] Confirm `build/web` starts correctly under local static hosting.
- [ ] Confirm startup time remains within acceptable bounds from smoke reporting.
- [ ] Confirm bundle size does not regress beyond CI budget thresholds.
- [ ] Confirm mobile and desktop targets still compile if the release scope includes them.

## Data And Sync Readiness

- [ ] Confirm Hive adapter registrations are aligned with persisted models.
- [ ] Confirm no Hive `TypeId` or `FieldId` changes were introduced without migration planning.
- [ ] Confirm Supabase migrations have been applied in the intended target environment.
- [ ] Confirm RLS policies for groups, expenses, invites, and profiles are present.
- [ ] Confirm sync queue, realtime subscriptions, and retry logic function in an authenticated environment.

## Security Readiness

- [ ] Confirm `SUPABASE_URL` and `SUPABASE_ANON_KEY` are provided only through approved configuration paths.
- [ ] Confirm no service-role credentials are embedded in client artifacts.
- [ ] Confirm biometric lock, secure storage, and encrypted Hive initialization work on target platforms.
- [ ] Confirm logs do not expose PII beyond approved identifiers.

## Deployment Readiness

- [ ] Confirm the web deployment target is selected: GitHub Actions artifact publication, Render-style Node hosting, Docker/Nginx image, or Vercel static output.
- [ ] Confirm `server/public` contains the intended release build if repository-hosted artifacts are used.
- [ ] Confirm hosting rewrite rules support SPA navigation.
- [ ] Confirm cache policy for `index.html`, `main.dart.js`, and static assets is correct.
- [ ] Confirm post-deploy smoke verification is scheduled.

## Documentation Readiness

- [ ] Review `release-notes.md` for stakeholder accuracy.
- [ ] Review `technical-summary.md` for engineering accuracy.
- [ ] Review `deployment-notes.md` against the actual target environment.
- [ ] Review `known-issues.md` with engineering leads before publication.
- [ ] Archive the final release commit SHA and CI artifact links.

## Release Execution

- [ ] Tag the release commit as `v1.0.0` if a Git tag is required.
- [ ] Publish release notes through the chosen release channel.
- [ ] Verify GitHub Actions completed successfully for the release commit.
- [ ] Verify the deployed application opens, authenticates, and reaches the dashboard.
- [ ] Record any post-release deviations or hotfixes against the 1.0.0 release record.
