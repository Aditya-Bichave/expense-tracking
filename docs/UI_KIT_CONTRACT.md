# UI Kit Contract

## 1. Purpose
This UI Kit serves as the single source of truth for the application's design system. It ensures consistency, accessibility, and theming support across the entire app. It encapsulates design tokens (colors, typography, spacing, etc.) and provides a set of reusable, semantic components.

## 2. Layering Model
The UI architecture follows a strict layering model:

1.  **Tokens (`lib/ui_kit/tokens/`)**: The atomic values of the design system (e.g., `AppColors`, `AppSpacing`, `AppTypography`). These are not accessed directly by features but via the Theme.
2.  **Theme (`lib/ui_kit/theme/`)**: Bundles tokens into a cohesive theme (`AppKitTheme`) and exposes them via `ThemeExtension`.
3.  **Components (`lib/ui_kit/components/`)**: Semantic widgets that consume tokens from the theme. They do not have hardcoded styles.
4.  **Bridge (`lib/ui_bridge/`)**: A compatibility layer that mimics legacy widgets but internally uses UI Kit components. This facilitates phased migration.
5.  **Features (`lib/features/`)**: Application code that consumes Components or the Bridge. **Features should NOT use raw Flutter Material widgets (like `Text`, `ElevatedButton`) directly if a UI Kit equivalent exists.**

## 3. Access Pattern
The **ONLY** allowed way to access design tokens is through the `BuildContext` extension:

```dart
final kit = context.kit;

// Usage
color: kit.colors.primary
padding: kit.spacing.allMd
style: kit.typography.body
radius: kit.radii.medium
```

**FORBIDDEN:**
- `Theme.of(context).primaryColor` (Legacy)
- `Colors.blue` (Raw colors)
- `TextStyle(fontSize: 14)` (Raw styles)

## 4. Naming Conventions
*   **Components**: Prefix with `App` (e.g., `AppButton`, `AppCard`) or `Ui` for new purely internal ones if needed, but `App` is the current standard.
*   **Bridge Adapters**: Prefix with `Bridge` (e.g., `BridgeButton`, `BridgeText`) to clearly distinguish them during migration.

## 5. Component API Conventions
All components should adhere to standard enums defined in `lib/ui_kit/foundation/ui_enums.dart`:

*   **Size**: `UiSize` (xs, sm, md, lg, xl)
*   **Variant**: `UiVariant` (primary, secondary, ghost, destructive, etc.)
*   **State**: `UiState` (enabled, disabled, loading, error, etc.)

Example:
```dart
AppButton(
  label: 'Submit',
  variant: UiVariant.primary,
  size: UiSize.md,
  onPressed: () {},
)
```

## 6. Forbidden Patterns (Post-Migration)
After the migration is complete, the following should be flagged by linters or code review:
*   Direct use of `Colors.*`
*   Manual `TextStyle` construction
*   Hardcoded `EdgeInsets` (use `AppSpacing`)
*   `Container` with `BoxDecoration` for cards (use `AppCard` or `AppSurface`)
