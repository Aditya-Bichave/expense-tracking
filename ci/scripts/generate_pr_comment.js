const fs = require("fs");
const path = require("path");

const ARTIFACTS_DIR = process.env.ARTIFACTS_DIR || ".";

function getCoverage() {
  const lcovPath = path.join(ARTIFACTS_DIR, "coverage", "lcov.info");
  if (!fs.existsSync(lcovPath)) return { pct: 0, display: "N/A", status: "⚪️" };

  const content = fs.readFileSync(lcovPath, "utf8");
  let lf = 0, lh = 0;
  content.split("\n").forEach(line => {
    if (line.startsWith("LF:")) lf += parseInt(line.split(":")[1]);
    if (line.startsWith("LH:")) lh += parseInt(line.split(":")[1]);
  });

  const pct = lf ? (lh / lf) * 100 : 0;
  return {
    pct,
    display: `${pct.toFixed(2)}%`,
    status: pct >= 35 ? "✅" : "⚠️"
  };
}

function getBundleSize() {
  const reportPath = path.join(ARTIFACTS_DIR, "bundle-size", "bundle-size-report.json");
  if (!fs.existsSync(reportPath)) return { main: "N/A", gzip: "N/A", passed: false, status: "⚪️", details: [] };
  const data = JSON.parse(fs.readFileSync(reportPath, "utf8"));
  return {
    main: `${data.mainJsKb.toFixed(2)} KB`,
    gzip: `${data.gzipMainJsKb.toFixed(2)} KB`,
    passed: data.passed,
    status: data.passed ? "✅" : "❌",
    details: data.messages || []
  };
}

function getSmokeTest() {
  const reportPath = path.join(ARTIFACTS_DIR, "smoke-test", "smoke-report.json");
  if (!fs.existsSync(reportPath)) return { startup: "N/A", passed: false, status: "⚪️", consoleErrors: [], pageErrors: [], failedRoutes: [] };
  const data = JSON.parse(fs.readFileSync(reportPath, "utf8"));
  return {
    startup: `${data.startupTimeMs}ms`,
    passed: data.passed,
    status: data.passed ? "✅" : "❌",
    consoleErrors: data.consoleErrors || [],
    pageErrors: data.pageErrors || [],
    failedRoutes: data.failedRoutes || []
  };
}

const coverage = getCoverage();
const bundle = getBundleSize();
const smoke = getSmokeTest();

const runUrl = process.env.GITHUB_RUN_ID ? `https://github.com/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID}` : "#";

const body = `
## 🚀 CI Quality Report

> **Build Status**: ${(coverage.status === "✅" && bundle.passed && smoke.passed) ? "Passing 🟢" : "Issues Found 🔴"}
> [View Full Logs](${runUrl})

| Category | Metric | Result | Status |
| :--- | :--- | :--- | :---: |
| **Testing** | Unit Coverage | **${coverage.display}** | ${coverage.status} |
| **Performance** | Bundle Size (Main) | **${bundle.main}** | ${bundle.status} |
| | Bundle Size (Gzip) | **${bundle.gzip}** | ${bundle.status} |
| **UX & Stability** | Startup Time | **${smoke.startup}** | ${smoke.status} |

<details>
<summary><strong>🔍 Detailed Insights</strong></summary>

### 📦 Bundle Analysis
- **Main JS**: ${bundle.main}
- **Gzip**: ${bundle.gzip}
${bundle.details.length > 0 ? `> ⚠️ **Warnings**:\n${bundle.details.map(d => `- ${d}`).join("\n")}` : ""}

### 💨 Smoke Tests
- **Startup**: ${smoke.startup}
- **Routes Checked**: ${smoke.passed ? "All Passed" : "Failures Detected"}
${smoke.consoleErrors.length > 0 ? `> 🚨 **Console Errors**:\n` + smoke.consoleErrors.map(e => `- ` + e).join("\n") : ""}
${smoke.pageErrors.length > 0 ? `> 🚨 **Page Errors**:\n` + smoke.pageErrors.map(e => `- ` + e).join("\n") : ""}
${smoke.failedRoutes.length > 0 ? `> ❌ **Failed Routes**:\n` + smoke.failedRoutes.map(r => `- ` + r).join("\n") : ""}

</details>

---
*Updated at ${new Date().toISOString()}*
<!-- ci-summary-bot -->
`;

console.log(body);