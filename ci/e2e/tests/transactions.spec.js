// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * Transaction tests — verifies the transaction list and add-expense wizard
 */

const FLUTTER_READY_TIMEOUT = 60_000;
const FLUTTER_RENDER_WAIT = 5000;

test.describe('Transactions', () => {
    test.beforeEach(async ({ page }) => {
        page.on('console', msg => {
            console.log(`[BROWSER LOG] ${msg.text()}`);
        });
        page.on('pageerror', err => {
            console.log(`[BROWSER FATAL] ${err.message}`);
        });
    });

    test('transactions list page loads without errors', async ({ page }) => {
        /** @type {string[]} */
        const pageErrors = [];
        page.on('pageerror', (err) => pageErrors.push(err.message));

        await page.goto('/transactions');
        await page.waitForSelector('flt-glass-pane', { timeout: FLUTTER_READY_TIMEOUT });
        await page.waitForTimeout(FLUTTER_RENDER_WAIT);

        await page.screenshot({ path: 'test-results/transactions-list.png', fullPage: true });

        const fatal = pageErrors.filter(
            (e) =>
                !e.includes('ERR_NAME_NOT_RESOLVED') &&
                !e.includes('ERR_CONNECTION_REFUSED') &&
                !e.includes('back/forward cache')
        );
        expect(fatal).toHaveLength(0);
        expect(page.url()).toContain('/transactions');
    });

    test('add expense wizard page loads', async ({ page }) => {
        /** @type {string[]} */
        const pageErrors = [];
        page.on('pageerror', (err) => pageErrors.push(err.message));

        await page.goto('/add-expense-wizard');
        await page.waitForSelector('flt-glass-pane', { timeout: FLUTTER_READY_TIMEOUT });
        await page.waitForTimeout(FLUTTER_RENDER_WAIT);

        await page.screenshot({ path: 'test-results/add-expense-wizard.png', fullPage: true });

        const fatal = pageErrors.filter(
            (e) =>
                !e.includes('ERR_NAME_NOT_RESOLVED') &&
                !e.includes('ERR_CONNECTION_REFUSED') &&
                !e.includes('back/forward cache')
        );
        expect(fatal).toHaveLength(0);
    });
});

test.describe('Reports', () => {
    const reportRoutes = [
        '/dashboard/report/spending-category',
        '/dashboard/report/spending-time',
        '/dashboard/report/income-expense',
        '/dashboard/report/budget-performance',
        '/dashboard/report/goal-progress',
    ];

    test.beforeEach(async ({ page }) => {
        page.on('console', msg => {
            console.log(`[BROWSER LOG] ${msg.text()}`);
        });
        page.on('pageerror', err => {
            console.log(`[BROWSER FATAL] ${err.message}`);
        });
    });

    for (const route of reportRoutes) {
        test(`report page loads: ${route}`, async ({ page }) => {
            /** @type {string[]} */
            const pageErrors = [];
            page.on('pageerror', (err) => pageErrors.push(err.message));

            await page.goto(route);
            await page.waitForSelector('flt-glass-pane', { timeout: FLUTTER_READY_TIMEOUT });
            await page.waitForTimeout(3000);

            const screenshotName = route.replace(/\//g, '_').replace(/^_/, '');
            await page.screenshot({
                path: `test-results/${screenshotName}.png`,
                fullPage: true,
            });

            const fatal = pageErrors.filter(
                (e) =>
                    !e.includes('ERR_NAME_NOT_RESOLVED') &&
                    !e.includes('ERR_CONNECTION_REFUSED') &&
                    !e.includes('back/forward cache')
            );
            expect(fatal).toHaveLength(0);
        });
    }
});
