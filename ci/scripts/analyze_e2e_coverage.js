const fs = require('fs');
const path = require('path');

const COVERAGE_FILE = process.argv[2] || 'ci/e2e/test-results/e2e-coverage.json';
const OUTPUT_FILE = process.argv[3] || path.join(path.dirname(COVERAGE_FILE), 'e2e_coverage_summary.md');

// The EXPECTED_FLOWS array must be kept in sync with the @flow:xxx tags used in test files.
// If a new test flow is introduced, it must be added to this list for proper coverage tracking.
// TODO: Consider extracting this to a shared config if it grows larger.
const EXPECTED_FLOWS = [
    'auth',
    'dashboard',
    'transactions',
    'budget',
    'reports',
    'groups'
];

let data;
try {
    data = JSON.parse(fs.readFileSync(COVERAGE_FILE, 'utf8'));
} catch (e) {
    console.error(`Failed to read or parse coverage file at ${COVERAGE_FILE}:`, e);
    process.exit(1);
}

let coveredFlows = 0;
const flowDetails = [];

EXPECTED_FLOWS.forEach(flow => {
    const flowData = data.flows[flow];
    if (flowData && flowData.total > 0) {
        coveredFlows++;
        const status = flowData.passed === flowData.total ? '✅' : '⚠️';
        flowDetails.push(`| ${flow} | ${status} | ${flowData.passed}/${flowData.total} |`);
    } else {
        flowDetails.push(`| ${flow} | ❌ | 0/0 |`);
    }
});

const coveragePct = Math.round((coveredFlows / EXPECTED_FLOWS.length) * 100);

const markdown = `
### 🎭 E2E Flow Coverage: ${coveragePct}% (${coveredFlows}/${EXPECTED_FLOWS.length} flows)

| Flow | Status | Tests Passed |
| --- | --- | --- |
${flowDetails.join('\n')}

**Test Summary:** ${data.passedTests} passed, ${data.failedTests} failed, ${data.skippedTests || 0} skipped.
`;

const resolvedOutputPath = path.resolve(OUTPUT_FILE);
try {
    fs.writeFileSync(resolvedOutputPath, markdown.trim());
    console.log(`E2E Coverage Analysis complete. Coverage: ${coveragePct}%`);
} catch (e) {
    console.error(`Failed to write markdown summary to ${resolvedOutputPath}:`, e);
    process.exit(1);
}
