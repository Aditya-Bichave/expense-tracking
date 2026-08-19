# Deployment Guide

The Flutter web app is built in GitHub Actions and deployed to Vercel as a
**prebuilt** artifact. Vercel runs no build of its own: it has no Flutter
toolchain, which is why the compiled bundle used to be committed to the
repository instead.

Pipeline: `.github/workflows/deploy_web.yml`.

## How a deploy happens

1. A commit lands on `main`.
2. `Flutter CI (Strict)` runs. If it fails, nothing deploys.
3. On success, `Deploy Web` triggers via `workflow_run`, checks out **the exact
   commit CI validated**, and runs `flutter build web --release`.
4. The output is laid out as a Vercel
   [Build Output API](https://vercel.com/docs/build-output-api/v3) directory
   (`.vercel/output/static` plus a `config.json` holding the SPA fallback route).
5. `vercel deploy --prebuilt --prod` ships it.

`workflow_dispatch` is also wired up, for re-deploying without a new commit.

### Why it is gated on CI

The previous version of this workflow triggered on `push` to `main` and committed
the built bundle back with `[skip ci]`. Two consequences: a commit that broke
every test still deployed, and the deploy commit itself was never tested. The
`workflow_run` trigger means the deploy is downstream of a green build.

## Required repository secrets

| Secret | Purpose |
| --- | --- |
| `VERCEL_TOKEN` | Vercel access token the CLI authenticates with |
| `VERCEL_ORG_ID` | Vercel team/user id that owns the project |
| `VERCEL_PROJECT_ID` | The Vercel project to deploy to |
| `SUPABASE_URL` | Compiled into the bundle via `--dart-define` |
| `SUPABASE_ANON_KEY` | Compiled into the bundle via `--dart-define` |

`VERCEL_ORG_ID` and `VERCEL_PROJECT_ID` are in `.vercel/project.json` after
running `vercel link` locally, or in the project settings in the dashboard.

## Git-integration deploys are disabled deliberately

`vercel.json` sets:

```json
{ "git": { "deploymentEnabled": false } }
```

Without this, Vercel's Git integration would deploy on every push *as well as*
this workflow. Those deploys would also fail, because they would try to build a
Flutter project on a runtime that has no Flutter SDK. Deploys come from CI only.

## `server/public` is no longer in version control

It is generated output (`flutter build web`), ignored via `.gitignore`. To serve
the site locally with `server/server.js`:

```bash
flutter build web --release
mkdir -p server/public && cp -r build/web/. server/public/
cd server && npm install && npm start
```

### If you still deploy via Render

This guide previously described a Render Web Service with **Root Directory**
`server`, **Build Command** `npm install`, **Start Command** `node server.js`.
That setup worked only because `server/public` was committed — Render cloned the
repository and served the checked-in bundle.

That no longer holds. If Render is still in use, pick one:

- **Retire it** and serve from Vercel only (what this document now assumes).
- **Give Render the bundle.** Add a step to `deploy_web.yml` that publishes
  `build/web` somewhere Render can fetch at boot, and have `server.js` download it
  on start.
- **Use the Docker path instead.** The repository's `Dockerfile` already builds
  Flutter web and serves it with nginx, and does not depend on any committed
  output. Deploy that image rather than the Node server.

## Client logs

`server/server.js` exposes a `/log` endpoint that forwards client logs to the
host's stdout, tagged `[CLIENT_LOG]`. This only applies when serving through the
Node server, not through Vercel.
