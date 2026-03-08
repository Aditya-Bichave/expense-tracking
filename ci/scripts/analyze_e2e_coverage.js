const fs = require('fs');
const path = require('path');
const EXPECTED_FLOWS = require('./shared/expectedFlows');

const COVERAGE_FILE = process.argv[2] || 'ci/e2e/test-results/e2e-coverage.json';
const OUTPUT_FILE = process.argv[3] || path.join(path.dirname(COVERAGE_FILE), 'e2e_coverage_summary.md');

let data;
try {
    data = JSON.parse(fs.readFileSync(COVERAGE_FILE, 'utf8'));
} catch (e) {
    console.error(`Failed to read or parse coverage file at ${COVERAGE_FILE}:`, e);
    process.exit(1);
}

let coveredFlows = 0;
const flowDetails = [];

const flows = data?.flows || {};

EXPECTED_FLOWS.forEach(flow => {
    const flowData = flows[flow];
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

**Test Summary:** ${data.passedTests || 0} passed, ${data.failedTests || 0} failed, ${data.skippedTests || 0} skipped.
`;

const resolvedOutputPath = path.resolve(OUTPUT_FILE);
try {
    fs.writeFileSync(resolvedOutputPath, markdown.trim());
    console.log(`E2E Coverage Analysis complete. Coverage: ${coveragePct}%`);
} catch (e) {
    console.error(`Failed to write markdown summary to ${resolvedOutputPath}:`, e);
    process.exit(1);
}
