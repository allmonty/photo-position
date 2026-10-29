#!/usr/bin/env bash
# End-to-end slot check on a running Android emulator/device: position the
# real overlay, save it to slots 1 and 2, move it away, then load each slot
# and assert the overlay window returns to the saved frame (within TOL px).
# Everything finer (clamping, overwrite, persistence) is unit-tested in
# test/ui/slots_flow_test.dart.
set -euo pipefail
source "$(dirname "$0")/e2e_common.sh"

start_overlay
drag_overlay 0 -500
a=$(overlay_frame); echo "A: $a"
tap_desc "Save current position to slot 1"; sleep 2

drag_overlay 200 400
b=$(overlay_frame); echo "B: $b"
tap_desc "Save current position to slot 2"; sleep 2

drag_overlay -250 -100
tap_desc "Slot 1"; sleep 3
now=$(overlay_frame); echo "slot 1 -> $now"
same_frame "$a" "$now" || { echo "FAIL: slot 1 did not restore A"; exit 1; }

tap_desc "Slot 2"; sleep 3
now=$(overlay_frame); echo "slot 2 -> $now"
same_frame "$b" "$now" || { echo "FAIL: slot 2 did not restore B"; exit 1; }
echo "PASS: slots restore the saved overlay position"
