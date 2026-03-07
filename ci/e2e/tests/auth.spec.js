// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * Auth tests — verify that the globalSetup session injection works and
 * that the app correctly routes authenticated users to the dashboard.
 */

const FLUTTER_READY_TIMEOUT = 60_000;

test.describe('Authentication', () => {
    test.beforeEach(async ({ page }) => {
        page.on('console', msg => {
            console.log(`[BROWSER LOG] ${msg.text()}`);
        });
        page.on('pageerror', err => {
            console.log(`[BROWSER FATAL] ${err.message}`);
        });
    });

    test('authenticated user lands on dashboard (not login)', async ({ page }) => {
        // The storageState from global-setup injects the Supabase session.
        await page.goto('/dashboard');

        // Wait for Flutter to finish loading the engine (CanvasKit can be slow)
        await page.waitForSelector('flt-glass-pane', { timeout: 60000 });

        // Should be at /dashboard or redirected to a valid sub-page
        await expect(page).toHaveURL(/.*dashboard|.*reports|.*transactions/, { timeout: 30000 });

        // App should redirect away from auth pages
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
        await page.waitForSelector('flt-glass-pane', { timeout: FLUTTER_READY_TIMEOUT });

        // Verify no fatal JS errors
        /** @type {string[]} */
        const pageErrors = [];
        page.on('pageerror', (err) => pageErrors.push(err.message));

        // Force navigate to profile-setup
        await page.goto('/profile-setup');
        await page.waitForSelector('flt-glass-pane', { timeout: 30000 });

        // Look for some text that would be on the profile setup page
        // Using a broad text check because Flutter renders everything in Shadow DOM or Canvas
        await expect(page.getByText(/Setup Your Profile/i).or(page.getByText(/Username/i))).toBeVisible({ timeout: 15000 });

        // Wait long enough for Flutter to render (not blank)
        await page.waitForTimeout(4000);

        // Take a screenshot for visual inspection
        await page.screenshot({ path: 'test-results/profile-setup.png', fullPage: true });

        // Check for specific error keywords
        const fatalErrors = pageErrors.filter((e) => e.includes('Bloc') || e.includes('null'));
        expect(fatalErrors).toHaveLength(0);
    });
});
