const { chromium } = require('playwright');
const httpServer = require('http-server');
const fs = require('fs');
const path = require('path');

// --- Configuration ---
const BUILD_DIR = path.resolve(__dirname, '../../build/web');
const PORT = 8080;
const TIMEOUT = 30000; // 30s timeout per action
const MAX_STARTUP_TIME_MS = 20000; // 20s budget for initial load
const ARTIFACTS_DIR = path.join(__dirname, 'artifacts');
const REPORT_FILE = path.join(__dirname, 'smoke-report.json');
const ROUTES_FILE = path.join(__dirname, 'routes.json');
const RETRIES = 1;

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
  const filename = path.join(ARTIFACTS_DIR, `${name.replace(/[\/\\:]/g, '_')}.png`);
  try {
    await page.screenshot({ path: filename, fullPage: true });
    return filename;
  } catch (e) {
    console.error(`Failed to take screenshot for ${name}: ${e.message}`);
    return null;
  }
}

async function saveTrace(context, name) {
  const filename = path.join(ARTIFACTS_DIR, `${name.replace(/[\/\\:]/g, '_')}_trace.zip`);
  try {
    await context.tracing.stop({ path: filename });
    return filename;
  } catch (e) {
    console.error(`Failed to save trace for ${name}: ${e.message}`);
    return null;
  }
}

// --- Main Execution ---
async function run() {
  console.log('🚀 Starting Smoke Tests...');
  ensureArtifactsDir();

  // Start HTTP Server
  const server = httpServer.createServer({ root: BUILD_DIR });
  server.listen(PORT);
  console.log(`Server started on http://localhost:${PORT}`);

  let browser;
  let context;
  let page;

  // Results Container
  const results = {
    startupTimeMs: 0,
    passed: true, // Optimistic start
    routes: [],
    consoleErrors: [],
    pageErrors: [],
    failedRoutes: []
  };

  try {
    browser = await chromium.launch();
    context = await browser.newContext();

    // Start tracing
    await context.tracing.start({ screenshots: true, snapshots: true });

    page = await context.newPage();

    // 1. Monitor Errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        const text = msg.text();
        // Filter out known noisy errors if needed
        console.error(`  Console Error: ${text}`);
        results.consoleErrors.push(text);
      }
    });

    page.on('pageerror', err => {
      const text = err.toString();
      console.error(`  Page Error: ${text}`);
      results.pageErrors.push(text);
    });

    // 2. Measure Startup Time
    console.log('⏱️  Measuring startup time...');
    const startTime = Date.now();

    // Navigate to root (which should redirect to /setup)
    await page.goto(`http://localhost:${PORT}`, { waitUntil: 'networkidle' });

    // Wait for Flutter to render something (flt-glass-pane is standard for CanvasKit)
    try {
      await page.waitForSelector('flt-glass-pane', { timeout: TIMEOUT });
    } catch (e) {
      console.error('Failed to detect Flutter app startup (flt-glass-pane not found).');
      await takeScreenshot(page, 'startup_failure');
      results.passed = false;
      throw e;
    }

    const startupTime = Date.now() - startTime;
    console.log(`✅ Startup time: ${startupTime}ms`);
    results.startupTimeMs = startupTime;

    if (startupTime > MAX_STARTUP_TIME_MS) {
      console.error(`❌ Startup time exceeded budget of ${MAX_STARTUP_TIME_MS}ms`);
      results.passed = false;
    }

    // 3. Initial Setup Bypass
    console.log('🔓 Attempting to bypass Initial Setup...');
    try {
      // Check if we are on the setup page by looking for specific text/buttons
      // We look for "Skip for Now" button
      // Note: We use a short timeout because if it's not there, we assume we are already past it
      // or on a different route.
      const skipButton = page.getByRole('button', { name: 'Skip for Now' });

      if (await skipButton.isVisible({ timeout: 5000 })) {
        console.log('  Found Skip button. Clicking...');
        await skipButton.click();

        // Wait for navigation to Dashboard
        // We use a glob to match any dashboard URL (e.g. /dashboard or /#/dashboard)
        // Since we are using hash routing, the URL will contain #/dashboard
        await page.waitForURL('**/dashboard', { timeout: TIMEOUT });
        console.log('  Navigated to Dashboard.');
      } else {
        console.log('  Skip button not found. Assuming app is already initialized or redirected.');
      }
    } catch (e) {
      console.error('Failed to bypass setup:', e.message);
      await takeScreenshot(page, 'setup_bypass_failure');
      // We don't fail hard here, we let the route checks fail if they can't be reached
    }

    // 4. Test Routes
    console.log(`🌍 Testing ${ROUTES.length} routes...`);

    for (const route of ROUTES) {
      // Skip parameterized routes just in case they slipped through
      if (route.includes(':')) continue;

      console.log(`  Checking ${route}...`);

      let routeResult = {
        path: route,
        passed: false,
        error: null,
        screenshot: null
      };

      for (let attempt = 1; attempt <= RETRIES + 1; attempt++) {
        try {
          // Construct URL for Hash Routing
          const targetUrl = `http://localhost:${PORT}/#${route}`;

          await page.goto(targetUrl, { waitUntil: 'networkidle', timeout: TIMEOUT });

          // Verify we didn't land on an error page (if your app has one)
          // or verify we are not stuck on loading?
          // For now, successful navigation without throwing is a pass.

          routeResult.passed = true;
          break; // Success

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

    // 5. Finalize
    if (results.failedRoutes.length > 0) results.passed = false;
    if (results.consoleErrors.length > 0) results.passed = false;
    if (results.pageErrors.length > 0) results.passed = false;

    // Save Trace if failed
    if (!results.passed) {
        await saveTrace(context, 'smoke_test_failure');
    }

    fs.writeFileSync(REPORT_FILE, JSON.stringify(results, null, 2));
    console.log(`📝 Report saved to ${REPORT_FILE}`);

    if (results.passed) {
      console.log('✅ Smoke tests passed!');
      process.exit(0);
    } else {
      console.error('❌ Smoke tests failed.');
      process.exit(1);
    }

  } catch (err) {
    console.error('🔥 Fatal error:', err);
    process.exit(1);
  } finally {
    if (browser) await browser.close();
    server.close();
  }
}

run();
