#!/usr/bin/env bash
# End-to-end stop/start check on a running Android emulator/device (adb).
#
# The overlay's Flutter engine outlives its window, so stopping the overlay
# and starting it again must bring it back at the position it was stopped at
# and still working (this used to leave a frozen overlay stuck in a corner).
# Stops and starts twice, checking the window frame and the drawn border.
set -euo pipefail
source "$(dirname "$0")/e2e_common.sh"

start_overlay
drag_overlay -100 -600 # clear of the Stop button, which the overlay would cover
saved=$(overlay_frame)
echo "running at: $saved"

for round in 1 2; do
  tap_desc "STOP OVERLAY"; sleep 4
  [ -z "$(overlay_frame)" ] || { echo "FAIL: window still there after stop (round $round)"; exit 1; }

  tap_desc "START OVERLAY"; sleep 9
  now=$(overlay_frame)
  echo "round $round restarted at: $now"
  [ -n "$now" ] || { echo "FAIL: no overlay window after restart (round $round)"; exit 1; }
  same_frame "$saved" "$now" || { echo "FAIL: restarted somewhere else (round $round)"; exit 1; }
  assert_border_drawn "$now" || { echo "FAIL: restarted overlay shows no shape (round $round)"; exit 1; }
done

# Still alive: it must follow a drag after the restarts.
drag_overlay 0 200
moved=$(overlay_frame)
same_frame "$saved" "$moved" && { echo "FAIL: overlay does not react after restart"; exit 1; }
echo "PASS: stop and start works repeatedly and the overlay stays usable"
