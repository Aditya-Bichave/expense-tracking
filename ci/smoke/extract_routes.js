const fs = require('fs');
const path = require('path');

// Assuming this script runs from ci/smoke/
const ROUTE_NAMES_FILE = path.join(__dirname, '../../lib/core/constants/route_names.dart');
const OUTPUT_FILE = path.join(__dirname, 'routes.json');

function extractRoutes() {
  console.log('Extracting routes from ' + ROUTE_NAMES_FILE);

  try {
    const content = fs.readFileSync(ROUTE_NAMES_FILE, 'utf8');
    const routes = [];
    let match;

    // Regex to match: static const String variableName = '/path';
    // We are interested in the string literal value.
    const routeRegex = /static const String \w+\s*=\s*'(\/[^']*)';/g;

    while ((match = routeRegex.exec(content)) !== null) {
      const route = match[1];

      // Filter out parameterized routes (containing :) unless safe defaults are known
      if (route.includes(':')) {
        console.log(`Skipping parameterized route: ${route}`);
        continue;
      }

      routes.push(route);
    }

    // Manual list of critical routes to ensure coverage, including sub-routes
    // derived from standard app structure which regex on RouteNames can't capture (since they are relative)
    const manualRoutes = [
      '/setup',
      '/dashboard',
      '/transactions',
      '/transactions/add',
      '/plan',
      '/plan/add_budget',
      '/plan/add_goal',
      '/plan/manage_categories',
      '/plan/manage_categories/add_category',
      '/accounts',
      '/accounts/add_account',
      '/recurring',
      '/recurring/add_recurring',
      '/settings',
      // Report routes
      '/dashboard/spending_category',
      '/dashboard/spending_time',
      '/dashboard/income_expense',
      '/dashboard/budget_performance',
      '/dashboard/goal_progress'
    ];

    for (const r of manualRoutes) {
      if (!routes.includes(r)) {
        // Only log if it's a "base" route we expected to find
        if (r.split('/').length === 2) {
            console.warn(`Warning: Critical base route ${r} not found by regex. Adding manually.`);
        }
        routes.push(r);
      }
    }

    // Remove duplicates
    const uniqueRoutes = [...new Set(routes)].sort();

    console.log(`Found ${uniqueRoutes.length} valid smoke test routes.`);
    console.log('Routes:', uniqueRoutes);

    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(uniqueRoutes, null, 2));
    console.log('Routes written to ' + OUTPUT_FILE);

  } catch (err) {
    console.error('Error extracting routes:', err);
    process.exit(1);
  }
}

extractRoutes();
