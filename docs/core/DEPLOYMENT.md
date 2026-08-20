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

## The built bundle is not in version control

`flutter build web` output is generated, not source. It is built in CI and handed
straight to Vercel; nothing is committed back. To look at a production-style build
locally:

```bash
flutter build web --release
cd build/web && python -m http.server 8080
```

Note that a plain static file server will 404 on a hard refresh of a deep link,
because client-side routes have no file behind them. Vercel handles this via the
SPA fallback in `.vercel/output/config.json`; locally, prefer `flutter run -d chrome`.

## Self-hosting with Docker

`Dockerfile` builds the web app and serves it with nginx, using `nginx.conf` for
SPA routing and caching. It depends on no committed build output:

```bash
docker build -t expense-tracker-web --build-arg API_BASE_URL=<url> .
docker run -p 8080:80 expense-tracker-web
```

This is the supported path for hosting the app anywhere other than Vercel.
