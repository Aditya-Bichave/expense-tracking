# CodeScene setup

## Exclude generated code from analysis

CodeScene reports `server/public/main.dart.js` as an unhealthy file. It is not
source code: it is the minified `dart2js` bundle (~6 MB, ~204k lines) produced by
`flutter build web`.

There is nothing to refactor in it, and its "complexity" and churn are artifacts
of the build, not of anyone's design decisions. Left in the analysis it drags the
project's code health down and buries real findings.

Exclusions are **project configuration in the CodeScene UI** - they cannot be
committed to the repository, and `.gitattributes` does not reach CodeScene.

Set this once, under **Project Configuration -> Exclude Content**:

```
expense-tracking/server/public/**
```

Notes on the syntax:

- Paths use forward slashes and **must start with the repository root name**
  (`expense-tracking`), not with `server/`.
- `**` matches whole directory paths.

The bundle is no longer in the repository at all: `server/` was removed along with
the Render deployment it existed for, and the web bundle is now built in CI and
deployed prebuilt (see `.github/workflows/deploy_web.yml`).

The exclusion is still worth setting, because CodeScene analyses **git history**,
not just the current tree. Every revision up to that removal still contains
`server/public/main.dart.js`, so without the pattern its 204k generated lines keep
contributing churn and complexity to the analysis.

## PR refactoring agent (not enabled)

CodeScene's [PR refactoring agent](https://codescene.io/docs/developer-tools/pr-refactoring-agent.html)
was evaluated and deliberately **not** added. It requires two repository secrets
to function at all - a `CODESCENE_ACCESS_TOKEN` and an LLM provider key such as
`ANTHROPIC_API_KEY` - and we chose not to take on those credentials.

If that changes, the action is `codescene-oss/pr-refactoring-agent`, triggered
from `issue_comment`. Gate it on `github.event.comment.author_association` being
`OWNER`/`MEMBER`/`COLLABORATOR`: the event runs against the base repository with
access to those secrets, and anyone can comment on a public pull request.
