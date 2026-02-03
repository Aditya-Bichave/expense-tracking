## 2026-02-03 - Rich Empty State Pattern
**Learning:** Empty states are high-visibility areas. Standard `Column(Icon, Text)` is too plain and lacks semantic grouping.
**Action:** Use a standardized "Rich Empty State" pattern: `Card` wrapper -> `Semantics(container: true, label: ...)` -> `Padding` -> `Column(CircleIcon, Title, Subtitle, FilledButton.tonal)`. This improves visual hierarchy and screen reader experience.
