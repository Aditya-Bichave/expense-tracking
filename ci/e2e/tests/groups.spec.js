// @ts-check
const { test, expect } = require('@playwright/test');
const {
    setupErrorCollector,
    gotoFlutterRoute,
    navigateClientSide,
    filterFatalErrors,
} = require('../helpers/testSetup');

test.describe('Groups @flow:groups', () => {
    let pageErrors = [];

    test.beforeEach(async ({ page }) => {
        pageErrors = [];
        setupErrorCollector(page, pageErrors);
    });

    test('groups list page loads without errors', async ({ page }) => {
        await gotoFlutterRoute(page, '/dashboard');
        await navigateClientSide(page, '/groups');

        await page.screenshot({ path: 'test-results/groups-list.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
        expect(page.url()).toContain('/groups');
    });
});
