# Shared helpers for the Android end-to-end scripts. Source it; needs adb and
# the debug app installed. Changes the device's rotation settings.
PKG=com.example.photo_position
# The plugin takes whole dp for positions and the frame is parsed in px, so a
# couple of px of rounding per rotation is expected (4px ~ 1.5dp).
TOL=4
tmp=$(mktemp -d)

# Centre "x y" of the on-screen node whose content-desc is $1 (accessibility tree).
node_center() {
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null
  adb pull /sdcard/ui.xml "$tmp/ui.xml" >/dev/null 2>&1
  local b
  b=$(grep -o "content-desc=\"$1\"[^>]*bounds=\"\[[0-9,]*\]\[[0-9,]*\]\"" "$tmp/ui.xml" | grep -o '\[[0-9,]*\]\[[0-9,]*\]' | head -1)
  [ -n "$b" ] || return 1
  read -r x1 y1 x2 y2 < <(echo "$b" | sed 's/\]\[/,/; s/[][]//g' | tr ',' ' ')
  echo "$(((x1 + x2) / 2)) $(((y1 + y2) / 2))"
}

tap_desc() {
  local c
  c=$(node_center "$1") || { echo "not found on screen: $1"; exit 1; }
  # shellcheck disable=SC2086
  adb shell input tap $c
}

# "l t r b" (px) of the overlay window, parsed from dumpsys.
overlay_frame() {
  adb shell dumpsys window windows | awk -v pkg="$PKG" '
    /Window #/ { inwin = ($0 ~ "Window\\{[0-9a-f]+ u0 " pkg "\\}:") }
    inwin && /Frames:/ { match($0, /frame=\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]/); print substr($0, RSTART + 7, RLENGTH - 7); exit }
  ' | sed 's/\]\[/,/; s/[][]//g' | tr ',' ' '
}

# Fresh start in portrait with the overlay running.
start_overlay() {
  adb shell pm clear "$PKG" >/dev/null
  adb shell appops set "$PKG" SYSTEM_ALERT_WINDOW allow
  adb shell settings put system accelerometer_rotation 0
  adb shell settings put system user_rotation 0
  adb shell am start -n "$PKG/.MainActivity" >/dev/null
  sleep 6
  tap_desc "START OVERLAY"
  sleep 9
}

# Fails (exit 1) unless frames $1 and $2 ("l t r b") agree within $TOL px.
same_frame() {
  local a b d i
  read -ra a <<<"$1"
  read -ra b <<<"$2"
  for i in 0 1 2 3; do
    d=$((a[i] - b[i])); d=${d#-}
    [ "$d" -le "$TOL" ] || return 1
  done
}

# Drags the overlay by (dx, dy) px from its centre.
drag_overlay() {
  local f
  read -ra f <<<"$(overlay_frame)"
  local cx=$(((f[0] + f[2]) / 2)) cy=$(((f[1] + f[3]) / 2))
  adb shell input swipe "$cx" "$cy" $((cx + $1)) $((cy + $2)) 600
  sleep 2
}

# Pixels per dp on the device (window geometry is parsed in px).
px_per_dp() {
  adb shell wm density | grep -o '[0-9]*$' | tail -1 | awk '{printf "%.4f", $1 / 160}'
}

# Natural (portrait) screen size in px, "W H".
natural_size() {
  adb shell wm size | grep -o '[0-9]*x[0-9]*' | tail -1 | tr 'x' ' '
}

# "l t r b" (px) of the shape inside the overlay window: the window adds a
# 20dp handle margin on every side and a 60dp control panel on the right.
shape_rect() {
  local f d
  read -ra f <<<"$(overlay_frame)"
  d=$(px_per_dp)
  awk -v l="${f[0]}" -v t="${f[1]}" -v r="${f[2]}" -v b="${f[3]}" -v d="$d" \
    'BEGIN { printf "%d %d %d %d", l + 20*d, t + 20*d, r - 80*d, b - 20*d }'
}

# Where portrait shape rect $1 ("l t r b") must be after turning the phone to
# rotation $2 (Surface.ROTATION_*): the shape is pinned to the glass.
expected_shape() {
  local W H
  read -r W H <<<"$(natural_size)"
  awk -v s="$1" -v rot="$2" -v W="$W" -v H="$H" 'BEGIN {
    split(s, a, " "); l = a[1]; t = a[2]; r = a[3]; b = a[4];
    if (rot == 0) printf "%d %d %d %d", l, t, r, b;
    else if (rot == 1) printf "%d %d %d %d", t, W - r, b, W - l;
    else if (rot == 2) printf "%d %d %d %d", W - r, H - b, W - l, H - t;
    else printf "%d %d %d %d", H - b, l, H - t, r;
  }'
}
