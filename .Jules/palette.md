## 2024-05-22 - [Explicit Required Field Indicators]
**Learning:** Users often struggle to differentiate between optional and required fields in forms without explicit indicators. Relying solely on validation errors after submission leads to frustration.
**Action:** Always mark required fields visually (e.g., with a red asterisk) to set clear expectations before interaction. This improves accessibility and reduces form submission errors.

## 2026-02-23 - [Semantics for Visual-Only Indicators]
**Learning:** Visual indicators like "+" or "-" signs for income/expense are intuitive for sighted users but may be missed or poorly announced by screen readers if they rely solely on character readout.
**Action:** Wrap such visual-only indicators in `Semantics(label: ...)` to provide explicit context (e.g., "Income of $50") rather than relying on the symbol reading.
