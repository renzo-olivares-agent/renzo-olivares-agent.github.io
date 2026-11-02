#!/usr/bin/env bash
# Scaffolds a new demo app in demos/<name>.
#
# usage: tool/new_demo.sh [name]
#
# With no name, uses the next free demo-NN.
set -euo pipefail

cd "$(dirname "$0")/.."

name=${1:-}
if [[ -z $name ]]; then
  last=$(ls demos 2>/dev/null | sed -n 's/^demo-\([0-9][0-9]*\)$/\1/p' | sort -n | tail -1)
  name=$(printf 'demo-%02d' $((10#${last:-0} + 1)))
fi
[[ ! -e demos/$name ]] || {
  echo "error: demos/$name already exists" >&2
  exit 1
}

flutter create --empty --platforms web --project-name "${name//-/_}" "demos/$name"

# `flutter create` requires the Dart SDK of the Flutter that ran it, which the
# "before" build is usually older than. Accept any build of this Dart minor.
sed -i.bak -E 's/^(  sdk: \^[0-9]+\.[0-9]+)\..*/\1.0-0/' "demos/$name/pubspec.yaml"
rm "demos/$name/pubspec.yaml.bak" "demos/$name/pubspec.lock"

echo
echo "Created demos/$name. Edit demos/$name/lib/main.dart, push, then run:"
echo "  gh workflow run publish-demo.yml -f demo=$name -f after=<PR number>"
