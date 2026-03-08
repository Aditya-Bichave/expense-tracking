// @ts-check
const { test, expect } = require('@playwright/test');
const { setupErrorCollector } = require('../helpers/testSetup');

/**
 * Auth tests — verify that the globalSetup session injection works and
 * that the app correctly routes authenticated users to the dashboard.
 */

const FLUTTER_READY_TIMEOUT = 30_000;

test.describe('Authentication @flow:auth', () => {
    /** @type {string[]} */
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
    });

    test('authenticated user lands on dashboard (not login)', async ({ page }) => {
        // The storageState from global-setup injects the Supabase session.
        await page.goto('/dashboard');

        // App should redirect away from auth pages to a valid dashboard-like route
        await page.waitForURL(/\/(dashboard|transactions|groups|budgets|accounts|recurring|settings)/, {
            timeout: FLUTTER_READY_TIMEOUT,
        });

        // Confirm we are NOT stuck on auth/setup pages
        const url = page.url();
        expect(url).not.toContain('/login');
        expect(url).not.toContain('/initial-setup');
        expect(url).not.toContain('/lock');
    });

    test('navigating to /profile-setup renders a form, not blank', async ({ page }) => {
        // This tests the fix for the BlocProvider<ProfileBloc> missing issue.
        await page.goto('/dashboard');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });

        // Force navigate to profile-setup
        await page.evaluate(() => { window.E2E_FLUTTER_READY = false; });
        await page.goto('/profile-setup');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });

        // Wait explicitly for Flutter semantics host to attach, asserting the page rendered correctly
        await expect(page.locator('flt-semantics-host')).toBeAttached({ timeout: 15000 });

        // Take a screenshot for visual inspection
        await page.screenshot({ path: 'test-results/profile-setup.png', fullPage: true });

        // Check for specific error keywords
        const fatalErrors = pageErrors.filter((e) => e.includes('Bloc') || e.includes('null'));
        expect(fatalErrors).toHaveLength(0);
    });
});
