#!/usr/bin/env bash
# dim-brightness.sh — proportional dimming for hypridle
# Dims to a fraction of the current brightness, so the step
# feels natural at 100% (home) and at 20–30% (school).

# ── Config ──────────────────────────────────────────────
DIM_RATIO=0.20        # dim to this fraction of current brightness (20%)
MIN_DIM=3             # never go below this % (avoids completely black screen)
SAVE_FILE="/tmp/hypridle-brightness-save"
# ────────────────────────────────────────────────────────

current=$(brightnessctl g)
max=$(brightnessctl m)

# Convert to percentage (integer)
current_pct=$(( current * 100 / max ))

# Calculate target: DIM_RATIO × current, floor to integer, respect MIN_DIM
target_pct=$(awk -v pct="$current_pct" -v ratio="$DIM_RATIO" -v min="$MIN_DIM" \
    'BEGIN { t=int(pct*ratio); print (t<min ? min : t) }')

# Save current raw value for restore
echo "$current" > "$SAVE_FILE"

brightnessctl set "${target_pct}%"
