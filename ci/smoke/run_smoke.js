const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

// --- Configuration ---
const BUILD_DIR = path.resolve(__dirname, '../../build/web');
const PORT = 8080;
const TIMEOUT = 60000;
const MAX_STARTUP_TIME_MS = 45000;
const ARTIFACTS_DIR = path.join(__dirname, 'artifacts');
const REPORT_FILE = path.join(__dirname, 'smoke-report.json');
const ROUTES_FILE = path.join(__dirname, 'routes.json');
const RETRIES = 1;
const BASE_URL = `http://localhost:${PORT}`;

// --- Load Routes ---
let ROUTES = [];
try {
  if (fs.existsSync(ROUTES_FILE)) {
    ROUTES = JSON.parse(fs.readFileSync(ROUTES_FILE, 'utf8'));
  } else {
    console.error(`Routes file not found at ${ROUTES_FILE}. Run extract_routes.js first.`);
    process.exit(1);
  }
} catch (e) {
  console.error('Failed to parse routes.json:', e);
  process.exit(1);
}

// --- Helper Functions ---
function ensureArtifactsDir() {
  if (!fs.existsSync(ARTIFACTS_DIR)) {
    fs.mkdirSync(ARTIFACTS_DIR, { recursive: true });
  }
}

async function takeScreenshot(page, name) {
  const filename = path.join(ARTIFACTS_DIR, `${name.replace(/[\/\:]/g, '_')}.png`);
  try {
    await page.screenshot({ path: filename, fullPage: true });
    return filename;
  } catch (e) {
    console.error(`Failed to take screenshot for ${name}: ${e.message}`);
    return null;
  }
}

async function saveTrace(context, name) {
  const filename = path.join(ARTIFACTS_DIR, `${name.replace(/[\/\:]/g, '_')}_trace.zip`);
  try {
    await context.tracing.stop({ path: filename });
    return filename;
  } catch (e) {
    console.error(`Failed to save trace for ${name}: ${e.message}`);
    return null;
  }
}

async function waitForFlutterReady(page) {
  await page.waitForFunction(() => window.E2E_FLUTTER_READY === true, {
    timeout: TIMEOUT
  });
  await page.locator('canvas, flt-semantics-host').first().waitFor({
    state: 'attached',
    timeout: TIMEOUT
  });
}

async function gotoFlutterRoute(page, route) {
  await page.goto(`${BASE_URL}/#${route}`, {
    waitUntil: 'domcontentloaded',
    timeout: TIMEOUT
  });
  await waitForFlutterReady(page);
}

async function navigateFlutterRoute(page, route) {
  await page.evaluate(targetRoute => {
    window.E2E_FLUTTER_READY = false;
    window.location.hash = targetRoute.startsWith('/') ? targetRoute : `/${targetRoute}`;
  }, route);
  await waitForFlutterReady(page);
}

async function enableAccessibilitySemantics(page) {
  const activation = await page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    if (host && host.querySelectorAll('flt-semantics').length > 0) {
      return { placeholderFound: true, semanticsAlreadyEnabled: true };
    }

    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (!placeholder) {
      return { placeholderFound: false };
    }

    placeholder.focus();
    placeholder.dispatchEvent(
      new MouseEvent('mousedown', { bubbles: true, cancelable: true })
    );
    placeholder.dispatchEvent(
      new MouseEvent('mouseup', { bubbles: true, cancelable: true })
    );
    placeholder.dispatchEvent(
      new MouseEvent('click', { bubbles: true, cancelable: true })
    );
    placeholder.dispatchEvent(
      new KeyboardEvent('keydown', {
        key: 'Enter',
        code: 'Enter',
        bubbles: true,
        cancelable: true
      })
    );
    placeholder.dispatchEvent(
      new KeyboardEvent('keyup', {
        key: 'Enter',
        code: 'Enter',
        bubbles: true,
        cancelable: true
      })
    );

    return { placeholderFound: true, semanticsAlreadyEnabled: false };
  });

  if (!activation.placeholderFound) {
    return false;
  }

  try {
    await page.waitForFunction(() => {
      const host = document.querySelector('flt-semantics-host');
      return !!host && host.querySelectorAll('flt-semantics').length > 0;
    }, {
      timeout: 10000
    });
    return true;
  } catch (e) {
    console.warn(`  Accessibility semantics did not become available: ${e.message}`);
    return false;
  }
}

// --- Custom Static Server with /log support ---
const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/log') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true }));
    return;
  }

  let filePath = path.join(BUILD_DIR, req.url === '/' ? 'index.html' : req.url);
  filePath = filePath.split('?')[0];

  if (!filePath.startsWith(BUILD_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      if (path.extname(filePath) === '') {
        const index = path.join(BUILD_DIR, 'index.html');
        fs.readFile(index, (readErr, data) => {
          if (readErr) {
            res.writeHead(404);
            res.end('Not Found');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(data);
          }
        });
      } else {
        res.writeHead(404);
        res.end('Not Found');
      }
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    let contentType = 'application/octet-stream';
    const mimeTypes = {
      '.html': 'text/html',
      '.js': 'application/javascript',
      '.css': 'text/css',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml',
      '.ico': 'image/x-icon',
      '.woff': 'application/font-woff',
      '.woff2': 'application/font-woff2',
      '.ttf': 'application/font-ttf',
      '.wasm': 'application/wasm',
      '.xml': 'application/xml',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.map': 'application/json'
    };

    if (mimeTypes[ext]) {
      contentType = mimeTypes[ext];
    }

    fs.readFile(filePath, (readErr, data) => {
      if (readErr) {
        res.writeHead(500);
        res.end('Server Error');
        return;
      }
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(data);
    });
  });
});

