const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

const BUILD_DIR = 'build/web';
const MAIN_JS = path.join(BUILD_DIR, 'main.dart.js');
const REPORT_FILE = 'bundle-size-report.json';
const BUDGET_FILE = 'ci/budgets.json';

async function run() {
  if (!fs.existsSync(BUDGET_FILE)) {
    console.error(`Budget file not found: ${BUDGET_FILE}`);
    process.exit(1);
  }

  const budgets = JSON.parse(fs.readFileSync(BUDGET_FILE, 'utf8'));

  if (!fs.existsSync(MAIN_JS)) {
    console.error(`Main JS not found: ${MAIN_JS}`);
    process.exit(1);
  }

  const mainJsStat = fs.statSync(MAIN_JS);
  const mainJsSizeKb = mainJsStat.size / 1024;

  const mainJsContent = fs.readFileSync(MAIN_JS);
  const gzipped = zlib.gzipSync(mainJsContent);
  const gzipSizeKb = gzipped.length / 1024;

  // Calculate total size of build/web
  let totalSize = 0;
  function traverse(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      if (stat.isDirectory()) {
        traverse(filePath);
      } else {
        totalSize += stat.size;
      }
    }
  }
  traverse(BUILD_DIR);
  const totalSizeKb = totalSize / 1024;

  const report = {
    mainJsKb: mainJsSizeKb,
    gzipMainJsKb: gzipSizeKb,
    totalKb: totalSizeKb,
    budgets,
    passed: true,
    messages: []
  };

  console.log(`Bundle Size Report:`);
  console.log(`  Main JS: ${mainJsSizeKb.toFixed(2)} KB (Budget: ${budgets.main_js_kb} KB)`);
  console.log(`  Gzip Main JS: ${gzipSizeKb.toFixed(2)} KB (Budget: ${budgets.gzip_main_js_kb} KB)`);
  console.log(`  Total Web: ${totalSizeKb.toFixed(2)} KB (Budget: ${budgets.total_kb} KB)`);

  if (mainJsSizeKb > budgets.main_js_kb) {
    report.passed = false;
    report.messages.push(`Main JS size exceeded budget! (${mainJsSizeKb.toFixed(2)} > ${budgets.main_js_kb})`);
  }
  if (gzipSizeKb > budgets.gzip_main_js_kb) {
    report.passed = false;
    report.messages.push(`Gzip Main JS size exceeded budget! (${gzipSizeKb.toFixed(2)} > ${budgets.gzip_main_js_kb})`);
  }
  if (totalSizeKb > budgets.total_kb) {
    report.passed = false;
    report.messages.push(`Total size exceeded budget! (${totalSizeKb.toFixed(2)} > ${budgets.total_kb})`);
  }

  fs.writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2));

  if (!report.passed) {
    console.error('❌ Bundle size check failed.');
    report.messages.forEach(m => console.error(m));
    process.exit(1);
  } else {
    console.log('✅ Bundle size check passed.');
  }
}

run();
