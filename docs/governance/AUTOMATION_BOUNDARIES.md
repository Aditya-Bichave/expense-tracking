# Automation Boundaries

## Purpose
To define what parts of the codebase AI agents (Jules) can modify safely and what requires human review.

## 1. Safe to Modify (Low Risk)
AI agents are **permitted** to modify these areas without explicit approval, provided tests pass.
*   `lib/features/*` (Logic, UI, Bloc, Repositories).
*   `test/*` (Adding or fixing tests).
*   `lib/l10n/*` (Adding localization strings).
*   `assets/*` (Adding images/icons).

## 2. Review Required (Medium Risk)
AI agents **may** modify these areas but **must** request explicit review/verification.
*   `lib/core/auth/*` (Authentication logic).
*   `lib/core/sync/*` (Sync Service logic).
*   `pubspec.yaml` (Adding dependencies - prefer well-known packages).
*   `lib/main.dart` (App entry point).
*   `lib/router.dart` (Navigation changes).

## 3. Forbidden (High Risk)
AI agents **must not** modify these areas unless explicitly instructed by a human maintainer.
*   `.github/workflows/*` (CI/CD pipelines).
*   `setup.sh` (System provisioning).
*   `JULES_ENV_SETUP.md` (Environment config).
*   `AGENTS.md` (Root instructions - self-modification restricted).
*   `docs/governance/*` (Policy files).

## 4. Required Validation
Before merging any change, AI agents **must**:
1.  Run `dart format .`.
2.  Run `flutter analyze`.
3.  Run relevant tests (`flutter test`).
4.  Verify no `print()` statements or `TODO`s without IDs are introduced.
