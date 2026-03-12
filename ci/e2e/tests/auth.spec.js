// @ts-check
const { test, expect } = require('@playwright/test');
const {
    setupErrorCollector,
    gotoFlutterRoute
} = require('../helpers/testSetup');

/**
 * Auth tests verify that deterministic E2E bootstrap routes the seeded user
 * straight to the dashboard.
 */

test.describe('Authentication @flow:auth', () => {
    /** @type {string[]} */
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
    });

    test('authenticated user lands on dashboard (not login)', async ({ page }) => {
        await gotoFlutterRoute(page, '/dashboard');

        // Confirm we are NOT stuck on auth/setup pages
        const url = page.url();
        expect(url).not.toContain('/login');
        expect(url).not.toContain('/setup');
        expect(url).not.toContain('/lock');
        expect(url).toContain('/dashboard');
    });
});
