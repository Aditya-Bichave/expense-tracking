// @ts-check
const { test, expect } = require('@playwright/test');
const { setupErrorCollector } = require('../helpers/testSetup');

/**
 * Dashboard tests — verifies the main screen loads and navigation works
 * for an authenticated user.
 */

const FLUTTER_READY_TIMEOUT = 30_000;
const FLUTTER_RENDER_WAIT = 2000; // time for Flutter to paint content after canvas appears

/**
 * Perform client-side navigation within Flutter Web to avoid deep-link boot crashes.
 * @param {import('@playwright/test').Page} page
 * @param {string} path
 */
async function navigateClientSide(page, path) {
    await page.evaluate(() => { window.E2E_FLUTTER_READY = false; });
    await page.evaluate((r) => {
        window.history.pushState({}, '', r);
        window.dispatchEvent(new Event('popstate'));
    }, path);
    await page.waitForURL(`**${path}*`, { timeout: 10000 });
    await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
    await page.waitForTimeout(FLUTTER_RENDER_WAIT);
}

test.describe('Dashboard @flow:dashboard', () => {
    /** @type {string[]} */
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
        await page.goto('/dashboard');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
    });

    test('dashboard loads without fatal errors', async ({ page }) => {
        await page.waitForTimeout(FLUTTER_RENDER_WAIT);

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
                await page.screenshot({ path: `test-results${route.path.replace(/\//g, '-')}-page.png`, fullPage: true });
            }
        });
    }
});