// --- Main Execution ---
async function run() {
  console.log('Starting smoke tests...');
  ensureArtifactsDir();

  server.listen(PORT);
  console.log(`Server started on ${BASE_URL}`);

  let browser;
  let context;
  let page;

  const results = {
    startupTimeMs: 0,
    passed: true,
    routes: [],
    consoleErrors: [],
    pageErrors: [],
    failedRoutes: []
  };

  try {
    browser = await chromium.launch();
    context = await browser.newContext();
    await context.tracing.start({ screenshots: true, snapshots: true });

    page = await context.newPage();

    page.on('console', msg => {
      if (msg.type() === 'error') {
        const text = msg.text();
        console.error(`  Console error: ${text}`);
        if (!text.includes('status of 405') &&
          !text.includes('ERR_NAME_NOT_RESOLVED') &&
          !text.includes('ERR_CONNECTION_REFUSED')) {
          results.consoleErrors.push(text);
        }
      }
    });

    page.on('pageerror', err => {
      const text = err.toString();
      console.error(`  Page error: ${text}`);
      results.pageErrors.push(text);
    });

    console.log('Measuring startup time...');
    const startTime = Date.now();
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: TIMEOUT });
    await waitForFlutterReady(page);

    if (results.pageErrors.length > 0) {
      console.error('Critical page errors detected immediately after navigation.');
      await takeScreenshot(page, 'startup_critical_failure');
      results.passed = false;
      throw new Error(`Critical page errors during startup: ${results.pageErrors.join(', ')}`);
    }

    const startupTime = Date.now() - startTime;
    console.log(`Startup time: ${startupTime}ms`);
    results.startupTimeMs = startupTime;

    if (startupTime > MAX_STARTUP_TIME_MS) {
      console.error(`Startup time exceeded budget of ${MAX_STARTUP_TIME_MS}ms`);
    }

    console.log('Seeding deterministic E2E session...');
    try {
      await gotoFlutterRoute(page, '/e2e-bypass');
      await page.waitForURL(`${BASE_URL}/#/dashboard`, { timeout: TIMEOUT });
      console.log('  Navigated to dashboard.');
    } catch (e) {
      console.error(`Failed to bypass setup: ${e.message}`);
      await takeScreenshot(page, 'setup_bypass_failure');
    }

    console.log('Enabling accessibility semantics...');
    if (await enableAccessibilitySemantics(page)) {
      console.log('  Accessibility semantics enabled.');
    } else {
      console.log('  Accessibility semantics unavailable.');
    }

    console.log(`Testing ${ROUTES.length} routes...`);
    for (const route of ROUTES) {
      if (route.includes(':')) continue;

      console.log(`  Checking ${route}...`);
      const routeResult = {
        path: route,
        passed: false,
        error: null,
        screenshot: null
      };

      for (let attempt = 1; attempt <= RETRIES + 1; attempt++) {
        try {
          await navigateFlutterRoute(page, route);
          routeResult.passed = true;
          break;
        } catch (e) {
          console.error(`    Attempt ${attempt} failed: ${e.message}`);
          routeResult.error = e.message;
          if (attempt > RETRIES) {
            routeResult.screenshot = await takeScreenshot(page, `fail_${route}`);
            results.failedRoutes.push(route);
          }
        }
      }

      results.routes.push(routeResult);
    }

    console.log('Verifying Groups create flow and form validation...');
    const groupsCreateResult = {
      path: '/groups#create-flow-validation',
      passed: false,
      error: null,
      screenshot: null
    };

    try {
      await gotoFlutterRoute(page, '/groups');
      const semanticsEnabled = await enableAccessibilitySemantics(page);
      if (!semanticsEnabled) {
        throw new Error('Flutter accessibility semantics did not enable for the Groups flow.');
      }

      const createOneButton = page.getByRole('button', { name: 'Create one' });
      await createOneButton.waitFor({ timeout: TIMEOUT });
      await createOneButton.focus();
      await page.keyboard.press('Enter');

      await page.waitForFunction(() => window.location.hash === '#/groups/create', {
        timeout: TIMEOUT
      });
      await waitForFlutterReady(page);

      await page.getByRole('heading', { name: 'Create New Group' }).waitFor({
        timeout: TIMEOUT
      });
      const submitButton = page.getByRole('button', { name: 'Create Group' });
      await submitButton.focus();
      await page.keyboard.press('Enter');
      await page.getByText('Please enter a name', { exact: true }).first().waitFor({
        timeout: TIMEOUT
      });

      groupsCreateResult.passed = true;
    } catch (e) {
      console.error(`  Groups validation check failed: ${e.message}`);
      groupsCreateResult.error = e.message;
      groupsCreateResult.screenshot = await takeScreenshot(
        page,
        'fail_groups_create_validation'
      );
      results.failedRoutes.push(groupsCreateResult.path);
    }

    results.routes.push(groupsCreateResult);

    if (results.failedRoutes.length > 0) results.passed = false;
    if (results.consoleErrors.length > 0) results.passed = false;
    if (results.pageErrors.length > 0) results.passed = false;

    if (!results.passed) {
      await saveTrace(context, 'smoke_test_failure');
    }

    fs.writeFileSync(REPORT_FILE, JSON.stringify(results, null, 2));
    console.log(`Report saved to ${REPORT_FILE}`);

    if (results.passed) {
      console.log('Smoke tests passed.');
      process.exit(0);
    } else {
      console.error('Smoke tests failed.');
      process.exit(1);
    }
  } catch (err) {
    console.error('Fatal error:', err);
    process.exit(1);
  } finally {
    if (browser) await browser.close();
    server.close();
  }
}

run();
