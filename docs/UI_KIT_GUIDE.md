# UI Kit Guide

This UI Kit (Design System) is the new standard for building UI in the Financial OS app. It isolates design decisions (colors, spacing, typography) from implementation details, allowing for centralized theming and future redesigns (e.g., iOS-cozy premium look).

## Golden Rules

1.  **No `Colors.*` in Feature UI**: Never use raw colors like `Colors.blue` or `Color(0xFF...)`. Use `context.kit.colors.primary` or semantic tokens like `context.kit.colors.success`.
2.  **No `TextStyle(...)` in Feature UI**: Do not manually construct TextStyles. Use `AppText` with a style enum, or `context.kit.typography.body`.
3.  **No `EdgeInsets(...)` Magic Numbers**: Use `context.kit.spacing.allMd`, `hMd`, or `AppGap`.
4.  **Use Components First**: Before building a custom widget, check `UI_KIT_CATALOG.md`. Use `AppCard`, `AppButton`, `AppTextField`, etc.
5.  **Theme Extension**: Access all tokens via `context.kit`.

## Migration Strategy

Do **NOT** refactor existing features all at once. Migrate screen-by-screen or component-by-component.

1.  **Identify a Screen**: Pick a screen to migrate (e.g., Settings).
2.  **Replace Scaffold**: Use `AppScaffold`.
3.  **Replace Layouts**: Use `AppSection`, `AppGap`.
4.  **Replace Primitives**: Swap `Card` for `AppCard`, `Text` for `AppText`, `ElevatedButton` for `AppButton`.
5.  **Verify**: Check Light and Dark mode.

## Do's and Don'ts

**DO:**
```dart
AppCard(
  child: Column(
    children: [
      AppText('Hello', style: AppTextStyle.title),
      context.kit.spacing.gapMd,
      AppButton(label: 'Click Me', onPressed: () {}),
    ],
  ),
)
```

**DON'T:**
```dart
Card(
  color: Colors.white,
  child: Column(
    children: [
      Text('Hello', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: 16),
      ElevatedButton(child: Text('Click Me'), onPressed: () {}),
    ],
  ),
)
```
