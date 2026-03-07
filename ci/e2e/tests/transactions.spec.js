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

test.describe('Transactions', () => {
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
        await page.waitForSelector('flt-glass-pane', { timeout: FLUTTER_READY_TIMEOUT });

        // TODO: Replace with condition-based wait (e.g. app-loaded hook) when available
        await page.waitForTimeout(FLUTTER_RENDER_WAIT);

        await page.screenshot({ path: 'test-results/transactions-list.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
        expect(page.url()).toContain('/transactions');
    });

    test('add expense wizard page loads', async ({ page }) => {
        await page.goto('/add-expense-wizard');
        await page.waitForSelector('flt-glass-pane', { timeout: FLUTTER_READY_TIMEOUT });

        // TODO: Replace with condition-based wait
        await page.waitForTimeout(FLUTTER_RENDER_WAIT);

        await page.screenshot({ path: 'test-results/add-expense-wizard.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
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
            await page.goto(route);
            await page.waitForSelector('flt-glass-pane', { timeout: FLUTTER_READY_TIMEOUT });

            // TODO: Replace with condition-based wait
            await page.waitForTimeout(FLUTTER_RENDER_WAIT);

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
