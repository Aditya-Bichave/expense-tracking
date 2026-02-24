const fs = require("fs");
const path = require("path");

const ARTIFACTS_DIR = process.env.ARTIFACTS_DIR || ".";

function getCoverage() {
  const lcovPath = path.join(ARTIFACTS_DIR, "coverage", "lcov.info");
  if (!fs.existsSync(lcovPath)) return { pct: 0, display: "N/A", status: "⚪️" };

  try {
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
  } catch (e) {
    return { pct: 0, display: "Error", status: "❌" };
  }
}

function getBundleSize() {
  const reportPath = path.join(ARTIFACTS_DIR, "bundle-size", "bundle-size-report.json");
  if (!fs.existsSync(reportPath)) return { main: "N/A", gzip: "N/A", passed: false, status: "⚪️", details: [] };

  try {
    const data = JSON.parse(fs.readFileSync(reportPath, "utf8"));
    return {
      main: `${data.mainJsKb.toFixed(2)} KB`,
      gzip: `${data.gzipMainJsKb.toFixed(2)} KB`,
      passed: data.passed,
      status: data.passed ? "✅" : "❌",
      details: data.messages || []
    };
  } catch (e) {
    return { main: "Error", gzip: "Error", passed: false, status: "❌", details: ["Failed to parse bundle report"] };
  }
}

function getSmokeTest() {
  const reportPath = path.join(ARTIFACTS_DIR, "smoke-test", "smoke-report.json");
  if (!fs.existsSync(reportPath)) return { startup: "N/A", passed: false, status: "⚪️", consoleErrors: [], pageErrors: [], failedRoutes: [] };

  try {
    const data = JSON.parse(fs.readFileSync(reportPath, "utf8"));

    // Performance Budget Check
    const MAX_STARTUP_MS = 20000;
    const startupOk = data.startupTimeMs <= MAX_STARTUP_MS;
    const startupStatus = startupOk ? "✅" : "⚠️";

    return {
      startup: `${data.startupTimeMs}ms`,
      startupStatus: startupStatus,
      passed: data.passed,
      status: data.passed ? "✅" : "❌",
      consoleErrors: data.consoleErrors || [],
      pageErrors: data.pageErrors || [],
      failedRoutes: data.failedRoutes || []
    };
  } catch (e) {
    return { startup: "Error", passed: false, status: "❌", consoleErrors: ["Failed to parse smoke report"], pageErrors: [], failedRoutes: [] };
  }
}

const coverage = getCoverage();
const bundle = getBundleSize();
const smoke = getSmokeTest();

const runUrl = process.env.GITHUB_RUN_ID ? `https://github.com/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID}` : "#";

// Prepare Smoke Failure Details
let smokeFailures = "";
if (!smoke.passed) {
  if (smoke.consoleErrors.length > 0) {
    smokeFailures += `\n**🚨 Console Errors (${smoke.consoleErrors.length})**:\n` + smoke.consoleErrors.slice(0, 5).map(e => `- \`${e.replace(/`/g, '')}\``).join("\n");
    if (smoke.consoleErrors.length > 5) smokeFailures += `\n- ... and ${smoke.consoleErrors.length - 5} more`;
  }
  if (smoke.pageErrors.length > 0) {
    smokeFailures += `\n**🚨 Page Errors (${smoke.pageErrors.length})**:\n` + smoke.pageErrors.slice(0, 5).map(e => `- \`${e.replace(/`/g, '')}\``).join("\n");
  }
  if (smoke.failedRoutes.length > 0) {
    smokeFailures += `\n**❌ Failed Routes**:\n` + smoke.failedRoutes.map(r => `- ${r}`).join("\n");
  }
}

const body = `
## 🚀 CI Quality Report

> **Build Status**: ${(coverage.status === "✅" && bundle.passed && smoke.passed) ? "Passing 🟢" : "Issues Found 🔴"}
> [View Full Logs](${runUrl})

| Category | Metric | Result | Status |
| :--- | :--- | :--- | :---: |
| **Testing** | Unit Coverage | **${coverage.display}** | ${coverage.status} |
| **Performance** | Bundle Size (Main) | **${bundle.main}** | ${bundle.status} |
| | Bundle Size (Gzip) | **${bundle.gzip}** | ${bundle.status} |
| **UX & Stability** | Startup Time | **${smoke.startup}** | ${smoke.startupStatus} |
| | Smoke Status | **${smoke.passed ? "Pass" : "Fail"}** | ${smoke.status} |

<details>
<summary><strong>🔍 Detailed Insights</strong></summary>

### 📦 Bundle Analysis
- **Main JS**: ${bundle.main}
- **Gzip**: ${bundle.gzip}
${bundle.details.length > 0 ? `> ⚠️ **Warnings**:\n${bundle.details.map(d => `- ${d}`).join("\n")}` : ""}

### 💨 Smoke Tests
- **Startup**: ${smoke.startup}
- **Routes Checked**: ${smoke.passed ? "All Passed" : "Failures Detected"}
${smokeFailures}

</details>

---
*Updated at ${new Date().toISOString()}*
<!-- ci-summary-bot -->
`;

console.log(body);
