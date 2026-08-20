# Known Pitfalls & Solutions

Common issues encountered in the codebase and their solutions.

## 1. Hive Schema Changes
**Issue**: Changing TypeIds/FieldIds or adding fields without updating the Hive TypeAdapter breaks existing data on user devices.
**Solution**:
*   Always define new TypeIds/FieldIds explicitly.
*   **NEVER** change existing FieldIds.
*   Add new fields as optional/nullable.
*   Run `flutter pub run build_runner build` to regenerate `.g.dart` files.

## 2. Supabase Synchronization
**Issue**: Race conditions between Local writes and Remote updates causing flickering UI or duplicate data.
**Solution**:
*   Always use `Outbox` for local writes.
*   Wait for `Synced` state or optimistic update confirmation in UI.
*   Use `client_generated_id` (UUID) for idempotency on the backend.

## 3. Web Platform Issues
**Issue**:
*   CORS errors on Supabase requests.
*   `Image.network` failing due to canvas tainting.
*   Performance issues with HTML renderer vs CanvasKit.
**Solution**:
*   Use `flutter build web --release` (defaults to CanvasKit/Auto).
*   Test with `flutter run -d chrome`.
*   Ensure Supabase project has correct CORS headers.

## 4. CI/CD Failures
**Issue**: Build passes locally but fails in GitHub Actions.
**Solution**:
*   **Format Check**: Run `dart format .` locally.
*   **Analyze Check**: Run `flutter analyze` locally.
*   **Golden Tests**: Font rendering differs on Linux (CI) vs macOS/Windows. Update goldens carefully using Docker if possible.
*   **Dependencies**: Ensure `pubspec.lock` is committed and up-to-date.

## 5. State Management Complexity
**Issue**: Over-fetching or infinite loops in Bloc listeners.
**Solution**:
*   Use `BlocListener` for side effects (navigation, snackbars).
*   Use `BlocBuilder` for UI rebuilding.
*   Avoid triggering events inside `build()` methods.

## Supabase migrations cannot provision a fresh database

`supabase/migrations` currently does **not** apply cleanly to an empty Postgres.
Two migrations define `public.profiles` incompatibly:

| Migration | Definition |
| --- | --- |
| `20240320000001_initial_schema.sql` | `CREATE TABLE profiles (user_id UUID PRIMARY KEY, phone, display_name, ...)` |
| `20240523000000_foundation_pack.sql` | `create table if not exists public.profiles (id uuid PRIMARY KEY, full_name, email, avatar_url, currency, timezone, ...)` |

Because the table already exists, the second definition is a silent no-op. Its RLS
policies then reference `id`, which the table does not have, and the apply aborts
with `ERROR: column "id" does not exist`.

The disagreement runs further:

- `20240524000000_viral_loop.sql` references `profiles(user_id)`
- `20240523000000_foundation_pack.sql`, `20260226100000_phase_4c_nudge_engine.sql`
  and `20260309000000_group_net_balances.sql` reference `profiles(id)`

Dart's `ProfileModel` (`id`, `fullName`, `email`, `avatarUrl`, `currency`,
`timezone`, `upiId`) matches the `foundation_pack` shape, so the running database
is evidently **not** the result of applying these files in order — the migration
history is not reproducible.

**Consequences:** no new environment can be stood up from this repository. That
blocks disaster recovery, staging, per-developer databases, and any local
`supabase start`.

**Fixing it** needs the production schema dumped and compared, then most likely a
squashed baseline migration that reflects reality, with the legacy definitions
retired. Do not simply edit the old files: whichever definition is wrong, the
other one has already run somewhere.

Until then, the `validate` job in `.github/workflows/supabase.yml` runs and
reports this failure but is marked `continue-on-error` so it does not block
unrelated pull requests.
