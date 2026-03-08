// @ts-check
const { test, expect } = require('@playwright/test');
const {
    setupErrorCollector,
    navigateClientSide,
    filterFatalErrors,
    FLUTTER_READY_TIMEOUT
} = require('../helpers/testSetup');

test.describe('Budgets @flow:budget', () => {
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
    });

    test('budgets list page loads without errors', async ({ page }) => {
        await page.goto('/dashboard');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
        await navigateClientSide(page, '/budgets');

        await page.screenshot({ path: 'test-results/budgets-list.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
        expect(page.url()).toContain('/budgets');
    });
});
