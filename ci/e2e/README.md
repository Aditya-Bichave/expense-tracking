# E2E Test Suite

Playwright-based E2E tests for FinancialOS. The suite runs the Flutter web app in deterministic `E2E_MODE`, seeds local Hive state on startup, and avoids live auth/session dependencies.

## How it works

1. Flutter is built with `--dart-define=E2E_MODE=true`.
2. App bootstrap seeds a known local dataset and authenticated session state.
3. Playwright serves the built web bundle with the local static server in `helpers/server.js`.
4. Tests navigate through the app using stable hash routes and the app's explicit ready signal.

No Supabase secrets, test credentials, or pre-generated browser storage are required for the E2E suite.

## Setup

### 1. Optional `.env`

Copy `.env.example` to `.env` only if you need to override the local server URL or build directory:

```bash
cp .env.example .env
```

### 2. Run through the unified runner

```bash
# From the repository root
./run_e2e.sh
```

### 3. Windows runner

```bat
cd ci\e2e
run_e2e.bat
```

## Running Tests

```bash
# Headless (default)
npm run e2e

# Headed (watch the browser)
npm run e2e:headed

# Interactive UI mode
npm run e2e:ui

# Single spec
npx playwright test tests/auth.spec.js

# Show report after run
npm run e2e:report
```

## Test structure

| Spec | What it tests |
|------|--------------|
| `auth.spec.js` | Seeded auth bootstrap and initial dashboard landing |
| `budgets.spec.js` | Plan tab loads from the seeded dashboard session |
| `dashboard.spec.js` | Dashboard loads and shell navigation works |
| `groups.spec.js` | Groups tab loads without fatal browser errors |
| `transactions.spec.js` | Transactions list, add-expense wizard, and report routes |

## CI Usage

GitHub Actions should build the web app in `E2E_MODE` and then invoke the root runner:

```yaml
- name: Build Web
  run: flutter build web --release --pwa-strategy=none --dart-define=E2E_MODE=true

- name: Run E2E Tests
  env:
    APP_BASE_URL: http://localhost:8080
    BUILD_DIR: build/web
  run: ./run_e2e.sh --skip-build
```

## Artifacts

- `test-results/` - screenshots, traces, and coverage output
- `playwright-report/` - full HTML report (`npm run e2e:report` to open)
