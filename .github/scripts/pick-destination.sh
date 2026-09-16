#!/usr/bin/env bash
#
# Prints the UDID of a simulator this project can actually build for, and
# reports the full destination line on stderr so the job log records which
# device and runtime the run actually used.
#
# Device names are a bad thing to hardcode in CI: runner images rotate them,
# and this project sets IPHONEOS_DEPLOYMENT_TARGET = 26.0, so a runner whose
# newest runtime is older than that has no usable simulator at all. Asking
# xcodebuild what it is willing to build for avoids guessing on both counts.
#
# iPhone is preferred deliberately. The UI tests assert on a phone layout, and
# a silent fall back to an iPad would change the tab bar out from under them.
set -euo pipefail

PROJECT="${1:?usage: pick-destination.sh <project> <scheme>}"
SCHEME="${2:?usage: pick-destination.sh <project> <scheme>}"

raw="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>&1 || true)"

# Entries look like:
#   { platform:iOS Simulator, id:D1B2..., OS:26.0, name:iPhone 17 }
# The generic entry carries a placeholder id and cannot be booted.
sims="$(printf '%s\n' "$raw" \
  | grep 'platform:iOS Simulator' \
  | grep -vi 'placeholder' || true)"

# `|| true` matters: with `set -e` and `pipefail`, a grep that matches nothing
# fails the whole substitution and aborts the script, so the fallback below
# could never run on a runner that had simulators but no iPhone.
line="$(printf '%s\n' "$sims" | grep 'name:iPhone' | head -1 || true)"
[ -n "$line" ] || line="$(printf '%s\n' "$sims" | head -1 || true)"

udid="$(printf '%s\n' "$line" | sed -n 's/.*id:\([^,}]*\).*/\1/p' | head -1 | tr -d '[:space:]')"

if [ -z "$udid" ]; then
  {
    echo "No bootable iOS Simulator destination for scheme '$SCHEME'."
    echo
    echo "--- xcodebuild -showdestinations ---"
    printf '%s\n' "$raw"
    echo "--- installed Xcodes ---"
    ls -d /Applications/Xcode*.app 2>/dev/null || echo "(none)"
    echo "--- simulator runtimes ---"
    xcrun simctl list runtimes 2>&1 || true
  } >&2
  exit 1
fi

echo "Chosen destination:$(printf '%s' "$line" | sed 's/^[[:space:]]*//')" >&2
printf '%s\n' "$udid"
