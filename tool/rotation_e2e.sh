#!/usr/bin/env bash
# End-to-end rotation check on a running Android emulator/device (adb).
#
# The overlay is pinned to the phone's glass: turning the phone must carry the
# shape with it, so its spot on the glass and its shape stay the same while
# the panel turns upright. Starts the overlay, rotates the display through
# every orientation and asserts the shape's on-screen rectangle matches the
# rotated glass position (within 4 px, see TOL). Needs the debug app installed
# (`flutter install -d <device>`); changes the device's rotation settings and
# restores portrait at the end.
set -euo pipefail
source "$(dirname "$0")/e2e_common.sh"

start_overlay
# Off-centre and not symmetric, so a wrong rotation cannot pass by luck.
drag_overlay -150 -500
portrait_shape=$(shape_rect)
echo "portrait (glass): $portrait_shape"

fail=0
check() { # name rotation
  adb shell settings put system user_rotation "$2"
  sleep 5
  local now want
  now=$(shape_rect)
  want=$(expected_shape "$portrait_shape" "$2")
  echo "$1: now=$now expected=$want"
  same_frame "$want" "$now" || { echo "FAIL: $1 is not where the glass says"; fail=1; }
}
check "landscape (rotation 1)" 1
check "upside down (rotation 2)" 2
check "landscape (rotation 3)" 3
check "portrait" 0
adb shell settings put system user_rotation 0
[ "$fail" -eq 0 ] && echo "PASS: the overlay stays pinned to the phone glass"
exit "$fail"
