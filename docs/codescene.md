# CodeScene setup

## 1. Exclude generated code from analysis

CodeScene reports `server/public/main.dart.js` as an unhealthy file. It is not
source code: it is the minified `dart2js` bundle (~6 MB, ~204k lines) produced by
`flutter build web`, committed by `.github/workflows/deploy_web.yml` because
`vercel.json` sets `outputDirectory: server/public` and Vercel deploys straight
from the repository.

There is nothing to refactor in it, and its "complexity" and churn are artifacts
of the build, not of anyone's design decisions. Left in the analysis it drags the
project's code health down and buries real findings.

Exclusions are **project configuration in the CodeScene UI** — they cannot be
committed to the repository, and `.gitattributes` does not reach CodeScene.

Set this once, under **Project Configuration → Exclude Content**:

```
expense-tracking/server/public/**
```

Notes on the syntax:

- Paths use forward slashes and **must start with the repository root name**
  (`expense-tracking`), not with `server/`.
- `**` matches whole directory paths.

The repository side of this is already handled: `.gitattributes` marks
`server/public/**` as `linguist-generated` and `-diff`, so GitHub keeps it out of
language stats and collapses it in pull requests instead of rendering a 6 MB
diff.

## 2. PR refactoring agent

`.github/workflows/codescene-refactor.yml` runs
[codescene-oss/pr-refactoring-agent](https://github.com/codescene-oss/pr-refactoring-agent).
It is **on-demand**: comment `/cs-agent` on a pull request and it proposes
refactorings for the code-health issues CodeScene found there, pushing them as
commits to the PR branch.

### Required repository secrets

| Secret | Purpose |
| --- | --- |
| `CODESCENE_ACCESS_TOKEN` | CodeScene Cloud (or on-prem) personal access token, so the agent can read the PR's code-health findings |
| `ANTHROPIC_API_KEY` | LLM used to generate the refactorings |

The agent also accepts `OPENAI_API_KEY`, `GOOGLE_API_KEY`, or
`OPENCODE_AUTH_JSON` instead of `ANTHROPIC_API_KEY`; change the `model:` input to
match if you switch provider.

### Who can trigger it

Only commenters whose `author_association` is `OWNER`, `MEMBER`, or
`COLLABORATOR`. This is deliberate. The `issue_comment` event runs in the context
of the base repository with access to the secrets above, so without that gate any
account able to comment on a pull request could spend the LLM budget and push
commits onto a branch under review.

### Model choice

CodeScene's guidance is to use the strongest coding-focused model available to
you — the agent's output quality tracks the model directly. Bump the `model:`
input when a stronger model is approved for the org.
