# Testing Docs

Four documents. Read them in this order; each assumes the one before it.

| Document | Answers |
| :--- | :--- |
| [COVERAGE_PLAYBOOK.md](COVERAGE_PLAYBOOK.md) | How coverage is measured here, what is in the denominator, how to project yield per file, and the traps that produce wrong numbers. |
| [TEST_AUTHORING_SPEC.md](TEST_AUTHORING_SPEC.md) | Where a test file goes, which harness to use, the assertion bar, and the determinism rules that keep the suite non-flaky. |
| [E2E_FLOW_INVENTORY.md](E2E_FLOW_INVENTORY.md) | Every user flow in the app, what covers it today, and what is still open. |
| [AGENT_PROMPT_V2.md](AGENT_PROMPT_V2.md) | The instruction to hand an AI agent for a coverage-and-stability run, plus what changed from the previous prompt and why. |

The strategy overview at [../core/TESTING.md](../core/TESTING.md) is still the
high-level statement of intent; these four are the operational detail.

## Fast path

```bash
flutter test --coverage --concurrency=8
awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{printf "%.2f%%\n", 100*lh/lf}' coverage/lcov.info
```

Worst-covered files, by absolute upside:

```bash
awk -F: '/^SF:/{f=$2} /^LF:/{lf=$2} /^LH:/{lh=$2; if(lf>0) printf "%6d %6.1f%% %s\n", lf-lh, 100*lh/lf, f}' coverage/lcov.info | sort -rn | head -40
```
