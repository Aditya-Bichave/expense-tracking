# UI Kit Tokens

Tokens are the atoms of the design system. Access them via `context.kit`.

## Colors (`AppColors`)
Access via `context.kit.colors`.
- **bg**: Main background.
- **surfaceContainer**: Secondary background.
- **card**: Card background.
- **elevated**: Dialogs/Sheets.
- **primary**: Brand color.
- **textPrimary / textSecondary / textMuted**: Text hierarchy.
- **border / borderSubtle**: Dividers and borders.
- **success / warn / danger**: Semantic states.

## Spacing (`AppSpacing`)
Access via `context.kit.spacing`.
- **xxs**: 2
- **xs**: 4
- **sm**: 8
- **md**: 12
- **lg**: 16
- **xl**: 20
- **xxl**: 24
- **xxxl**: 32
- **xxxxl**: 40 (implied, custom)

Helpers: `gapMd` (SizedBox), `allMd` (EdgeInsets).

## Radii (`AppRadii`)
Access via `context.kit.radii`.
- **xs**: 4
- **sm**: 8
- **md**: 12
- **lg**: 16
- **xl**: 24
- **full**: 999 (Circular)

Semantic: `card` (md), `button` (md), `sheet` (lg top), `chip` (full).

## Typography (`AppTypography`)
Access via `context.kit.typography`.
- **display**: Huge headers.
- **title**: Screen titles.
- **headline**: Section headers.
- **body**: Default text.
- **bodyStrong**: Bold body.
- **caption**: Small text.
- **overline**: ALL CAPS LABELS.

## Motion (`AppMotion`)
Access via `context.kit.motion`.
- **fast / normal / slow**: Durations.
- **standard / emphasized / overshoot**: Curves.

## Shadows (`AppShadows`)
Access via `context.kit.shadows`.
- **sm / md / lg**: Elevation levels (adjusted for light/dark mode).
- **glow**: Subtle glow for dark mode.
