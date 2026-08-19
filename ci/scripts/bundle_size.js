const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

const BUILD_DIR = 'build/web';
const MAIN_JS = path.join(BUILD_DIR, 'main.dart.js');
const REPORT_FILE = 'bundle-size-report.json';
const BUDGET_FILE = 'ci/budgets.json';

// Everything under canvaskit/ is renderer payload shipped by the Flutter SDK,
// not application code. It holds several mutually-exclusive variants — a
// browser downloads exactly one of canvaskit.wasm, chromium/, skwasm.wasm or
// skwasm_heavy.wasm — plus *.symbols debug maps that are never fetched at all.
// Summing them overstates what a user actually downloads by roughly 4x, and
// makes `total_kb` move whenever the SDK is upgraded rather than when our code
// grows. `total_kb` still covers the whole directory (it bounds what we ship
// and what a CDN stores), but `app_payload_kb` is the metric that tracks us.
const SDK_RENDERER_DIR = 'canvaskit';
const DEBUG_SYMBOL_EXT = '.symbols';

function walk(dir, onFile) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const filePath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(filePath, onFile);
    } else {
      onFile(filePath, fs.statSync(filePath).size);
    }
  }
}

function isSdkRenderer(relPath) {
  return relPath.split(path.sep)[0] === SDK_RENDERER_DIR;
}

function isDebugSymbols(relPath) {
  return relPath.endsWith(DEBUG_SYMBOL_EXT);
}

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

  const mainJsSizeKb = fs.statSync(MAIN_JS).size / 1024;
  const gzipSizeKb = zlib.gzipSync(fs.readFileSync(MAIN_JS)).length / 1024;

  let totalSize = 0;
  let rendererSize = 0;
  let symbolsSize = 0;

  walk(BUILD_DIR, (filePath, size) => {
    const relPath = path.relative(BUILD_DIR, filePath);
    totalSize += size;
    if (isDebugSymbols(relPath)) {
      symbolsSize += size;
    } else if (isSdkRenderer(relPath)) {
      rendererSize += size;
    }
  });

  const totalSizeKb = totalSize / 1024;
  const rendererKb = rendererSize / 1024;
  const symbolsKb = symbolsSize / 1024;
  // What our own code and assets contribute, independent of the SDK renderer.
  const appPayloadKb = totalSizeKb - rendererKb - symbolsKb;

  const report = {
    mainJsKb: mainJsSizeKb,
    gzipMainJsKb: gzipSizeKb,
    totalKb: totalSizeKb,
    appPayloadKb,
    sdkRendererKb: rendererKb,
    debugSymbolsKb: symbolsKb,
    budgets,
    passed: true,
    messages: [],
  };

  const fmt = (n) => n.toFixed(2);
  console.log(`Bundle Size Report:`);
  console.log(
    `  Main JS:      ${fmt(mainJsSizeKb)} KB (Budget: ${budgets.main_js_kb} KB)`
  );
  console.log(
    `  Gzip Main JS: ${fmt(gzipSizeKb)} KB (Budget: ${budgets.gzip_main_js_kb} KB)`
  );
  console.log(
    `  App payload:  ${fmt(appPayloadKb)} KB (Budget: ${budgets.app_payload_kb} KB)  <- our code + assets`
  );
  console.log(
    `  Total Web:    ${fmt(totalSizeKb)} KB (Budget: ${budgets.total_kb} KB)`
  );
  console.log(`    of which SDK renderer (canvaskit/): ${fmt(rendererKb)} KB`);
  console.log(`    of which debug symbols (*.symbols): ${fmt(symbolsKb)} KB`);

  const check = (actual, budget, label) => {
    if (budget === undefined) return;
    if (actual > budget) {
      report.passed = false;
      report.messages.push(
        `${label} exceeded budget! (${fmt(actual)} > ${budget})`
      );
    }
  };

  check(mainJsSizeKb, budgets.main_js_kb, 'Main JS size');
  check(gzipSizeKb, budgets.gzip_main_js_kb, 'Gzip Main JS size');
  check(appPayloadKb, budgets.app_payload_kb, 'App payload size');
  check(totalSizeKb, budgets.total_kb, 'Total size');

  fs.writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2));

  if (!report.passed) {
    console.error('❌ Bundle size check failed.');
    report.messages.forEach((m) => console.error(m));
    process.exit(1);
  } else {
    console.log('✅ Bundle size check passed.');
  }
}

run();
