// @ts-check
require('dotenv').config({ path: __dirname + '/.env' });

const { defineConfig, devices } = require('@playwright/test');

const BASE_URL = process.env.APP_BASE_URL || 'http://localhost:8080';
const PORT = 8080;

module.exports = defineConfig({
    testDir: './tests',
    fullyParallel: true,       // Flutter canvas tests are sequential-friendly
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 4 : undefined,                 // Single worker — Flutter web is heavy
    timeout: 30_000,            // 45s per test (Reduced from 90s)

    reporter: [
        ['list'],
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
