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
