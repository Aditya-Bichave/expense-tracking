## 2024-05-22 - [Explicit Required Field Indicators]

**Learning:** Users often struggle to differentiate between optional and required fields in forms without explicit indicators. Relying solely on validation errors after submission leads to frustration.
**Action:** Always mark required fields visually (e.g., with a red asterisk) to set clear expectations before interaction. This improves accessibility and reduces form submission errors.

## 2026-02-23 - [Semantics for Visual-Only Indicators]

**Learning:** Visual indicators like "+" or "-" signs for income/expense are intuitive for sighted users but may be missed or poorly announced by screen readers if they rely solely on character readout.
**Action:** Wrap such visual-only indicators in `Semantics(label: ...)` to provide explicit context (e.g., "Income of $50") rather than relying on the symbol reading.

## 2026-02-23 - [Smart Dialog Autofocus]

**Learning:** Users often open search or input dialogs with the intent to type immediately. Requiring an extra tap to focus the field breaks flow.
**Action:** Use `autofocus: true` on primary input fields in dialogs (e.g., search bars, confirmation inputs) to reduce friction.

## 2026-02-23 - [Accessible Ripple Feedback]

**Learning:** `GestureDetector` captures taps but offers no visual feedback, leaving users unsure if their interaction registered.
**Action:** Prefer `InkWell` (wrapped in `Material`) for touchable areas. It provides a standard ripple effect that confirms interaction and enhances perceived responsiveness. Ensure `borderRadius` matches the container.
