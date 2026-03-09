// @ts-check
const { test, expect } = require('@playwright/test');
const {
    setupErrorCollector,
    FLUTTER_READY_TIMEOUT
} = require('../helpers/testSetup');

/**
 * Auth tests — verify that the globalSetup session injection works and
 * that the app correctly routes authenticated users to the dashboard.
 */

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

    // NOTE: The previous test checking /profile-setup has been removed because global-setup.js
    // now explicitly provisions a complete mock profile. GoRouter inherently rejects
    // access to /profile-setup for users with a complete profile, immediately redirecting
    // them to /dashboard. Testing this specific flow would require a dedicated mocked user state.
});
