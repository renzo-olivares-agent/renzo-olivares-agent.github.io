#!/usr/bin/env python3
"""Writes <site>/index.html, listing every published demo from its demo.json.

usage: tool/generate_index.py <site-dir>
"""

import html
import json
import pathlib
import sys

FLUTTER = "https://github.com/renzo-olivares-agent/flutter"

PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Flutter demos</title>
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font: 16px/1.5 system-ui, sans-serif; max-width: 48rem; margin: 2rem auto; padding: 0 1rem; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ text-align: left; padding: 0.4rem 1rem 0.4rem 0; border-bottom: 1px solid color-mix(in srgb, currentColor 20%, transparent); }}
  code {{ font-size: 0.85em; }}
</style>
</head>
<body>
<h1>Flutter demos</h1>
<p>The same app built against two Flutter commits: before and after a change.</p>
<table>
<tr><th>Demo</th><th>Before</th><th>After</th><th>Change</th><th>Built</th></tr>
{rows}
</table>
</body>
</html>
"""

ROW = """<tr>
<td>{name}</td>
<td><a href="{name}/before/">before</a> <a href="{flutter}/commit/{before}"><code>{before_short}</code></a></td>
<td><a href="{name}/after/">after</a> <a href="{flutter}/commit/{after}"><code>{after_short}</code></a></td>
<td><a href="{flutter}/compare/{before}...{after}">diff</a></td>
<td>{built}</td>
</tr>"""


def main():
    site = pathlib.Path(sys.argv[1])
    demos = [json.loads(path.read_text()) for path in site.glob("*/demo.json")]
    demos.sort(key=lambda demo: demo["built"], reverse=True)
    rows = "\n".join(
        ROW.format(
            flutter=FLUTTER,
            name=html.escape(demo["name"]),
            before=demo["before"],
            before_short=demo["before"][:10],
            after=demo["after"],
            after_short=demo["after"][:10],
            built=demo["built"][:10],
        )
        for demo in demos
    )
    (site / "index.html").write_text(PAGE.format(rows=rows))


if __name__ == "__main__":
    main()
