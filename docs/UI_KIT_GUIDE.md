# UI Kit Guide

This repository now includes a centralized UI Kit in `lib/ui_kit/`.
The goal is to standardize UI patterns and tokens to facilitate easier theming and maintenance.

## Golden Rules
1. **Do NOT use `Colors.red` or `Color(0xFF...)` directly.** Use `context.kit.colors.error` or semantic tokens.
2. **Do NOT use `TextStyle(fontSize: 16)` directly.** Use `context.kit.typography.bodyLarge`.
3. **Do NOT hardcode paddings like `EdgeInsets.all(16)`.** Use `context.kit.spacing.allMd`.
4. **Prefer `App*` components over standard Flutter widgets.**
   - `AppCard` instead of `Card` or `Container` with decoration.
   - `AppButton` instead of `ElevatedButton` / `OutlinedButton`.
   - `AppTextField` instead of `TextFormField`.
   - `AppListTile` instead of `ListTile`.

## Accessing Tokens
The UI Kit exposes a `kit` extension on `BuildContext`:
```dart
final kit = context.kit;

Color bg = kit.colors.background;
EdgeInsets padding = kit.spacing.allMd;
TextStyle style = kit.typography.titleLarge;
```

## Component Migration Examples

### Buttons
**Old:**
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
  child: Text("Save"),
)
```

**New:**
```dart
AppButton(
  label: "Save",
  onPressed: () {},
  variant: AppButtonVariant.primary,
)
```

### Text Fields
**Old:**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: "Name",
    border: OutlineInputBorder(),
  ),
)
```

**New:**
```dart
AppTextField(
  label: "Name",
)
```

### Cards
**Old:**
```dart
Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(padding: EdgeInsets.all(16), child: ...),
)
```

**New:**
```dart
AppCard(
  child: ...,
)
```

## Migration Plan

### Wave 1 (Done)
- UI Kit structure created.
- Tokens defined.
- Core components (`AppButton`, `AppCard`, `AppTextField`, `AppListTile`) created.
- Migrated: `TransactionListItem` and `LogContributionSheet`.

### Wave 2 (Next Steps)
- Migrate `AddExpenseWizard` screens (high complexity).
- Migrate `GoalDetailPage` and `BudgetDetailPage`.
- Replace all `ElevatedButton` usages in `lib/features/`.

### Wave 3
- Migrate Settings screens.
- Migrate Dashboard charts styling to use tokens.
- Deprecate `lib/core/widgets/` where redundant.

## Structure
- `lib/ui_kit/tokens/`: Atomic values (colors, spacing, typography).
- `lib/ui_kit/theme/`: Theme extensions and configuration.
- `lib/ui_kit/components/`: Reusable widgets.
