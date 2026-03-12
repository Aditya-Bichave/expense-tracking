// @ts-check
const { test, expect } = require('@playwright/test');
const {
    setupErrorCollector,
    gotoFlutterRoute,
    navigateClientSide,
    filterFatalErrors,
} = require('../helpers/testSetup');

test.describe('Budgets @flow:budget', () => {
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
    });

    test('budgets list page loads without errors', async ({ page }) => {
        await gotoFlutterRoute(page, '/dashboard');
        await navigateClientSide(page, '/plan');

        await page.screenshot({ path: 'test-results/budgets-list.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
        expect(page.url()).toContain('/plan');
    });
});
