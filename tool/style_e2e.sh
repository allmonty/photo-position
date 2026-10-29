#!/usr/bin/env bash
# End-to-end border style check on a running Android emulator/device (adb):
# picking a border colour on the home screen recolours the running overlay at
# once, and the choice is still there after stopping and starting it.
set -euo pipefail
source "$(dirname "$0")/e2e_common.sh"

start_overlay
drag_overlay -100 -600 # clear of the Stop button, which the overlay would cover
frame=$(overlay_frame)
assert_border_drawn "$frame" || { echo "FAIL: default gold border not drawn"; exit 1; }

# The colour swatches are further down the home screen.
adb shell input swipe 540 1800 540 700 400; sleep 1
tap_desc "Border color ffff3b30"; sleep 3
assert_border_drawn "$frame" ff3b30 || { echo "FAIL: running overlay did not turn red"; exit 1; }
echo "live change: ok"

adb shell input swipe 540 700 540 1800 400; sleep 1
tap_desc "STOP OVERLAY"; sleep 4
tap_desc "START OVERLAY"; sleep 9
now=$(overlay_frame)
assert_border_drawn "$now" ff3b30 || { echo "FAIL: red border lost after restart"; exit 1; }
echo "PASS: border colour applies live and is remembered"
