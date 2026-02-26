# Migration Playbook

## 1. Why a Bridge Layer?
The **Bridge Layer** (`lib/ui_bridge/`) is a temporary compatibility layer designed to decouple the UI Kit implementation from the feature code migration.

*   **Goal**: Allow features to migrate away from raw Flutter widgets (`Text`, `ElevatedButton`, `Card`) without immediately adopting the full complexity of the new `UiKit` components if they aren't ready or if the developer prefers a familiar API.
*   **Mechanism**: Bridge components wrap `UiKit` components but expose an API similar to standard Flutter widgets or the legacy shared widgets used in the app.

## 2. Migration Waves

### Wave 1: The "Bridge" Swap
*   **Target**: High-usage raw widgets (Buttons, Text, Cards, TextFields).
*   **Action**: When touching a feature screen for any reason, replace raw widgets with their Bridge equivalents.
    *   `Text(...)` -> `BridgeText(...)`
    *   `ElevatedButton(...)` -> `BridgeButton(...)`
    *   `Card(...)` -> `BridgeCard(...)`
    *   `TextFormField(...)` -> `BridgeTextField(...)`
*   **Benefit**: Instantly unifies styling (fonts, colors, shapes) with the new Design System without rewriting logic.

### Wave 2: Direct UI Kit Adoption (Optional/Advanced)
*   **Target**: Complex screens or new features.
*   **Action**: Use `App*` components directly from `lib/ui_kit/`.
    *   `BridgeButton` -> `AppButton`
*   **Benefit**: Access to full power of the Design System (variants, sizes, semantic tokens).

## 3. Rules for Parallel Agents

1.  **Token/Theme Ownership**: Only **ONE** agent/engineer should modify `lib/ui_kit/tokens/` or `lib/ui_kit/theme/` at a time to prevent conflicts.
2.  **Component Independence**: Components in `lib/ui_kit/components/` can be built/modified in parallel as long as they are in different subdirectories (e.g., `buttons/` vs `inputs/`).
3.  **Feature Migration**: Feature migration can happen fully in parallel.
    *   Agent A migrates `features/dashboard`
    *   Agent B migrates `features/settings`
4.  **No New Raw Styles**:
    *   **NEVER** introduce new `Colors.red`, `TextStyle(fontSize: 20)`, or `BoxDecoration` in feature code.
    *   Always use `Bridge*` widgets or `context.kit` tokens.

## 4. Troubleshooting
*   **"Missing parameter in Bridge widget"**: If a Bridge widget lacks a parameter you need from the raw widget, add it to the Bridge adapter and map it to the underlying `UiKit` component. Do **not** revert to raw widgets.
*   **"UI looks different"**: This is expected! The Bridge uses the new Design System. If it looks *broken* (unreadable), check the Theme mapping in `AppTheme`.
