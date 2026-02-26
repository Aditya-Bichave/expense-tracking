# Assumptions Register

## User Environment
1.  **Internet Access**: User has intermittent internet connectivity.
    *   **Implication**: Local-first (Hive) is critical. Sync happens when online.
2.  **Device Storage**: Modern smartphones have sufficient storage for local financial data (100MB+ for Hive).
    *   **Implication**: We cache extensively.
3.  **Supabase Auth**: User is comfortable authenticating via email/password or OAuth.

## Backend Dependencies
1.  **Supabase Availability**: Supabase provides stable uptime and API access.
    *   **Implication**: If Supabase is down, app works offline but sync fails.
2.  **Edge Functions**: Supabase Edge Functions are deployed and handle complex backend logic (e.g., invites).
    *   **Implication**: We rely on backend validation for invites/RBAC.

## Development Environment
1.  **Flutter Version**: 3.22.2 or later (Stable).
    *   **Implication**: `setup.sh` installs this specific version.
2.  **OS**: CI runs on Linux (Ubuntu). Developers may use macOS/Windows.
    *   **Implication**: Golden tests generated on Linux are the baseline. macOS/Windows devs must use Docker or tolerate diffs.
3.  **Secrets**: API keys (Anon key) are safe to expose in client code, but Service Role keys are strictly forbidden.
