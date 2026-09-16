#!/usr/bin/env bash
#
# Prints the UDID of a simulator this project can actually build for.
#
# Device names are a bad thing to hardcode in CI: runner images rotate them,
# and this project sets IPHONEOS_DEPLOYMENT_TARGET = 26.0, so a runner whose
# newest runtime is older than that has no usable simulator at all. Asking
# xcodebuild what it is willing to build for avoids guessing on both counts,
# and failing here — loudly, with the runtime list attached — is much easier
# to read than the destination error xcodebuild emits later.
set -euo pipefail

PROJECT="${1:?usage: pick-destination.sh <project> <scheme>}"
SCHEME="${2:?usage: pick-destination.sh <project> <scheme>}"

raw="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>&1 || true)"

# Entries look like:
#   { platform:iOS Simulator, id:D1B2..., OS:26.0, name:iPhone 17 }
# The generic entry carries a placeholder id and cannot be booted.
udid="$(printf '%s\n' "$raw" \
  | grep 'platform:iOS Simulator' \
  | grep -vi 'placeholder' \
  | sed -n 's/.*id:\([^,}]*\).*/\1/p' \
  | head -1 \
  | tr -d '[:space:]')"

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

printf '%s\n' "$udid"
