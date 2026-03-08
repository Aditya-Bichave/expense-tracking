/**
 * global-setup.js
 *
 * Runs ONCE before any Playwright test.
 *
 * Strategy:
 *  1. Sign in to Supabase using email+password (no magic link, no OTP, no email credits).
 *  2. Launch a headless browser, navigate to the Flutter web app.
 *  3. Inject the Supabase session into localStorage under Flutter's session key.
 *  4. Navigate to /e2e-bypass to let Flutter write the mock profile to Hive.
 *  5. Save the full browser storage state to storage/auth-state.json.
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

// Matches 'SUPABASE_PERSIST_SESSION_KEY' in lib/core/network/supabase_config.dart
const FLUTTER_SESSION_KEY = 'SUPABASE_PERSIST_SESSION_KEY';

module.exports = async function globalSetup() {
    const missing = [];
    if (!SUPABASE_URL || SUPABASE_URL.includes('PLACEHOLDER')) missing.push('SUPABASE_URL');
    if (!SUPABASE_ANON_KEY || SUPABASE_ANON_KEY.includes('PLACEHOLDER')) missing.push('SUPABASE_ANON_KEY');
    if (!TEST_EMAIL) missing.push('E2E_TEST_EMAIL');
    if (!TEST_PASSWORD) missing.push('E2E_TEST_PASSWORD');

    if (missing.length > 0) {
        throw new Error(`[E2E globalSetup] Invalid or missing env vars: ${missing.join(', ')}`);
    }

    fs.mkdirSync(STORAGE_DIR, { recursive: true });

    console.log('[E2E] Authenticating with Supabase (email+password)...');
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    let authData = null;
    let authError = null;
    for (let i = 0; i < 3; i++) {
        const result = await supabase.auth.signInWithPassword({ email: TEST_EMAIL, password: TEST_PASSWORD });
        authData = result.data;
        authError = result.error;
        if (!authError && authData?.session) break;
        console.warn(`[E2E] Supabase auth attempt ${i+1} failed: ${authError?.message}. Retrying...`);
        await new Promise(r => setTimeout(r, 2000));
    }

    if (authError || !authData?.session) {
        throw new Error(`[E2E globalSetup] Supabase auth failed: ${authError?.message}`);
    }

    const { session } = authData;
    console.log(`[E2E] ✅ Authenticated as: ${authData.user?.email}`);

    const sessionJson = JSON.stringify({
        access_token: session.access_token,
        refresh_token: session.refresh_token,
        token_type: session.token_type,
        expires_in: session.expires_in,
        expires_at: session.expires_at,
        user: session.user,
    });

    console.log('[E2E] Injecting session into browser localStorage...');
    const browser = await chromium.launch();
    const context = await browser.newContext();
    const page = await context.newPage();

    page.on('console', msg => {
        if (msg.type() === 'error') console.log(`[BROWSER ERROR] ${msg.text()}`);
        else console.log(`[BROWSER LOG] ${msg.text()}`);
    });

    // 1. Load base to ensure localStorage origin is set
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 });

    // 2. Inject Supabase session
    await page.evaluate(({ key, value }) => { localStorage.setItem(key, value); }, { key: FLUTTER_SESSION_KEY, value: sessionJson });
    console.log(`[E2E] ✅ Session injected.`);

    // 3. Navigate to E2E bypass hook so Dart can construct local Hive profile data
    console.log('[E2E] Navigating to bypass hook to initialize Hive local profile state...');
    await page.goto(BASE_URL + '/#/e2e-bypass');

    // 4. Wait for the app to redirect back to Dashboard (confirming SessionCubit verified the profile)
    await page.waitForURL('**/dashboard*', { timeout: 30000 });
    console.log(`[E2E] ✅ Profile bypassed and landed on Dashboard.`);

    // 5. Save the final storage state including Hive's IndexedDB caches
    await context.storageState({ path: AUTH_STATE_PATH });
    console.log(`[E2E] ✅ Auth state saved to: ${AUTH_STATE_PATH}`);

    await browser.close();
};
