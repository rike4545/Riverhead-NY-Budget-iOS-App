#!/bin/bash
# Boots the chosen simulator and blocks until it is actually ready.
#
# Without this, `xcodebuild test` boots the device as a side effect and then
# immediately attempts the first app launch, which competes with the device's
# own first-boot work. XCUITest allows an app launch 60 seconds, and run 32
# spent all 60 of them inside a single "Launch Me.Riverhead-NY-Budget-App":
#
#     t =     1.28s     Launch Me.Riverhead-NY-Budget-App
#     error: ... Timed out while launching application via Xcode.
#     t =    61.69s Tear Down
#
# Every launch after that one took under four seconds, including four more in
# the launch-screen suite, so the binary was fine — the device was not up yet.
# testLaunchPerformance sorts first in the bundle, so it absorbed the cost.
#
# Both jobs call this. The two have diverged once before: the unit job warmed
# Xcode and the UI job did not, and the UI job then read an empty destination
# list from a cold CoreSimulator. Asymmetry between them is the recurring bug.
set -euo pipefail

udid="${1:?usage: boot-simulator.sh <udid>}"

echo "Booting simulator $udid"

# -b boots the device when it is shut down and then waits for boot to finish,
# which is the part that was missing. Already-booted is success, not an error.
if ! xcrun simctl bootstatus "$udid" -b; then
    echo "::warning::bootstatus did not report a clean boot for $udid; continuing so xcodebuild reports the real error"
fi

# Recorded so a future red run has the device's state in the log rather than
# needing a re-run to find out.
echo "Device state after boot:"
xcrun simctl list devices | grep -- "$udid" || echo "  (udid not found in simctl list)"
