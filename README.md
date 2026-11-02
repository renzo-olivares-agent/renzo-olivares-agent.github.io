# Flutter before/after demos

Live web demos for the coder team's fixes in
[renzo-olivares-agent/flutter](https://github.com/renzo-olivares-agent/flutter). Each demo is one
small app built twice, against Flutter before and after a fix, and published to GitHub Pages:

    https://renzo-olivares-agent.github.io/issue-<n>/before/
    https://renzo-olivares-agent.github.io/issue-<n>/after/

The app's code is identical in both builds. Only the Flutter commit differs. `<n>` is the
flutter/flutter issue number, written as plain digits.

The coder team's publisher bot adds demos here (see `bots/coder-team/publisher/` in
renzo-olivares-agent/bots). Demos are a lasting record: none is deleted unless Renzo says so.

## Publishing a demo

1. Put the app in `demos/issue-<n>/` and push it to `main`. The publisher does this with
   `ct demo --main main.dart`; by hand, `tool/new_demo.sh issue-<n>` scaffolds one.

2. Run the workflow, from the Actions tab or with:

       gh workflow run publish-demo.yml -f demo=issue-<n> \
         -f after=renzo-olivares-agent:<head sha> -f before=renzo-olivares-agent:<base sha>

   The run summary has the two links.

Running the workflow again for the same demo replaces that demo. Everything else on the site stays as
published.

### Choosing the Flutter commits

`after` (required) and `before` (optional) each take any of:

| Input | Meaning |
| --- | --- |
| A flutter/flutter PR number or URL | Its head commit while open, its merge commit once merged |
| `owner:branch` or `owner:sha` | A branch or commit on a fork |
| anything else | A SHA, branch, or tag in flutter/flutter |

Refs are resolved to commit SHAs when the workflow starts, so each demo corresponds to exact commits,
listed on the site's index page. Without `before`, the baseline is the commit `after` forked from
master.

### Changes to the engine

Nothing here compiles the engine; Flutter downloads a prebuilt one. A fork commit that changes
`engine/` can't be built, so the team's fixes stay in the framework.
