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

The repository side is already handled: `.gitattributes` marks `server/public/**`
as `linguist-generated` and `-diff`, so GitHub keeps it out of language stats and
collapses it in pull requests instead of rendering a 6 MB diff.

Note that `server/public/` is no longer committed - the web bundle is built in
CI and deployed prebuilt (see `.github/workflows/deploy_web.yml`). The
`.gitattributes` entry and this exclusion are kept so that historical revisions,
which still contain the bundle, do not skew the analysis.

## PR refactoring agent (not enabled)

CodeScene's [PR refactoring agent](https://codescene.io/docs/developer-tools/pr-refactoring-agent.html)
was evaluated and deliberately **not** added. It requires two repository secrets
to function at all - a `CODESCENE_ACCESS_TOKEN` and an LLM provider key such as
`ANTHROPIC_API_KEY` - and we chose not to take on those credentials.

If that changes, the action is `codescene-oss/pr-refactoring-agent`, triggered
from `issue_comment`. Gate it on `github.event.comment.author_association` being
`OWNER`/`MEMBER`/`COLLABORATOR`: the event runs against the base repository with
access to those secrets, and anyone can comment on a public pull request.
