#!/usr/bin/env bash
# download-hospital-streams.sh
#
# Downloads hospital-themed YouTube videos directly as H.264 8-bit MP4
# using yt-dlp with YouTube Premium cookies (for best quality / no throttle).
#
# Usage:
#   1. Export cookies from Chrome/Firefox on Mac:
#      - Chrome: install "Get cookies.txt LOCALLY" extension → export youtube.com cookies
#      - Firefox: install "cookies.txt" extension → export youtube.com cookies
#      Then: scp cookies.txt pi:/mnt/hdd/media/yt-cookies.txt
#
#   2. Run on Pi:
#      ./scripts/download-hospital-streams.sh
#
# Output: /mnt/hdd/media/hospital-streams/stream1.mp4 ... stream8.mp4
# Format: H.264 High, 8-bit, yuv420p, 720p, no audio

set -euo pipefail

COOKIES="/mnt/hdd/media/yt-cookies.txt"
OUT_DIR="/mnt/hdd/media/hospital-streams"
mkdir -p "$OUT_DIR"

# Hospital/medical themed YouTube videos — real documentary/stock footage
# Replace any URL with a preferred one; these are public hospital/ER content
VIDEOS=(
  "https://www.youtube.com/watch?v=D2tkiic32Iw"  # True Stories from ER: Medical Documentary
  "https://www.youtube.com/watch?v=2g0yqGPUjJM"  # Emergency Room Life - 24 Hours in A&E S02E14
  "https://www.youtube.com/watch?v=I5iewcBt4RI"  # 24 Hours in the ER: Health care's front lines
  "https://www.youtube.com/watch?v=mHDYQIy_zuY"  # 24 Hours In The ER
  "https://www.youtube.com/watch?v=_n7TaOi94-g"  # Real-Life Stories from a Trauma Center
  "https://www.youtube.com/watch?v=2g0yqGPUjJM"  # Emergency Room Life - 24 Hours in A&E S02E14 (dup ok, different slot)
  "https://www.youtube.com/watch?v=mHDYQIy_zuY"  # 24 Hours In The ER (dup ok, different slot)
  "https://www.youtube.com/watch?v=3JZ_D3ELwOQ"  # Hospital ambience
)

COOKIE_ARGS=()
if [ -f "$COOKIES" ]; then
  echo "Using YouTube Premium cookies from $COOKIES"
  COOKIE_ARGS=(--cookies "$COOKIES")
else
  echo "WARNING: No cookies file found at $COOKIES — download may be throttled or lower quality"
  echo "  To use Premium: scp cookies.txt pi:$COOKIES"
fi

for i in "${!VIDEOS[@]}"; do
  url="${VIDEOS[$i]}"
  stream_num=$((i + 1))
  out_file="$OUT_DIR/stream${stream_num}.mp4"

  if [ -f "$out_file" ]; then
    echo "[stream${stream_num}] already exists, skipping"
    continue
  fi

  echo "[stream${stream_num}] downloading $url ..."
  # Download video-only H.264 stream (no audio needed for camera-mock)
  # -S prefers 720p, then 1080p; vcodec:h264 ensures avc1 not vp9/av1
  yt-dlp \
    "${COOKIE_ARGS[@]}" \
    --format "bestvideo[vcodec^=avc1][height<=720][ext=mp4]/bestvideo[vcodec^=avc1][height<=720]/bestvideo[vcodec^=avc1]" \
    --no-audio \
    --output "$out_file" \
    "$url" && echo "[stream${stream_num}] done: $out_file"
done

echo ""
echo "Verifying downloaded files..."
for i in $(seq 1 8); do
  f="$OUT_DIR/stream${i}.mp4"
  if [ -f "$f" ]; then
    info=$(ffprobe -v error -show_entries stream=codec_name,width,height,pix_fmt -of csv=p=0 "$f" 2>/dev/null | head -1)
    echo "  stream${i}: $info"
  else
    echo "  stream${i}: MISSING"
  fi
done

echo ""
echo "Update camera-mock config, then restart:"
echo "  systemctl --user restart camera-mock"
