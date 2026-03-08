// @ts-check
require('dotenv').config({ path: __dirname + '/.env' });

const { defineConfig, devices } = require('@playwright/test');

const BASE_URL = process.env.APP_BASE_URL || 'http://localhost:8080';
const PORT = 8080;

module.exports = defineConfig({
    testDir: './tests',
    fullyParallel: true,       // Run tests in parallel but bounded by workers
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    // Limit workers on CI to prevent CPU/Memory starvation which causes Flutter web initialization to timeout
    workers: process.env.CI ? 1 : undefined,
    timeout: 60_000,            // 60s per test to allow Flutter engine to boot safely under load

    reporter: [
        ['list'],
        ['./helpers/coverageReporter.js', { outputFile: './test-results/e2e-coverage.json' }],
        ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ],

    use: {
        baseURL: BASE_URL,

        // All tests start from a pre-authenticated session (set by globalSetup)
        storageState: './storage/auth-state.json',

        screenshot: 'only-on-failure',
        video: 'on-first-retry',
        trace: 'retain-on-failure'
    },

    globalSetup: './global-setup.js',

    webServer: {
        command: `node helpers/server.js ../../build/web ${PORT}`,
        port: PORT,
        reuseExistingServer: !process.env.CI,
        timeout: 120 * 1000
    },

    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] }
    }
    ],

    outputDir: './test-results'
});
