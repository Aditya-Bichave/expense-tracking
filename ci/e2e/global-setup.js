/**
 * global-setup.js
 *
 * Runs ONCE before any Playwright test.
 *
 * Strategy:
 *  1. Sign in to Supabase using email+password (no magic link, no OTP, no email credits).
 *  2. Launch a headless browser, navigate to the Flutter web app.
 *  3. Inject the Supabase session into localStorage under Flutter's session key.
 *  4. Save the full browser storage state to storage/auth-state.json.
 *  5. All test files use storageState: './storage/auth-state.json' → start pre-authenticated.
 */

require('dotenv').config({ path: __dirname + '/.env' });

const { chromium } = require('@playwright/test');
const { createClient } = require('@supabase/supabase-js');
const path = require('path');
const fs = require('fs');

const SUPABASE_URL = process.env.E2E_SUPABASE_URL || process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.E2E_SUPABASE_ANON_KEY || process.env.SUPABASE_ANON_KEY;
const TEST_EMAIL = process.env.E2E_TEST_EMAIL;
const TEST_PASSWORD = process.env.E2E_TEST_PASSWORD;
const BASE_URL = process.env.APP_BASE_URL || 'http://localhost:8080';
const BUILD_DIR = path.resolve(__dirname, process.env.BUILD_DIR || '../../build/web');
const STORAGE_DIR = path.join(__dirname, 'storage');
const AUTH_STATE_PATH = path.join(STORAGE_DIR, 'auth-state.json');

// SharedPreferences on Web uses 'flutter.' prefix by default.
// Matches 'SUPABASE_PERSIST_SESSION_KEY' in lib/core/network/supabase_config.dart
const FLUTTER_SESSION_KEY = 'SUPABASE_PERSIST_SESSION_KEY';

module.exports = async function globalSetup() {
    // ── Validate config ─────────────────────────────────────────────────────────
    const missing = [];
    if (!SUPABASE_URL || SUPABASE_URL.includes('PLACEHOLDER') || SUPABASE_URL.includes('YOUR_SUPABASE')) missing.push('SUPABASE_URL');
    if (!SUPABASE_ANON_KEY || SUPABASE_ANON_KEY.includes('PLACEHOLDER') || SUPABASE_ANON_KEY.includes('YOUR_SUPABASE')) missing.push('SUPABASE_ANON_KEY');
    if (!TEST_EMAIL) missing.push('E2E_TEST_EMAIL');
    if (!TEST_PASSWORD) missing.push('E2E_TEST_PASSWORD');

    if (missing.length > 0) {
        throw new Error(
            `[E2E globalSetup] Invalid or missing env vars: ${missing.join(', ')}\n` +
            `Please ensure these are set in ci/e2e/.env or the root .env file.\n` +
            `Current SUPABASE_URL: "${SUPABASE_URL}"`
        );
    }

    if (!fs.existsSync(BUILD_DIR)) {
        throw new Error(
            `[E2E globalSetup] Build directory not found: ${BUILD_DIR}\n` +
            `Run: flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
        );
    }

    // Ensure storage dir exists
    fs.mkdirSync(STORAGE_DIR, { recursive: true });

    // ── Step 1: Authenticate with Supabase ──────────────────────────────────────
    console.log('[E2E] Authenticating with Supabase (email+password)...');
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    let authData = null;
    let authError = null;
    for (let i = 0; i < 3; i++) {
        const result = await supabase.auth.signInWithPassword({
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });
        authData = result.data;
        authError = result.error;
        if (!authError && authData?.session) break;
        console.warn(`[E2E] Supabase auth attempt ${i+1} failed: ${authError?.message}. Retrying...`);
        await new Promise(r => setTimeout(r, 2000));
    }

    if (authError || !authData?.session) {
        throw new Error(
            `[E2E globalSetup] Supabase auth failed after retries: ${authError?.message || 'No session returned'}\n` +
            `Make sure the test user exists in Supabase Auth > Users with email+password enabled.`
        );
    }

    const { session } = authData;
    console.log(`[E2E] ✅ Authenticated as: ${authData.user?.email}`);

    // Ensure user has a profile so SessionCubit doesn't block routes with SessionNeedsProfileSetup
    console.log(`[E2E] Upserting user profile to bypass /profile-setup redirect...`);
    const { error: profileError } = await supabase
        .from('profiles')
        .upsert({
            id: session.user.id,
            full_name: 'E2E Tester',
            currency: 'USD',
            timezone: 'UTC'
        });
    if (profileError) {
        console.warn(`[E2E] Failed to upsert profile: ${profileError.message}. This might cause /profile-setup redirects.`);
    } else {
        console.log(`[E2E] ✅ Profile upserted successfully.`);
    }

    // Build the session JSON string that Supabase Flutter SDK stores in localStorage
    // The Flutter supabase_flutter package stores the full auth response JSON
    const sessionJson = JSON.stringify({
        access_token: session.access_token,
        refresh_token: session.refresh_token,
        token_type: session.token_type,
        expires_in: session.expires_in,
        expires_at: session.expires_at,
        user: session.user,
    });

    // ── Step 2: Inject session into browser storage ──────────────────────────────
    console.log('[E2E] Injecting session into browser localStorage...');
    const browser = await chromium.launch();
    const context = await browser.newContext();
    const page = await context.newPage();

    // Debug: capture console logs and errors
    page.on('console', msg => {
        if (msg.type() === 'error') console.log(`[BROWSER ERROR] ${msg.text()}`);
        else console.log(`[BROWSER LOG] ${msg.text()}`);
    });
    page.on('pageerror', err => {
        console.log(`[BROWSER FATAL] ${err.message}`);
    });

    // Navigate to the app first (localStorage is origin-scoped)
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 });

    // Inject the Supabase session the way Flutter's SecureLocalStorage expects it
    await page.evaluate(
        ({ key, value }) => {
            localStorage.setItem(key, value);
        },
        { key: FLUTTER_SESSION_KEY, value: sessionJson }
    );

    console.log(`[E2E] ✅ Session injected into localStorage['${FLUTTER_SESSION_KEY}']`);

    // ── Step 3: Save storage state ───────────────────────────────────────────────
    await context.storageState({ path: AUTH_STATE_PATH });
    console.log(`[E2E] ✅ Auth state saved to: ${AUTH_STATE_PATH}`);

    await browser.close();

    console.log('[E2E] globalSetup complete. Tests will start pre-authenticated. 🚀');
};
