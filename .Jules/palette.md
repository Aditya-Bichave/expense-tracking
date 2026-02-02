## 2024-05-22 - Default Name Validation too Restrictive
**Learning:** `CommonFormFields.buildNameField` enforced alphanumeric-only validation by default, which is poor UX for user-generated content like transaction titles where punctuation is common.
**Action:** Review centralized form field builders for overly restrictive default validators; prefer permissive validation (checking only for emptiness) for general text fields.
