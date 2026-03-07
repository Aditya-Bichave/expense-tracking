// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * Dashboard tests — verifies the main screen loads and navigation works
 * for an authenticated user.
 */

const FLUTTER_READY_TIMEOUT = 60_000;
const FLUTTER_RENDER_WAIT = 5000; // time for Flutter to paint content after canvas appears

test.describe('Dashboard', () => {
    test.beforeEach(async ({ page }) => {
        page.on('console', msg => {
            console.log(`[BROWSER LOG] ${msg.text()}`);
        });
        page.on('pageerror', err => {
            console.log(`[BROWSER FATAL] ${err.message}`);
        });
        await page.goto('/dashboard');
        await page.waitForSelector('flt-glass-pane', { timeout: FLUTTER_READY_TIMEOUT });
        // Let Flutter finish rendering the initial frame
        await page.waitForTimeout(FLUTTER_RENDER_WAIT);
    });

    test('dashboard loads without fatal errors', async ({ page }) => {
        /** @type {string[]} */
        const pageErrors = [];
        page.on('pageerror', (err) => pageErrors.push(err.message));

        // Let some time pass to capture delayed errors
        await page.waitForTimeout(3000);

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

    test('navigating to /transactions works', async ({ page }) => {
        await page.goto('/transactions');
        await page.waitForSelector('canvas', { timeout: FLUTTER_READY_TIMEOUT });
        await page.waitForTimeout(3000);

        const url = page.url();
        expect(url).toContain('/transactions');

        await page.screenshot({ path: 'test-results/transactions-page.png', fullPage: true });
    });

    test('navigating to /settings works', async ({ page }) => {
        await page.goto('/settings');
        await page.waitForSelector('canvas', { timeout: FLUTTER_READY_TIMEOUT });
        await page.waitForTimeout(3000);

        const url = page.url();
        expect(url).toContain('/settings');
    });

    test('navigating to /groups works', async ({ page }) => {
        await page.goto('/groups');
        await page.waitForSelector('canvas', { timeout: FLUTTER_READY_TIMEOUT });
        await page.waitForTimeout(3000);

        const url = page.url();
        expect(url).toContain('/groups');
    });
});
