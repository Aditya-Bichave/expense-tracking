// @ts-check
const { test, expect } = require('@playwright/test');
const {
    setupErrorCollector,
    navigateClientSide,
    filterFatalErrors,
    FLUTTER_READY_TIMEOUT
} = require('../helpers/testSetup');

/**
 * Transaction tests — verifies the transaction list and add-expense wizard
 */

test.describe('Transactions @flow:transactions', () => {
    /** @type {string[]} */
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
    });

    test('transactions list page loads without errors', async ({ page }) => {
        await page.goto('/dashboard');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
        await navigateClientSide(page, '/transactions');

        await page.screenshot({ path: 'test-results/transactions-list.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
        expect(page.url()).toContain('/transactions');
    });

    test('add expense wizard page loads', async ({ page }) => {
        await page.goto('/dashboard');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
        await navigateClientSide(page, '/add-expense-wizard');

        await page.screenshot({ path: 'test-results/add-expense-wizard.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
    });
});

test.describe('Reports @flow:reports', () => {
    const reportRoutes = [
        '/spending_category',
        '/spending_time',
        '/income_expense',
        '/budget_performance',
        '/goal_progress',
    ];

    /** @type {string[]} */
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
    });

    for (const route of reportRoutes) {
        test(`report page loads: ${route}`, async ({ page }) => {
            await page.goto('/dashboard');
            await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
            await navigateClientSide(page, route);

            const screenshotName = route.replace(/\//g, '_').replace(/^_/, '');
            await page.screenshot({
                path: `test-results/${screenshotName}.png`,
                fullPage: true,
            });

            const fatal = filterFatalErrors(pageErrors);
            expect(fatal).toHaveLength(0);
        });
    }
});
