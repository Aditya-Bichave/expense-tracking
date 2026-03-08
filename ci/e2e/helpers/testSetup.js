// @ts-check

/**
 * Sets up global page error and console logging for tests.
 * @param {import('@playwright/test').Page} page
 * @param {string[]} pageErrors
 */
function setupErrorCollector(page, pageErrors) {
    page.on('console', msg => {
        console.log(`[BROWSER LOG] ${msg.text()}`);
    });
    page.on('pageerror', err => {
        console.log(`[BROWSER FATAL] ${err.message}`);
        pageErrors.push(err.message);
    });
}

module.exports = { setupErrorCollector };
