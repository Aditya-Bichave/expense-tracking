/**
 * Reusable static file server for Flutter web build.
 * Used by globalSetup to serve the app during E2E tests.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'application/font-woff',
  '.woff2': 'application/font-woff2',
  '.ttf': 'application/font-ttf',
  '.wasm': 'application/wasm',
  '.map': 'application/json',
};

/**
 * Start a static file server for the Flutter web build.
 * @param {string} buildDir - Absolute path to the build/web directory
 * @param {number} port
 * @returns {{ server: http.Server, stop: () => void }}
 */
function startServer(buildDir, port) {
  const server = http.createServer((req, res) => {
    // Handle POST /log (Flutter web logging)
    if (req.method === 'POST' && req.url === '/log') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ok: true }));
      return;
    }

    let urlPath = req.url.split('?')[0]; // strip query params
    let filePath = path.join(buildDir, urlPath === '/' ? 'index.html' : urlPath);

    // Security: prevent directory traversal
    if (!filePath.startsWith(buildDir)) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }

    fs.stat(filePath, (err, stats) => {
      if (err || !stats.isFile()) {
        // SPA fallback: serve index.html for extensionless paths
        if (path.extname(filePath) === '') {
          const index = path.join(buildDir, 'index.html');
          fs.readFile(index, (readErr, data) => {
            if (readErr) {
              res.writeHead(404);
              res.end('Not Found');
            } else {
              res.writeHead(200, { 'Content-Type': 'text/html' });
              res.end(data);
            }
          });
        } else {
          res.writeHead(404);
          res.end('Not Found');
        }
        return;
      }

      const ext = path.extname(filePath).toLowerCase();
      const contentType = MIME_TYPES[ext] || 'application/octet-stream';

      fs.readFile(filePath, (readErr, data) => {
        if (readErr) {
          res.writeHead(500);
          res.end('Server Error');
          return;
        }
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
      });
    });
  });

  server.listen(port);

  return {
    server,
    stop: () => new Promise((resolve) => server.close(resolve)),
  };
}

module.exports = { startServer };

// If run directly: node server.js <buildDir> <port>
if (require.main === module) {
  const buildDir = path.resolve(process.argv[2] || '../../build/web');
  const port = parseInt(process.argv[3] || '8080', 10);

  console.log(`Starting static server...`);
  console.log(`- Build Dir: ${buildDir}`);
  console.log(`- Port: ${port}`);

  if (!fs.existsSync(buildDir)) {
    console.error(`Error: Build directory does not exist: ${buildDir}`);
    process.exit(1);
  }

  startServer(buildDir, port);
  console.log(`Server listening at http://localhost:${port}`);
}
