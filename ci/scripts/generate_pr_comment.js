const fs = require('fs');
const execSync = require('child_process').execSync;
const path = require('path');
const EXPECTED_FLOWS = require('./shared/expectedFlows');

const HEAD_REF = process.env.GITHUB_HEAD_REF || "local";
const BASE_REF = process.env.GITHUB_BASE_REF || "main";

let RUN_URL = "local-run";
if (process.env.GITHUB_SERVER_URL && process.env.GITHUB_REPOSITORY && process.env.GITHUB_RUN_ID) {
    RUN_URL = `${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID}`;
}

const RUNNER_OS = process.env.RUNNER_OS || "Linux";
const ARTIFACTS_DIR = process.env.ARTIFACTS_DIR || "artifacts";

// --- HELPERS ---

function safeRead(filePath) {
  try { return fs.readFileSync(filePath, "utf8"); }
  catch (e) { return null; }
}

function safeJson(filePath) {
  try { return JSON.parse(fs.readFileSync(filePath, "utf8")); }
  catch (e) { return {}; }
}

function getVersion(cmd) {
  try {
    return execSync(cmd).toString().trim().split("\n")[0];
  } catch (e) {
    return "Unknown";
  }
}

function getGitImpact() {
  try {
    const stats = execSync(`git diff --shortstat origin/${BASE_REF}...HEAD`).toString().trim();
    const files = (stats.match(/(\d+) files? changed/) || [0, 0])[1];
    const adds = (stats.match(/(\d+) insertions?/) || [0, 0])[1];
    const dels = (stats.match(/(\d+) deletions?/) || [0, 0])[1];

    const testsOutput = execSync(`git diff --numstat origin/${BASE_REF}...HEAD`).toString().trim();
    let testsAdded = 0;
    testsOutput.split("\n").forEach(line => {
      const parts = line.split("\t");
      if (parts.length >= 3 && parts[2].toLowerCase().includes("test")) {
        testsAdded += parseInt(parts[0]) || 0;
      }
    });

    return { files, adds, dels, testsAdded };
  } catch (e) {
    return { files: 0, adds: 0, dels: 0, testsAdded: 0 };
  }
}

function getCoverage() {
  const lcovPath = path.join(ARTIFACTS_DIR, "coverage", "lcov.info");
  const diffPath = path.join(ARTIFACTS_DIR, "coverage", "diff-coverage.txt");

  let totalPct = 0;
  let diffPct = 0;

  const lcov = safeRead(lcovPath);
  if (lcov) {
    let lf = 0, lh = 0;
    lcov.split("\n").forEach(line => {
      if (line.startsWith("LF:")) lf += parseInt(line.split(":")[1]);
      if (line.startsWith("LH:")) lh += parseInt(line.split(":")[1]);
    });
    totalPct = lf ? (lh / lf) * 100 : 0;
  }

  const diffContent = safeRead(diffPath);
  if (diffContent) {
    const match = diffContent.match(/(?:Total|Coverage|Diff Coverage):\s+(\d+(?:\.\d+)?)%/i);
    if (match) {
      diffPct = parseFloat(match[1]);
    }
  }

  return {
    total: totalPct,
    diff: diffPct,
    status: totalPct >= 50 ? "✅" : "⚠️",
    diffStatus: diffPct >= 80 ? "✅" : "❌"
  };
}

function getBundleSize() {
  const reportPath = path.join(ARTIFACTS_DIR, "bundle-size", "bundle-size-report.json");
  const data = safeJson(reportPath);

  const mainSize = data.mainJsKb ? `${data.mainJsKb.toFixed(2)} KB` : "N/A";
  const gzipSize = data.gzipMainJsKb ? `${data.gzipMainJsKb.toFixed(2)} KB` : "N/A";

  return {
    main: mainSize,
    gzip: gzipSize,
    passed: data.passed || false,
    status: data.passed ? "✅" : (data.mainJsKb ? "❌" : "⚪️"),
    assets: data.messages || []
  };
}

function getSmokeTest() {
  const reportPath = path.join(ARTIFACTS_DIR, "smoke-test", "smoke-report.json");
  const data = safeJson(reportPath);

  if (!data.routes) {
    return { status: "⚪️", passed: false, routesPass: 0, routesFail: 0, startup: "N/A", errors: [], flakiness: 0, consoleErrors: [], failedRoutes: [] };
  }

  const routesPass = data.routes.filter(r => r.passed === true).length;
  const routesFail = data.failedRoutes ? data.failedRoutes.length : 0;
  const startup = data.startupTimeMs ? `${data.startupTimeMs}ms` : "N/A";
  const startupStatus = (data.startupTimeMs && data.startupTimeMs < 5000) ? "✅" : "⚠️";

  let retries = 0;
  if (data.routes) {
    data.routes.forEach(r => { if (r.retry) retries += r.retry; });
  }

  return {
    status: data.passed ? "✅" : "❌",
    passed: data.passed,
    routesPass,
    routesFail,
    startup,
    startupStatus,
    consoleErrors: data.consoleErrors || [],
    failedRoutes: data.failedRoutes || [],
    flakiness: retries
  };
}

