#!/usr/bin/env bash
# Builds demos/<demo> for the web against Flutter at <flutter-sha>.
#
# usage: tool/build_demo.sh <demo> <flutter-sha> <base-href> <out-dir> [flutter build web args...]
#
# Flutter checkouts are kept in $FLUTTER_DEMO_SDKS (default: $TMPDIR/flutter-demo-sdks),
# one per commit, so rebuilding a demo locally doesn't set the SDK up again.
set -euo pipefail

[[ $# -ge 4 ]] || {
  echo "usage: $0 <demo> <flutter-sha> <base-href> <out-dir> [flutter build web args...]" >&2
  exit 1
}
demo=$1 sha=$2 base_href=$3 out=$4
shift 4

root=$(cd "$(dirname "$0")/.." && pwd)
sdk=${FLUTTER_DEMO_SDKS:-${TMPDIR:-/tmp}/flutter-demo-sdks}/$sha
mkdir -p "$out"
out=$(cd "$out" && pwd)

exists() {
  curl --fail --silent --head --retry 3 --output /dev/null "$1"
}

if [[ ! -d $sdk/.git ]]; then
  # Blobless rather than shallow: Flutter derives its version from tags in the
  # history, and without one pub rejects any package that has a Flutter SDK
  # constraint.
  git clone --quiet --filter=blob:none --no-checkout https://github.com/flutter/flutter.git "$sdk"
fi
# Fetching by SHA from flutter/flutter also reaches PR and fork commits.
git -C "$sdk" cat-file -e "$sha^{commit}" 2>/dev/null || git -C "$sdk" fetch --quiet origin "$sha"

# Flutter picks its prebuilt engine by hashing DEPS and engine/. On any branch
# not named like a release branch it hashes the merge-base with master instead
# of HEAD, which would silently build a PR commit against the unpatched engine.
git -C "$sdk" checkout --quiet -B master "$sha"
engine=$("$sdk/bin/internal/content_aware_hash.sh")

storage=https://storage.googleapis.com
if ! exists "$storage/flutter_infra_release/flutter/$engine/flutter-web-sdk.zip"; then
  # Not an engine that was built from master, so this should be a PR commit
  # that changes the engine. PR presubmit builds are uploaded to a separate
  # bucket, keyed by commit instead of content hash.
  if ! exists "$storage/flutter_archives_v2/flutter_infra_release/flutter/$sha/flutter-web-sdk.zip"; then
    echo "error: no prebuilt engine for Flutter $sha (engine hash $engine)." >&2
    echo "If this commit changes engine/, it needs to be the head of a flutter/flutter PR" >&2
    echo "whose engine presubmit builds have finished." >&2
    exit 1
  fi
  export FLUTTER_PREBUILT_ENGINE_VERSION=$sha FLUTTER_REALM=flutter_archives_v2
  engine=$sha
fi

export PATH="$sdk/bin:$PATH"
flutter --version

args=(--base-href "$base_href")
# CanvasKit is loaded from Google's CDN by default, but the CDN only carries
# engines built from master.
cdn=true
revision=$(flutter --version --machine | sed -n 's/.*"engineRevision": "\([0-9a-f]*\)".*/\1/p')
if ! exists "https://www.gstatic.com/flutter-canvaskit/$revision/canvaskit.wasm"; then
  cdn=false
  args+=(--no-web-resources-cdn)
fi

cd "$root/demos/$demo"
rm -rf build .dart_tool
flutter build web "${args[@]}" "$@"

# Trim the bundled renderers down to what the page can load. They are most of
# a build's size, and GitHub Pages sites are limited to 1 GB.
cd build/web
if $cdn; then
  rm -rf canvaskit
else
  find canvaskit -name '*.symbols' -delete
  [[ " $* " == *" --wasm "* ]] || rm -f canvaskit/skwasm* canvaskit/wimp*
fi

rm -rf "$out"
cp -R . "$out"
echo "Built $demo against Flutter $sha (engine $engine) into $out"
