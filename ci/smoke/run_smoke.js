const { chromium } = require('playwright');
const httpServer = require('http-server');
const fs = require('fs');
const path = require('path');

const ROUTES = JSON.parse(fs.readFileSync('routes.json', 'utf8'));
const BUILD_DIR = '../../build/web';
const PORT = 8080;
const TIMEOUT = 60000; // Increased timeout for CI (Wasm/CanvasKit can be slow)
const REPORT_FILE = 'smoke-report.json';
const MAX_STARTUP_TIME_MS = 60000; // Increased budget for CI

async function run() {
  const server = httpServer.createServer({ root: BUILD_DIR });
  server.listen(PORT);
  console.log(`Server started on port ${PORT}`);

  let browser;
  try {
    browser = await chromium.launch();
    const page = await browser.newPage();

    // Console error monitoring
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    const pageErrors = [];
    page.on('pageerror', err => {
      // Capture all errors
      pageErrors.push(err.toString());
    });

    // 1. Startup Time Check
    console.log('Checking startup time...');
    const startTime = Date.now();
    await page.goto(`http://localhost:${PORT}`, { waitUntil: 'networkidle' });

    // Wait for Flutter engine to initialize
    // flt-glass-pane is standard for HTML renderer, canvas is used in CanvasKit/Wasm
    try {
      await page.waitForSelector('flt-glass-pane, canvas', { timeout: TIMEOUT });
    } catch (e) {
      console.error('No flt-glass-pane or canvas found. Startup likely failed.');
      throw e;
    }

    const startupTime = Date.now() - startTime;
    console.log(`Startup time: ${startupTime}ms`);

    // 2. Route Checks
    const failedRoutes = [];
    for (const route of ROUTES) {
      console.log(`Checking route: ${route}`);
      try {
        await page.goto(`http://localhost:${PORT}#${route}`, { waitUntil: 'networkidle' });
        const title = await page.title();
        console.log(`  Title: ${title}`);
      } catch (e) {
        console.error(`  Failed to load route ${route}: ${e.message}`);
        failedRoutes.push(route);
      }
    }

    const passed = consoleErrors.length === 0 && pageErrors.length === 0 && failedRoutes.length === 0 && startupTime < MAX_STARTUP_TIME_MS;

    const report = {
      startupTimeMs: startupTime,
      consoleErrors,
      pageErrors,
      failedRoutes,
      passed
    };

    fs.writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2));

    if (!passed) {
      console.error('❌ Smoke tests failed.');
      if (startupTime >= MAX_STARTUP_TIME_MS) console.error(`Startup time exceeded budget: ${startupTime}ms`);
      if (consoleErrors.length > 0) console.error('Console Errors:', consoleErrors);
      if (pageErrors.length > 0) console.error('Page Errors:', pageErrors);
      if (failedRoutes.length > 0) console.error('Failed Routes:', failedRoutes);
      process.exit(1);
    } else {
      console.log('✅ Smoke tests passed.');
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