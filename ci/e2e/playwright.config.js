// @ts-check
require('dotenv').config({ path: __dirname + '/.env' });

const { defineConfig, devices } = require('@playwright/test');

const BASE_URL = process.env.APP_BASE_URL || 'http://localhost:8080';
const BUILD_DIR = process.env.BUILD_DIR || '../../build/web';
const PORT = 8080;

module.exports = defineConfig({
    testDir: './tests',
    fullyParallel: false,
    forbidOnly: !!process.env.CI,
    retries: 0,
    workers: 1,
    timeout: 60_000,

    reporter: [
        ['list'],
        ['./helpers/coverageReporter.js', { outputFile: './test-results/e2e-coverage.json' }],
        ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ],

    use: {
        baseURL: BASE_URL,
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
        trace: 'retain-on-failure'
    },

    webServer: {
        command: `node helpers/server.js ${BUILD_DIR} ${PORT}`,
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