function getE2ECoverage() {
  const covPath = path.join(ARTIFACTS_DIR, "e2e-results", "e2e-coverage.json");
  const data = safeJson(covPath);

  let coveredFlows = 0;
  let summary = [];

  if (data && data.flows) {
    EXPECTED_FLOWS.forEach(flow => {
        const flowData = data.flows[flow];
        if (flowData && flowData.total > 0) {
            coveredFlows++;
            const status = flowData.passed === flowData.total ? '✅' : '⚠️';
            summary.push(`- **${flow}**: ${status} (${flowData.passed}/${flowData.total})`);
        } else {
            summary.push(`- **${flow}**: ❌ (0/0)`);
        }
    });
  } else {
    EXPECTED_FLOWS.forEach(flow => {
        summary.push(`- **${flow}**: ❌ (0/0)`);
    });
  }

  const coveragePct = Math.round((coveredFlows / EXPECTED_FLOWS.length) * 100);

  return {
    pct: coveragePct,
    summary: summary,
    hasData: !!(data && data.flows)
  };
}

function getJobBreakdown() {
  const statusEmoji = (s) => {
    if (s === "success") return "✅";
    if (s === "failure") return "❌";
    if (s === "cancelled") return "🚫";
    return "⚪️";
  };

  return {
    static: statusEmoji(process.env.STATIC_STATUS),
    unit: statusEmoji(process.env.UNIT_STATUS),
    build: statusEmoji(process.env.WEB_BUILD_STATUS),
    smoke: statusEmoji(process.env.WEB_SMOKE_STATUS),
    e2e: statusEmoji(process.env.WEB_E2E_STATUS)
  };
}

// --- CALC QUALITY SCORE ---

function calculateQualityScore(cov, smoke, bundle, jobs, e2e) {
  let score = 0;

  // Total Coverage (20)
  score += Math.min((cov.total / 80) * 20, 20);

  // Diff Coverage (20)
  score += Math.min((cov.diff / 80) * 20, 20);

  // Smoke Tests (20)
  if (smoke.passed) score += 20;
  else if (smoke.routesPass > 0) score += (smoke.routesPass / (smoke.routesPass + smoke.routesFail)) * 10;

  // E2E Flow Coverage (20)
  score += Math.min((e2e.pct / 100) * 20, 20);

  // Bundle (10)
  if (bundle.passed) score += 10;

  // Policy/Static (10)
  if (process.env.STATIC_STATUS === 'success') score += 10;

  return Math.round(score);
}

function computeOverallStatus(hasFailures, hasWarnings, score) {
  if (hasFailures || score < 70) return "Failure";
  if (hasWarnings) return "Warning";
  if (score >= 90) return "Success";
  return "Warning";
}

// --- DATA AGGREGATION ---

const impact = getGitImpact();
const coverage = getCoverage();
const bundle = getBundleSize();
const smoke = getSmokeTest();
const jobs = getJobBreakdown();
const e2e = getE2ECoverage();
const score = calculateQualityScore(coverage, smoke, bundle, jobs, e2e);

const flutterVerRaw = getVersion("flutter --version");
const flutterVer = flutterVerRaw.replace(/^Flutter\s+/i, '').split(' • ')[0];
const nodeVer = getVersion("node -v");

const hasFailures = jobs.static === "❌" || jobs.unit === "❌" || jobs.build === "❌" || jobs.smoke === "❌" || jobs.e2e === "❌";
const hasWarnings = coverage.diff < 80 || (jobs.build === "✅" && !bundle.passed) || (jobs.smoke === "✅" && !smoke.passed) || (e2e.pct < 100);

const overallStatus = computeOverallStatus(hasFailures, hasWarnings, score);
const statusLabel = overallStatus === 'Success' ? 'Passing' : (overallStatus === 'Warning' ? 'Attention Needed' : 'Issues Found');
const verdictEmoji = hasFailures ? "❌" : (overallStatus === "Warning" ? "⚠️" : "✅");
const statusEmoji = hasFailures ? "🔴" : (overallStatus === "Warning" ? "🟡" : "🟢");

// --- WHAT NEEDS ATTENTION ---

