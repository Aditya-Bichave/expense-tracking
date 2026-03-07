# E2E Test Suite

Playwright-based E2E tests for FinancialOS. Uses email+password auth to bypass magic links — **no email credits consumed**.

## How it works

`globalSetup.js` runs once before tests:

1. Signs in to Supabase using credentials from environment variables (`E2E_TEST_EMAIL` and `E2E_TEST_PASSWORD`)
2. Injects the session into browser `localStorage` under Flutter's session key
3. Saves the state to `storage/auth-state.json`
4. All tests start pre-authenticated — no login page shown

## Setup (one-time)

### 1. Create `.env`

Copy `.env.example` to `.env` and fill in your Supabase project's URL and anon key:

```bash
cp .env.example .env
# then edit .env with your SUPABASE_URL and SUPABASE_ANON_KEY
```

### 2. Build the Flutter web app

```bash
# From the app root (apps/mobile/expense_tracking)
flutter build web --release \
  --dart-define=SUPABASE_URL=<your-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

### 3. Install dependencies (already done on first setup)

```bash
npm install
npx playwright install chromium
```

## Running Tests

```bash
# Headless (default)
npm run e2e

# Headed (watch the browser)
npm run e2e:headed

# Interactive UI mode (best for debugging)
npm run e2e:ui

# Single spec
npx playwright test tests/auth.spec.js

# Show report after run
npm run e2e:report
```

## Test structure

| Spec | What it tests |
|------|--------------|
| `auth.spec.js` | Session injection works, auth redirects, profile-setup page renders |
| `dashboard.spec.js` | Dashboard loads, nav routes work, page title correct |
| `transactions.spec.js` | Transactions list, add-expense wizard, all 5 report pages |

## CI Usage

In GitHub Actions, add secrets `E2E_SUPABASE_URL`, `E2E_SUPABASE_ANON_KEY` and run:

```yaml
- name: Run E2E Tests
  env:
    E2E_SUPABASE_URL: ${{ secrets.E2E_SUPABASE_URL }}
    E2E_SUPABASE_ANON_KEY: ${{ secrets.E2E_SUPABASE_ANON_KEY }}
    E2E_TEST_EMAIL: test@financialos.co
    E2E_TEST_PASSWORD: ${{ secrets.E2E_TEST_PASSWORD }}
    BUILD_DIR: ../../build/web
  run: |
    cd ci/e2e
    npm ci
    npx playwright install chromium --with-deps
    npm run e2e
```

## Artifacts

- `test-results/` — screenshots on failure + per-route screenshots
- `playwright-report/` — full HTML report (`npm run e2e:report` to open)
- `storage/auth-state.json` — saved session (gitignored, regenerated each run)
