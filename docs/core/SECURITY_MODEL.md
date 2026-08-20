# Security & Authentication Model

## Overview
Expense Tracker uses a comprehensive security model protecting data at rest, in transit, and via access control.

## 1. Authentication
*   **Provider**: Supabase Auth (JWT).
*   **Session Management**:
    *   Tokens stored in `flutter_secure_storage` (Android: EncryptedSharedPreferences, iOS: Keychain).
    *   Auto-refresh via Supabase SDK.
    *   **Web Storage & XSS Threat Model**: On Web platform, full Supabase session JWT tokens are stored in browser `localStorage`.
        *   *Risk*: `localStorage` is accessible by any JavaScript running in the same origin. An XSS vulnerability could allow an attacker to read the token and perform account takeover.
        *   *Mitigation & Blast Radius Reduction*:
            1. Sessions are explicitly cleared from `localStorage` immediately on user logout (`removePersistedSession`).
            2. Console logging of session existence or tokens in web storage adapter (`WebLocalStorage`) is strictly removed.
            3. Strict Content Security Policy (CSP) and sanitization of user-supplied content are enforced on the frontend.

## 2. Authorization (RLS)
Supabase Row Level Security (RLS) policies enforce access control at the database level.
*   **Groups**:
    *   Insert: Authenticated users.
    *   Select: Members of the group.
    *   Update: Admins of the group.
*   **Members**:
    *   Select: Members of the same group.
    *   Insert/Update: Admins.
*   **Expenses**:
    *   Select/Insert/Update: Members of the group.

## 3. Data Protection
*   **Local Storage (Hive)**:
    *   Hive boxes are encrypted using AES-256 if the device supports secure storage.
    *   Encryption keys are generated and stored securely via `flutter_secure_storage`.
    *   `HiveKeyCorruptionException` is handled by resetting secure storage and deleting corrupted boxes to prevent app lock-out.
*   **Network**:
    *   All communication over HTTPS (TLS 1.2+).
    *   Supabase API keys (Anon key) are safe to expose in client code, but Service Role keys are **strictly forbidden**.

## 4. PII Handling
*   **Logging**:
    *   `print()` is forbidden in production code.
    *   `GoRouterObserver` masks sensitive strings (PII) in navigation logs.
    *   User IDs (UUIDs) are allowed in logs for debugging but names/emails are redacted.
*   **Crash Reporting**:
    *   Ensure no PII is sent to crash reporting services (e.g., Sentry/Firebase) unless explicitly consented.
