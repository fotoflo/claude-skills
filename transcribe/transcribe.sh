#!/bin/bash
# transcribe.sh — Convert and transcribe audio files using whisper-cpp
# Usage: transcribe.sh <file1> [file2] ...
# Output: plain text transcriptions to stdout, combined output to pbcopy

set -euo pipefail

# Find a whisper model
find_model() {
  local candidates=(
    "$HOME/Library/Application Support/superwhisper/ggml-medium.bin"
    "$HOME/Library/Application Support/superwhisper/ggml-small.bin"
    "$HOME/Library/Application Support/superwhisper/ggml-small.en.bin"
    "$HOME/Library/Application Support/superwhisper/ggml-base.bin"
    "/opt/homebrew/share/whisper-cpp/ggml-medium.bin"
    "/opt/homebrew/share/whisper-cpp/ggml-base.bin"
    "/opt/homebrew/share/whisper-cpp/ggml-small.bin"
  )
  for m in "${candidates[@]}"; do
    if [[ -f "$m" ]]; then
      echo "$m"
      return 0
    fi
  done
  echo "ERROR: No whisper model found" >&2
  return 1
}

MODEL=$(find_model)
OUTPUT=""

# Sort files by modification time (oldest first) for chronological order
SORTED_FILES=$(for f in "$@"; do echo "$f"; done | while read -r f; do
  stat -f "%m %N" "$f"
done | sort -n | cut -d' ' -f2-)

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # Extract timestamp from filename if possible (WhatsApp format)
  basename=$(basename "$file")
  # Try to extract date/time from "WhatsApp Audio YYYY-MM-DD at HH.MM.SS" pattern
  if [[ "$basename" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})\ at\ ([0-9]{2})\.([0-9]{2})\.([0-9]{2}) ]]; then
    date_part="${BASH_REMATCH[1]}"
    time_part="${BASH_REMATCH[2]}:${BASH_REMATCH[3]}:${BASH_REMATCH[4]}"
    header="[${date_part} ${time_part} — ${basename}]"
  else
    # Fall back to file modification time
    mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file")
    header="[${mod_time} — ${basename}]"
  fi

  # Convert to 16kHz mono WAV
  tmpwav=$(mktemp /tmp/whisper-XXXXXX.wav)
  ffmpeg -y -i "$file" -ar 16000 -ac 1 -c:a pcm_s16le "$tmpwav" 2>/dev/null

  # Transcribe
  text=$(whisper-cli -m "$MODEL" --no-timestamps -l auto -t 8 -f "$tmpwav" 2>/dev/null | sed 's/^[[:space:]]*//')

  # Cleanup temp file
  rm -f "$tmpwav"

  # Build output block
  block="${header}
${text}"

  if [[ -n "$OUTPUT" ]]; then
    OUTPUT="${OUTPUT}

${block}"
  else
    OUTPUT="$block"
  fi

done <<< "$SORTED_FILES"

# Display and copy
echo "$OUTPUT"
echo "$OUTPUT" | pbcopy
echo ""
echo "--- Copied to clipboard ---"
