const fs = require('fs');
const path = require('path');

const COVERAGE_FILE = process.argv[2] || 'ci/e2e/test-results/e2e-coverage.json';

// Expected critical flows for FinancialOS
const EXPECTED_FLOWS = [
    'auth',
    'dashboard',
    'transactions',
    'budget',
    'reports',
    'groups'
];

if (!fs.existsSync(COVERAGE_FILE)) {
    console.error(`Coverage file not found: ${COVERAGE_FILE}`);
    process.exit(1);
}

const data = JSON.parse(fs.readFileSync(COVERAGE_FILE, 'utf8'));

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

**Test Summary:** ${data.passedTests} passed, ${data.failedTests} failed.
`;

fs.writeFileSync('e2e_coverage_summary.md', markdown.trim());
console.log(`E2E Coverage Analysis complete. Coverage: ${coveragePct}%`);
