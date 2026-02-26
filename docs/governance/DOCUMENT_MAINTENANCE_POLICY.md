# Document Maintenance Policy

## Purpose
To prevent documentation drift and ensure AI agents (Jules) have accurate instructions.

## 1. Update Triggers
Documentation **must** be updated when:

| Trigger | Document(s) to Update | Responsible |
| :--- | :--- | :--- |
| **New Feature** | `docs/core/ARCHITECTURE.md`, `docs/governance/DOMAIN_MODEL.md` | Developer/AI |
| **New Dependency** | `pubspec.yaml`, `JULES_ENV_SETUP.md` (if system dep) | Developer |
| **CI/CD Change** | `docs/core/CI_CD.md`, `.github/workflows/` | DevOps/Lead |
| **Policy Change** | `AGENTS.md`, `docs/governance/*` | Architect |
| **New Risk Found**| `docs/governance/RISK_REGISTER.md`, `docs/core/KNOWN_PITFALLS.md` | Discoverer |

## 2. Review Cycle
*   **Monthly**: Review `AGENTS.md` for relevance.
*   **Quarterly**: Review `docs/governance/RISK_REGISTER.md` and `docs/governance/ASSUMPTIONS_REGISTER.md`.

## 3. Conflict Resolution
If a discrepancy is found between Code and Documentation:
1.  **Immediate Action**: Trust the **Code** (it executes).
2.  **Correction**: File a `TODO` or Issue to update the **Documentation** to match the Code (or vice-versa if the Code is wrong).
3.  **Forbidden**: Do not leave the discrepancy unresolved.

## 4. AI-Specific Rules
*   If an AI agent discovers a contradiction, it **must** log it in `docs/governance/RISK_REGISTER.md` or ask for clarification.
*   AI agents are encouraged to suggest documentation updates when modifying code.