const topIssues = [];
if (jobs.static === "❌") topIssues.push("🛡️ **Static Analysis Failed**: Please check lint rules.");
if (jobs.unit === "❌") topIssues.push("🧪 **Unit Tests Failed**: Check test logs for specific failures.");
if (smoke.routesFail > 0) topIssues.push(`💨 **Smoke Test Failures**: \`${smoke.failedRoutes[0]}\` and ${smoke.routesFail - 1} more routes.`);
if (coverage.diff < 80) topIssues.push(`🧪 **Low Diff Coverage**: PR coverage is only **${coverage.diff}%** (target 80%).`);
if (e2e.pct < 100) topIssues.push(`🎭 **Incomplete E2E Flow Coverage**: Only **${e2e.pct}%** of flows covered.`);
if (smoke.consoleErrors && smoke.consoleErrors.length > 0) topIssues.push(`🚫 **Console Errors Detected**: ${smoke.consoleErrors.length} errors found during smoke tests.`);
if (jobs.build === "✅" && !bundle.passed) topIssues.push("📦 **Bundle Size Exceeded**: Main JS bundle is over the 5MB threshold.");

if (topIssues.length === 0) topIssues.push("✨ Everything looks stellar! No immediate action required.");

// --- RENDER ---

const body = `<!-- ci-summary-bot -->
## 🚀 CI Quality Report

> **Status:** ${verdictEmoji} **${statusLabel}**
> **Quality Score:** **${score}/100** ${score >= 90 ? '🏆' : (score >= 70 ? '⚖️' : '💔')}
> [View Full Logs](${RUN_URL})
>
> **Run:** \`${process.env.GITHUB_SHA ? process.env.GITHUB_SHA.substring(0, 7) : 'local'}\` • **Branch:** \`${HEAD_REF}\` → \`${BASE_REF}\`
> **Env:** Flutter \`${flutterVer.split(' • ')[0]}\` • Node \`${nodeVer}\` • Runner \`${RUNNER_OS}\`

---

### 🧩 Code Change Impact
📦 Files Changed: **${impact.files}** • 🧠 Additions: **<span style="color:green">+${impact.adds}</span>** • 🧹 Deletions: **<span style="color:red">-${impact.dels}</span>** • 🧪 Tests Added: **${impact.testsAdded}**

---

### 🚀 Scorecard

| Area | Metric | Result | Trend | Status |
| :--- | :--- | :--- | :---: | :---: |
| 🧪 **Testing** | Total Coverage | **${coverage.total.toFixed(2)}%** | — | ${coverage.status} |
| 🧩 **Diff Coverage** | PR Diff Coverage | **${coverage.diff}%** | — | ${coverage.diffStatus} |
| 🎭 **E2E Flows** | Flow Coverage | **${e2e.pct}%** | — | ${e2e.pct >= 100 ? "✅" : "⚠️"} |
| 📦 **Bundle** | Main JS | **${bundle.main}** | — | ${bundle.status} |
| 🗜️ **Bundle** | Gzip | **${bundle.gzip}** | — | ${bundle.status} |
| ⚡ **UX & Stability** | Startup Time | **${smoke.startup}** | — | ${smoke.startupStatus} |
| 💨 **Smoke** | Routes Checked | **${smoke.routesPass} succ, ${smoke.routesFail} fail** | — | ${smoke.status} |

---

### 🎭 E2E Flow Coverage Summary
${e2e.summary.join('\n')}

---

### 🛡️ Job Breakdown

- 🛡️ Static Checks: ${jobs.static}
- 🧪 Unit Tests: ${jobs.unit}
- 🌐 Web Build: ${jobs.build}
- 💨 Web Smoke: ${jobs.smoke}
- 🎭 E2E Tests: ${jobs.e2e}

---

### 🔥 What needs attention (top 3)
${topIssues.slice(0, 3).map((issue, i) => `${i + 1}. ${issue}`).join("\n")}

${smoke.flakiness > 0 ? `> ⚠️ **Flaky Tests Detected:** Playwright required **${smoke.flakiness}** retries to pass some routes.` : ""}

---

<details>
<summary>🔎 <strong>Detailed Insights</strong></summary>

#### 📦 Bundle Analysis
- **Main JS**: ${bundle.main}
- **Gzip**: ${bundle.gzip}
${bundle.assets.length > 0 ? `\n**Top Assets:**\n${bundle.assets.slice(0, 5).map(a => `- ${a}`).join("\n")}` : ""}

#### 💨 Smoke Tests
- **Startup**: ${smoke.startup}
- **Routes Failed**: ${smoke.failedRoutes.length > 0 ? smoke.failedRoutes.map(r => `\`${r}\``).join(", ") : "None"}
- **Console Errors (${smoke.consoleErrors.length}):**
${smoke.consoleErrors.length > 0 ? smoke.consoleErrors.slice(0, 10).map(e => `- \`${e.replace(/`/g, "")}\``).join("\n") : "None"}

</details>

---
_Updated automatically. Re-run CI to refresh. ${new Date().toISOString()}_
`;

console.log(body);
