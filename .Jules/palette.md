## 2024-05-23 - Restrictive Transaction Titles
**Learning:** Default "alphanumeric only" validation on transaction titles blocks valid real-world inputs like "Ben & Jerry's", "Rent (July)", or "T-Mobile". This creates significant friction for users trying to record normal expenses.
**Action:** When building text input fields for names or descriptions, default to permissive validation (non-empty) and only add restrictions if technically required (e.g. IDs) or strictly business-logic driven.
