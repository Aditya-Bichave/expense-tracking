// @ts-check
const { test, expect } = require('@playwright/test');
const {
    setupErrorCollector,
    gotoFlutterRoute,
    navigateClientSide,
    filterFatalErrors,
} = require('../helpers/testSetup');

/**
 * Dashboard tests — verifies the main screen loads and navigation works
 * for an authenticated user.
 */

test.describe('Dashboard @flow:dashboard', () => {
    /** @type {string[]} */
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
        await gotoFlutterRoute(page, '/dashboard');
    });

    test('dashboard loads without fatal errors', async ({ page }) => {
        // Use shared error filter
        const fatalErrors = filterFatalErrors(pageErrors);

        await page.screenshot({ path: 'test-results/dashboard-load.png', fullPage: true });
        expect(fatalErrors).toHaveLength(0);
    });

    test('dashboard renders a canvas (Flutter app is alive)', async ({ page }) => {
        const canvas = page.locator('canvas, flt-semantics-host');
        await expect(canvas.first()).toBeVisible({ timeout: 15000 });
    });

    const routes = [
        { path: '/transactions', screenshot: true },
        { path: '/settings', screenshot: false },
        { path: '/groups', screenshot: false },
    ];

    for (const route of routes) {
        test(`navigating to ${route.path} works`, async ({ page }) => {
            await navigateClientSide(page, route.path);

            const url = page.url();
            expect(url).toContain(route.path);

            if (route.screenshot) {
                await page.screenshot({ path: `test-results/${route.path.replace(/\//g, '-')}-page.png`, fullPage: true });
            }
        });
    }
});
