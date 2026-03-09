// @ts-check

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

/**
 * Perform client-side navigation within Flutter Web to avoid deep-link boot crashes.
 * Uses Hash routing by default as `usePathUrlStrategy` is not enabled in main.dart.
 * @param {import('@playwright/test').Page} page
 * @param {string} path
 */
async function navigateClientSide(page, path) {
    await page.evaluate(() => { window.E2E_FLUTTER_READY = false; });
    await page.evaluate((r) => {
        // Flutter web defaults to hash routing
        window.location.hash = r.startsWith('/') ? r : '/' + r;
    }, path);
    await page.waitForURL(`**/*#${path}*`, { timeout: 15000 });
    await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, { timeout: FLUTTER_READY_TIMEOUT });
    await page.waitForTimeout(FLUTTER_RENDER_WAIT);
}

module.exports = {
    setupErrorCollector,
    navigateClientSide,
    filterFatalErrors,
    IGNORABLE_ERRORS,
    FLUTTER_READY_TIMEOUT,
    FLUTTER_RENDER_WAIT
};
