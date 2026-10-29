#!/usr/bin/env bash
# End-to-end rotation check on a running Android emulator/device (adb).
#
# Starts the overlay, rotates the display and asserts the overlay window keeps
# the same on-screen pixel rectangle (within 2 px). Needs the debug app
# installed (`flutter install -d <device>`); changes the device's rotation
# settings and restores portrait at the end.
set -euo pipefail

PKG=com.example.photo_position
TOL=2
tmp=$(mktemp -d)

adb shell appops set "$PKG" SYSTEM_ALERT_WINDOW allow
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell am force-stop "$PKG"
adb shell am start -n "$PKG/.MainActivity" >/dev/null
sleep 4

# Tap the START OVERLAY button, found through the accessibility tree.
adb shell uiautomator dump /sdcard/ui.xml >/dev/null
adb pull /sdcard/ui.xml "$tmp/ui.xml" >/dev/null
bounds=$(grep -o 'content-desc="START OVERLAY"[^>]*bounds="\[[0-9,]*\]\[[0-9,]*\]"' "$tmp/ui.xml" | grep -o '\[[0-9,]*\]\[[0-9,]*\]' | head -1)
[ -n "$bounds" ] || { echo "START OVERLAY button not found"; exit 1; }
read -r x1 y1 x2 y2 < <(echo "$bounds" | sed 's/\]\[/,/; s/[][]//g' | tr ',' ' ')
adb shell input tap $(((x1 + x2) / 2)) $(((y1 + y2) / 2))
sleep 8

# "l t r b" of the overlay window (the APPLICATION_OVERLAY window that is not full screen).
overlay_frame() {
  adb shell dumpsys window windows | awk -v pkg="$PKG" '
    /Window #/ { inwin = ($0 ~ "Window\\{[0-9a-f]+ u0 " pkg "\\}:") }
    inwin && /Frames:/ { match($0, /frame=\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]/); print substr($0, RSTART + 7, RLENGTH - 7); exit }
  ' | sed 's/\]\[/,/; s/[][]//g' | tr ',' ' '
}

check() { # name rotation
  adb shell settings put system user_rotation "$2"
  sleep 5
  local now
  now=$(overlay_frame)
  echo "$1: $now"
  read -ra a <<<"$before"
  read -ra b <<<"$now"
  for i in 0 1 2 3; do
    d=$((a[i] - b[i])); d=${d#-}
    [ "$d" -le "$TOL" ] || { echo "FAIL: $1 moved by ${d}px (before: $before)"; fail=1; break; }
  done
}

# The default spot (screen centre) does not fit a landscape screen, where the
# overlay is deliberately pulled into view. Drag it up so it fits both.
read -ra f <<<"$(overlay_frame)"
cx=$(((f[0] + f[2]) / 2)); cy=$(((f[1] + f[3]) / 2))
adb shell input swipe "$cx" "$cy" "$cx" $((cy - 600)) 600
sleep 2

before=$(overlay_frame)
[ -n "$before" ] || { echo "overlay window not found"; exit 1; }
echo "portrait (before): $before"
fail=0
check "landscape 90" 1
check "portrait" 0
check "landscape 270" 3
check "portrait again" 0
adb shell settings put system user_rotation 0
[ "$fail" -eq 0 ] && echo "PASS: overlay kept its pixels across rotations"
exit "$fail"
