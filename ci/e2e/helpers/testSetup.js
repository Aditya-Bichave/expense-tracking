// @ts-check

const FLUTTER_READY_TIMEOUT = 30_000;

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

function normalizeRoute(path) {
    if (!path || path === '/') {
        return '/';
    }

    return path.startsWith('/') ? path : `/${path}`;
}

/**
 * Wait for the Flutter app to signal readiness and attach its render host.
 * @param {import('@playwright/test').Page} page
 */
async function waitForFlutterReady(page) {
    await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, {
        timeout: FLUTTER_READY_TIMEOUT,
    });
    await page.locator('canvas, flt-semantics-host').first().waitFor({
        state: 'attached',
        timeout: FLUTTER_READY_TIMEOUT,
    });
}

/**
 * Navigate to a Flutter hash route and wait for the app to finish rendering it.
 * @param {import('@playwright/test').Page} page
 * @param {string} path
 */
async function gotoFlutterRoute(page, path) {
    const normalizedRoute = normalizeRoute(path);
    await page.goto(`/#${normalizedRoute}`, {
        waitUntil: 'domcontentloaded',
        timeout: FLUTTER_READY_TIMEOUT,
    });
    await waitForFlutterReady(page);
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
    await waitForFlutterReady(page);
}

module.exports = {
    setupErrorCollector,
    waitForFlutterReady,
    gotoFlutterRoute,
    navigateClientSide,
    filterFatalErrors,
    IGNORABLE_ERRORS,
    FLUTTER_READY_TIMEOUT
};
