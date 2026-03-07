// @ts-check
const { test, expect } = require('@playwright/test');

const FLUTTER_READY_TIMEOUT = 30_000;

const IGNORABLE_ERRORS = [
    'ERR_NAME_NOT_RESOLVED',
    'ERR_CONNECTION_REFUSED',
    'back/forward cache',
];

const filterFatalErrors = (errors) => {
    return errors.filter(e => !IGNORABLE_ERRORS.some(ignored => e.includes(ignored)));
};

test.describe('Groups @flow:groups', () => {
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

    test('groups list page loads without errors', async ({ page }) => {
        await page.goto('/groups');
        await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });

        await page.screenshot({ path: 'test-results/groups-list.png', fullPage: true });

        const fatal = filterFatalErrors(pageErrors);
        expect(fatal).toHaveLength(0);
        expect(page.url()).toContain('/groups');
    });
});
