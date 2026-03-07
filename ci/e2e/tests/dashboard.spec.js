// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * Dashboard tests — verifies the main screen loads and navigation works
 * for an authenticated user.
 */

const FLUTTER_READY_TIMEOUT = 30_000;
const FLUTTER_RENDER_WAIT = 2000; // time for Flutter to paint content after canvas appears

test.describe('Dashboard', () => {
    /** @type {string[]} */
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        page.on('console', msg => {
            console.log(`[BROWSER LOG] ${msg.text()}`);
        });
        page.on('pageerror', err => {
            console.log(`[BROWSER FATAL] ${err.message}`);
            pageErrors.push(err.message);
        });
        await page.goto('/dashboard');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
    });

    test('dashboard loads without fatal errors', async ({ page }) => {
        // Let some time pass to capture delayed errors
        await page.waitForTimeout(1000);

        // Filter out known non-fatal Flutter web browser noise
        const fatalErrors = pageErrors.filter(
            (e) =>
                !e.includes('ERR_NAME_NOT_RESOLVED') &&
                !e.includes('ERR_CONNECTION_REFUSED') &&
                !e.includes('back/forward cache')
        );

        await page.screenshot({ path: 'test-results/dashboard-load.png', fullPage: true });
        expect(fatalErrors).toHaveLength(0);
    });

    test('dashboard renders a canvas (Flutter app is alive)', async ({ page }) => {
        const canvas = page.locator('canvas');
        await expect(canvas).toBeVisible();
    });

    test('page title is correct', async ({ page }) => {
        await expect(page).toHaveTitle(/Financial OS/i);
    });

    const routes = [
        { path: '/transactions', screenshot: true },
        { path: '/settings', screenshot: false },
        { path: '/groups', screenshot: false },
    ];

    for (const route of routes) {
        test(`navigating to ${route.path} works`, async ({ page }) => {
            await page.goto(route.path);
            await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });

            const url = page.url();
            expect(url).toContain(route.path);

            if (route.screenshot) {
                await page.screenshot({ path: `test-results${route.path.replace(/\//g, '-')}-page.png`, fullPage: true });
            }
        });
    }
});
