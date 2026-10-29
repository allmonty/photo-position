#!/usr/bin/env bash
# End-to-end rotation check on a running Android emulator/device (adb).
#
# Starts the overlay, rotates the display and asserts the overlay window keeps
# the same on-screen pixel rectangle (within 2 px). Needs the debug app
# installed (`flutter install -d <device>`); changes the device's rotation
# settings and restores portrait at the end.
set -euo pipefail
source "$(dirname "$0")/e2e_common.sh"

start_overlay
# The default spot (screen centre) does not fit a landscape screen, where the
# overlay is deliberately pulled into view. Drag it up so it fits both.
drag_overlay 0 -600
before=$(overlay_frame)
[ -n "$before" ] || { echo "overlay window not found"; exit 1; }
echo "portrait (before): $before"

fail=0
check() { # name rotation
  adb shell settings put system user_rotation "$2"
  sleep 5
  local now
  now=$(overlay_frame)
  echo "$1: $now"
  same_frame "$before" "$now" || { echo "FAIL: $1 moved (before: $before)"; fail=1; }
}
check "landscape 90" 1
check "portrait" 0
check "landscape 270" 3
check "portrait again" 0
adb shell settings put system user_rotation 0
[ "$fail" -eq 0 ] && echo "PASS: overlay kept its pixels across rotations"
exit "$fail"
