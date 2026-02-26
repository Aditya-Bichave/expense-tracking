# UI Kit Component Catalog

This catalog lists available components in `lib/ui_kit/components/`. Use the Showcase Page (`/ui-kit` route) to view them live.

## Foundations (`lib/ui_kit/components/foundations/`)
- **AppScaffold**: Standard page wrapper with SafeArea and background color handling.
- **AppNavBar**: Standard AppBar wrapper.
- **AppSection**: Layout helper for titled sections.
- **AppDivider**: Tokenized divider.
- **AppGap**: Spacing helpers (though `context.kit.spacing.gapX` is preferred).
- **AppSafeArea**: Wrapper for SafeArea.
- **AppCard**: Standard container for grouped content. Supports `glass` mode.
- **AppSurface**: Generic background container.
- **AppChip**: Selectable or action chip.
- **AppBadge**: Status indicator (primary, success, warn, error).

## Typography (`lib/ui_kit/components/typography/`)
- **AppText**: Main text widget with semantic styles (`display`, `title`, `headline`, `body`, etc.).
- **AppLinkText**: Tappable inline link.

## Inputs (`lib/ui_kit/components/inputs/`)
- **AppTextField**: Standard text input with label, hint, error.
- **AppSearchField**: Specialized search input.
- **AppDropdown**: Selection input.
- **AppSwitch**: Toggle switch (Cupertino style).
- **AppSegmentedControl**: Tab-like selection.
- **AppCheckbox**: Boolean selection.
- **AppDatePickerField**: Date selection input.

## Buttons (`lib/ui_kit/components/buttons/`)
- **AppButton**: Primary, Secondary, Ghost, Destructive variants. Supports loading state.
- **AppIconButton**: Icon-only button.
- **AppFAB**: Floating Action Button (standard & extended).

## Lists (`lib/ui_kit/components/lists/`)
- **AppListTile**: Standard list item with leading/trailing widgets.
- **AppGroupCard**: Card wrapper for a list of items (iOS settings style).
- **AppAvatar**: User image or initials.
- **AppStatTile**: Key-value display for dashboards.

## Feedback (`lib/ui_kit/components/feedback/`)
- **AppBottomSheet**: Modal sheet wrapper. Use `AppBottomSheet.show(context, ...)`.
- **AppDialog**: Alert/Confirm dialog. Use `AppDialog.show(context, ...)`.
- **AppToast**: SnackBar helper. Use `AppToast.show(context, ...)`.
- **AppBanner**: Inline message (info, success, warning, error).
- **AppTooltip**: Tooltip wrapper.

## Loading (`lib/ui_kit/components/loading/`)
- **AppSkeleton**: Shimmer placeholder.
- **AppLoadingIndicator**: Circular spinner.
- **AppEmptyState**: Placeholder for empty lists/data.

## Charts (`lib/ui_kit/components/charts/`)
- **AppChartCard**: Wrapper for charts with title and empty state handling.

## Animation (`lib/ui_kit/components/animation/`)
- **AppFadeScale**: Entrance animation.
- **AppSlideFade**: Entrance animation with slide.
- **AppPageTransition**: Route transition helper.
