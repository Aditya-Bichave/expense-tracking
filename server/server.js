import express from "express";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json({ limit: "1mb" }));

// Client log endpoint
app.post("/log", (req, res) => {
  const { level, message, time, caller, stackTrace } = req.body;

  const timestamp = time || new Date().toISOString();
  console.log(`[CLIENT_LOG] ${timestamp} [${level}] ${message}`);

  if (caller) console.log(`  Caller: ${caller}`);
  if (stackTrace) console.log(`  Stack: ${stackTrace}`);

  res.json({ ok: true });
});

// Serve static files from ./public
const publicDir = path.join(__dirname, "public");
app.use(express.static(publicDir));

// SPA fallback for all other routes
app.get("*", (req, res) => {
  res.sendFile(path.join(publicDir, "index.html"));
});

const port = process.env.PORT || 10000;
app.listen(port, () => console.log("Server listening on", port));
