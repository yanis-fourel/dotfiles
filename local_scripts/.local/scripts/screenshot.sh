#!/bin/bash

# Take a screenshot of the whole screen, a specific window, or a user-drawn region.
# Saves to ~/Pictures

OUTPUT_DIR="$HOME/Pictures"

FILENAME="screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
FILEPATH="$OUTPUT_DIR/$FILENAME"

if [[ ! -d $OUTPUT_DIR ]]; then
  notify-send "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  exit 1
fi

pkill slurp && exit 0


hyprpicker -r -z >/dev/null 2>&1 &
PID=$!
trap 'kill "$PID" 2>/dev/null || true' EXIT
sleep .1
SELECTION=$(slurp 2>/dev/null)
grim -g "$SELECTION" "$FILEPATH" || exit 1
[[ -z $SELECTION ]] && exit 0
kill $PID 2>/dev/null
trap - EXIT

swappy -f "$FILEPATH" -o "$FILEPATH"
wl-copy < "$FILEPATH"
