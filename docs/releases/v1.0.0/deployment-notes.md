# Deployment Notes

## Release Context

Version 1.0.0 is the first official release of the application and supports a multi-platform Flutter codebase with a particularly mature web deployment path. The repository contains both general Flutter platform scaffolding and explicit infrastructure for web hosting, Supabase-backed services, smoke validation, and authenticated E2E testing.

## Runtime Targets

The repository contains platform directories for:

- Android
- iOS
- Web
- Windows
- macOS
- Linux

Operational deployment work in the Git history is concentrated on the web target.

## Build Requirements

### Flutter And Dart

- Flutter channel: `stable`
- Flutter project metadata revision: `d211f42860350d914a5ad8102f9ec32764dc6d06`
- Dart SDK constraint from `pubspec.yaml`: `>=3.8.0 <4.0.0`

The CI workflows use `subosito/flutter-action@v2` with the stable channel rather than pinning a human-readable Flutter version in workflow YAML.

### Node.js

Node is required for:

- Web smoke tests in `ci/smoke`
- Web E2E tests in `ci/e2e`
- Express-based static hosting in `server`
- CI reporting utilities in `ci/scripts`

The GitHub Actions workflows use Node.js `20` for smoke and E2E jobs.

### Other Tooling

- `build_runner` for generated Dart sources
- Supabase CLI in `.github/workflows/supabase.yml`
- `diff-cover` for local or CI coverage verification
- Docker for the containerized web deployment path

## Required Environment Configuration

### Flutter web build variables

Production web builds expect the following Dart defines:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

These values are passed in GitHub Actions during web deployment and are required for authenticated, synchronized environments.

### E2E variables

Authenticated Playwright E2E tests require:

- `E2E_SUPABASE_URL`
- `E2E_SUPABASE_ANON_KEY`
- `E2E_TEST_EMAIL`
- `E2E_TEST_PASSWORD`
- `APP_BASE_URL` (defaults to `http://localhost:8080` in test configuration)
- `BUILD_DIR` for the compiled web artifact path

### Hosting assumptions

For deployed web hosting, the application assumes:

- SPA rewrite behavior to `index.html`
- HTTPS in production for Supabase and auth flows
- Availability of the compiled Flutter web assets under the configured static root

## Build Commands

### Core project verification

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
./ci/check_coverage.sh
```

### Release web build

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=<your-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

### Smoke verification

```bash
cd ci/smoke
npm ci
npm run smoke
```

### E2E verification

```bash
cd ci/e2e
npm ci
npx playwright install chromium
npx playwright test
```

## Deployment Topologies

## 1. GitHub Actions published static web build

The repository includes `.github/workflows/deploy_web.yml`, which:

- Builds Flutter web on pushes to `main`
- Injects Supabase values through `--dart-define`
- Copies the generated web build into `server/public`
- Commits the generated site back to the repository as `chore: update built web [skip ci]`

This is the primary repository-managed publication flow reflected in the Git history.

## 2. Render-style Node hosting

The repository includes a Node server under `server/server.js` and deployment guidance indicating a Render web service model:

- Runtime: Node
- Root directory: `server`
- Build command: `npm install`
- Start command: `node server.js`

The Express server:

- Serves the built Flutter web files from `server/public`
- Provides SPA fallback routing
- Accepts client log events through `POST /log`

## 3. Docker + Nginx web deployment

A containerized deployment path is also available:

- Multi-stage Docker build using `ghcr.io/cirruslabs/flutter:stable` for build output
- Nginx runtime image for serving static assets
- Custom `nginx.conf` that enables SPA fallback and cache controls

This path is appropriate when the team wants image-based delivery independent of repository-hosted static assets.

## 4. Vercel static hosting

`vercel.json` configures:

- `outputDirectory` as `server/public`
- Clean URLs
- Rewrite of all routes to `/index.html`

This supports deployment from the already-published static artifact tree.

## CI/CD Setup

The main CI pipeline in `.github/workflows/flutter-ci.yml` includes:

- Static formatting and analysis checks
- Policy checks for forbidden `print()` and unmanaged TODO usage
- Code generation consistency checks
- Unit and widget tests with coverage collection
- Total coverage enforcement at 50%
- Web release build
- Bundle size verification using `ci/budgets.json`
- Web smoke tests using Playwright
- Authenticated Playwright E2E tests
- PR reporting with artifacts and status summaries

There is also a Supabase workflow that validates the presence of migration files when backend schema changes occur.

## Required Infrastructure Services

For the full 1.0.0 feature set, the deployment environment needs:

- A Supabase project for auth, database, realtime, and RLS enforcement
- Applied schema migrations from `supabase/migrations`
- Edge/serverless functions for invite flows under `supabase/functions`
- A static file host or Node host for Flutter web artifacts
- CI secrets for build and E2E environments

## Production Configuration Assumptions

- Supabase anon keys are safe for client distribution; service-role keys must not be embedded in Flutter builds.
- The application expects secure local storage support on platforms where encrypted Hive is used.
- Web hosting must preserve client-side routing through rewrite or fallback rules.
- Cache policy should keep HTML/bootstrap files fresh while allowing aggressive caching of immutable assets.
- Collaborative features assume RLS and invite functions are deployed alongside the app, not after it.

## Post-Deployment Verification

After deployment, verify at minimum:

- App bootstrap reaches the intended landing screen without initialization errors.
- Login or session restoration works with the target Supabase project.
- Dashboard renders successfully.
- Profile setup loads and saves correctly.
- Group and invite flows resolve routes correctly.
- Smoke tests and E2E tests are green for the release commit.

## Deployment Risks To Watch

- Recent March 7, 2026 fixes indicate Supabase initialization and router redirects were still being refined late in the release cycle.
- The repository-committed `server/public` artifact can drift from source if the publication workflow is bypassed.
- Hosting environments that do not implement SPA rewrites will break deep links and invite flows.
