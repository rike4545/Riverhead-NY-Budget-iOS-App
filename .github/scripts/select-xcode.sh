#!/usr/bin/env bash
#
# Selects the newest installed Xcode and warms it up.
#
# Both jobs run this so they behave identically. They did not before, and the
# difference caused a real failure: the unit job happened to run
# `xcodebuild -showsdks` after xcode-select, which warms the toolchain, while
# the UI job went straight to `-showdestinations` on a freshly selected Xcode
# and got an empty destination list after hanging 32 seconds — on a runner that
# had iOS 26.2, 26.4 and 26.5 runtimes installed the whole time.
set -euo pipefail

newest="$(ls -d /Applications/Xcode*.app | sort -V | tail -1)"
echo "Selecting $newest"
sudo xcode-select -s "$newest"
xcodebuild -version

echo "--- iOS SDKs ---"
xcodebuild -showsdks 2>/dev/null | grep -i ios || echo "(no iOS SDK reported)"

echo "--- simulator runtimes ---"
xcrun simctl list runtimes 2>&1 | grep -i '^iOS' || echo "(no iOS runtime reported)"

# Forces CoreSimulator to start and build its device list before any build
# command depends on it.
xcrun simctl list devices >/dev/null 2>&1 || true
