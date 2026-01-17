## 2024-05-22 - Relaxing Form Validation for Better UX
**Learning:** Strict alphanumeric validation (regex) on title/description fields frustrates users who want to use punctuation (e.g., "Dinner w/ friends", "#123"). It's better to allow all characters and rely on basic non-empty validation for local apps.
**Action:** Default to permissive validation for free-text fields unless there's a strict technical requirement (e.g., ID generation).
