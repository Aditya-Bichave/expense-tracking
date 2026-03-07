// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * Transaction tests — verifies the transaction list and add-expense wizard
 */

const FLUTTER_READY_TIMEOUT = 30_000;
const FLUTTER_RENDER_WAIT = 2000;

const IGNORABLE_ERRORS = [
    'ERR_NAME_NOT_RESOLVED',
    'ERR_CONNECTION_REFUSED',
    'back/forward cache',
];

/**
 * @param {string[]} errors
 * @returns {string[]}
 */
const filterFatalErrors = (errors) => {
    return errors.filter(e => !IGNORABLE_ERRORS.some(ignored => e.includes(ignored)));
};

test.describe('Transactions @flow:transactions', () => {
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
    });

    test('transactions list page loads without errors', async ({ page }) => {
        await page.goto('/transactions');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });

        await page.screenshot({ path: 'test-results/transactions-list.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
        expect(page.url()).toContain('/transactions');
    });

    test('add expense wizard page loads', async ({ page }) => {
        await page.goto('/dashboard');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
        await page.goto('/add-expense-wizard');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });

        await page.screenshot({ path: 'test-results/add-expense-wizard.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
    });
});

test.describe('Reports @flow:reports', () => {
    const reportRoutes = [
        '/dashboard/spending_category',
        '/dashboard/spending_time',
        '/dashboard/income_expense',
        '/dashboard/budget_performance',
        '/dashboard/goal_progress',
    ];

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
    });

    for (const route of reportRoutes) {
        test(`report page loads: ${route}`, async ({ page }) => {
            await page.goto('/dashboard');
            await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
            await page.goto(route);
            await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });

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
