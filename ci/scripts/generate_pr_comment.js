const fs = require('fs');
const path = require('path');

const ARTIFACTS_DIR = process.env.ARTIFACTS_DIR || '.';

function getCoverage() {
  const lcovPath = path.join(ARTIFACTS_DIR, 'coverage', 'lcov.info');
  if (!fs.existsSync(lcovPath)) return 'N/A';

  const content = fs.readFileSync(lcovPath, 'utf8');
  let lf = 0, lh = 0;
  content.split('\n').forEach(line => {
    if (line.startsWith('LF:')) lf += parseInt(line.split(':')[1]);
    if (line.startsWith('LH:')) lh += parseInt(line.split(':')[1]);
  });

  return lf ? ((lh / lf) * 100).toFixed(2) + '%' : '0%';
}

function getBundleSize() {
  const reportPath = path.join(ARTIFACTS_DIR, 'bundle-size', 'bundle-size-report.json');
  if (!fs.existsSync(reportPath)) return { main: 'N/A', gzip: 'N/A', passed: false };
  const data = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  return {
    main: `${data.mainJsKb.toFixed(2)} KB`,
    gzip: `${data.gzipMainJsKb.toFixed(2)} KB`,
    passed: data.passed
  };
}

function getSmokeTest() {
  const reportPath = path.join(ARTIFACTS_DIR, 'smoke-test', 'smoke-report.json');
  if (!fs.existsSync(reportPath)) return { startup: 'N/A', passed: false };
  const data = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  return {
    startup: `${data.startupTimeMs}ms`,
    passed: data.passed
  };
}

const coverage = getCoverage();
const bundle = getBundleSize();
const smoke = getSmokeTest();

const body = `
## 🛡️ CI Quality Gate Report

| Metric | Result | Status |
| :--- | :--- | :--- |
| **Test Coverage** | ${coverage} | ${parseFloat(coverage) >= 35 ? '✅' : '⚠️'} |
| **Bundle Size (Main)** | ${bundle.main} | ${bundle.passed ? '✅' : '❌'} |
| **Bundle Size (Gzip)** | ${bundle.gzip} | ${bundle.passed ? '✅' : '❌'} |
| **Startup Time** | ${smoke.startup} | ${smoke.passed ? '✅' : '❌'} |

<!-- ci-summary-bot -->
`;

console.log(body);
