// @ts-check
require('dotenv').config({ path: __dirname + '/.env' });

const { defineConfig, devices } = require('@playwright/test');

const BASE_URL = process.env.APP_BASE_URL || 'http://localhost:8080';

module.exports = defineConfig({
    testDir: './tests',
    fullyParallel: false,       // Flutter canvas tests are sequential-friendly
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 1 : 0,
    workers: 1,                 // Single worker — Flutter web is heavy
    timeout: 90_000,            // 90s per test (Flutter web loads slowly)

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
        trace: 'retain-on-failure',
        // Capture browser console logs
        launchOptions: {
            logger: {
                isEnabled: (name, severity) => true,
                log: (name, severity, message, args) => console.log(`${name} [${severity}] ${message}`)
            }
        }
    },

    globalSetup: './global-setup.js',

    webServer: {
        command: 'node helpers/server.js ../../build/web 8080',
        port: 8080,
        reuseExistingServer: !process.env.CI,
        timeout: 120 * 1000,
    },

    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
    ],

    outputDir: './test-results',
});
