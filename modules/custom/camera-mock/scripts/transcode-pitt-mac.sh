#!/usr/bin/env bash
# transcode-pitt-mac.sh
#
# Run this on your Mac (M4 Max). It will:
#   1. Pull each HEVC MKV from the Pi via scp
#   2. Encode to H.264 High 8-bit yuv420p 720p using Apple VideoToolbox
#   3. Push the MP4 back to the SAME directory on the Pi
#   4. Delete the original MKV from the Pi to free space
#
# Usage:
#   chmod +x transcode-pitt-mac.sh
#   ./transcode-pitt-mac.sh
#
# Requirements on Mac:
#   - ffmpeg installed (brew install ffmpeg)
#   - SSH access to pi (adjust PI_HOST if needed)

set -euo pipefail

PI_HOST="pi"
PI_DIR="/mnt/hdd/media/tv/The Pitt/Season 1"
LOCAL_WORK_DIR="$HOME/tmp/pitt-transcode"

EPISODES=(
  "The.Pitt.S01E01.1080p.10bit.WEBRip.6CH.x265.HEVC-PSA.mkv"
)

mkdir -p "$LOCAL_WORK_DIR"

# rsync needs the remote path shell-quoted to handle spaces
rsync_remote() { echo "${PI_HOST}:$(printf '%q' "${PI_DIR}/$1")"; }

for mkv in "${EPISODES[@]}"; do
  ep_id=$(echo "$mkv" | grep -oE 'S[0-9]+E[0-9]+')
  out_name="The.Pitt.${ep_id}.720p.H264.mp4"
  local_src="$LOCAL_WORK_DIR/$mkv"
  local_dst="$LOCAL_WORK_DIR/$out_name"
  pi_out="${PI_DIR}/${out_name}"

  # Skip if already done on Pi
  if ssh "$PI_HOST" "test -f '${pi_out}'"; then
    echo "[$out_name] already on Pi, skipping"
    continue
  fi

  # Skip encode if MP4 already produced locally
  if [ -f "$local_dst" ]; then
    echo "[$out_name] already encoded locally, pushing to Pi..."
  else
    # Pull MKV from Pi if not already local
    if [ ! -f "$local_src" ]; then
      echo "[$mkv] pulling from Pi..."
      rsync -ah --progress "$(rsync_remote "$mkv")" "$local_src"
    else
      echo "[$mkv] already local"
    fi

  # Encode with Apple VideoToolbox (hardware H.264 on M4 Max)
  echo "[$mkv] encoding → $out_name ..."
  ffmpeg -hide_banner -loglevel warning -stats \
    -i "$local_src" \
    -vf "scale=1280:720:flags=lanczos,format=yuv420p" \
    -c:v h264_videotoolbox \
    -profile:v high \
    -level:v 4.1 \
    -b:v 2000k \
    -maxrate 3000k \
    -bufsize 4000k \
    -pix_fmt yuv420p \
    -color_range tv \
    -an \
    -movflags +faststart \
    "$local_dst"

  # Push MP4 back to same dir on Pi
  echo "[$out_name] pushing to Pi..."
  rsync -ah --progress "$local_dst" "${PI_HOST}:${PI_DIR}/"

  # Verify remote file size matches local before deleting source
  local_size=$(stat -f%z "$local_dst" 2>/dev/null || stat -c%s "$local_dst")
  remote_size=$(ssh "$PI_HOST" "stat -c%s '${PI_DIR}/${out_name}'")
  if [ "$local_size" != "$remote_size" ]; then
    echo "ERROR: size mismatch for $out_name (local=$local_size remote=$remote_size) — skipping delete"
    rm -f "$local_src" "$local_dst"
    continue
  fi

  # Delete original MKV from Pi to free space
  echo "[$mkv] deleting source MKV from Pi..."
  ssh "$PI_HOST" "rm -f '${PI_DIR}/${mkv}'"

  # Clean up local copies
  rm -f "$local_src" "$local_dst"
  echo "[$out_name] done"
done

echo ""
echo "All episodes done. Restarting camera-mock on Pi..."
ssh "$PI_HOST" "systemctl --user restart camera-mock"
echo "Done. Test with: ffprobe -v error -rtsp_transport tcp -show_entries stream=codec_name,width,height -of csv=p=0 rtsp://${PI_HOST}:8554/stream1"
