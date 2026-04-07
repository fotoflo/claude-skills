#!/bin/bash
# Setup script for the transcribe skill
# Installs CLI deps via Homebrew and downloads a whisper model
set -euo pipefail

echo "=== Transcribe Skill Setup ==="

# 1. Install CLI deps
echo ""
echo "Checking Homebrew dependencies..."
if ! command -v whisper-cli &>/dev/null; then
  echo "Installing whisper-cpp..."
  brew install whisper-cpp
else
  echo "whisper-cli: already installed"
fi

if ! command -v ffmpeg &>/dev/null; then
  echo "Installing ffmpeg..."
  brew install ffmpeg
else
  echo "ffmpeg: already installed"
fi

# 2. Find or download a whisper model
MODEL_DIR="$HOME/Library/Application Support/superwhisper"
FALLBACK_DIR="/opt/homebrew/share/whisper-cpp"

# Check if a usable model already exists
EXISTING=""
for dir in "$MODEL_DIR" "$FALLBACK_DIR"; do
  for size in medium small base; do
    for f in "$dir/ggml-${size}.bin" "$dir/ggml-${size}.en.bin"; do
      if [[ -f "$f" ]]; then
        EXISTING="$f"
        break 3
      fi
    done
  done
done

if [[ -n "$EXISTING" ]]; then
  echo ""
  echo "Model found: $EXISTING"
  echo "No download needed."
else
  echo ""
  echo "No whisper model found. Downloading ggml-base.bin (~150MB)..."
  TARGET="$FALLBACK_DIR/ggml-base.bin"
  mkdir -p "$FALLBACK_DIR"
  curl -L --progress-bar -o "$TARGET" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
  echo "Downloaded to: $TARGET"
  echo ""
  echo "For better accuracy, you can also download the medium model (~1.5GB):"
  echo "  curl -L -o \"$FALLBACK_DIR/ggml-medium.bin\" \\"
  echo "    \"https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin\""
fi

echo ""
echo "=== Setup complete ==="
