---
name: transcribe
description: Transcribe audio files (opus, ogg, mp3, wav, m4a) to text using local whisper-cpp. Use when the user says "transcribe", "what does this audio say", or provides an audio file.
argument-hint: "<path-to-audio-file>"
---

Transcribe an audio file to text using local whisper-cpp.

## Prerequisites

- `whisper-cli` (install: `brew install whisper-cpp`)
- `ffmpeg` (install: `brew install ffmpeg`)
- A whisper model file. If none exists, download one:
  ```bash
  whisper-cli --model-path-default  # shows default model directory
  # Download base model (~150MB, good balance of speed/quality):
  curl -L -o "$(whisper-cli --model-path-default)/ggml-base.bin" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
  # For better accuracy, use medium (~1.5GB):
  curl -L -o "$(whisper-cli --model-path-default)/ggml-medium.bin" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"
  ```

## Steps

### 1. Locate the audio file

Use $ARGUMENTS as the file path. If not provided, ask the user.

Common WhatsApp voice note locations:
- `~/Downloads/*.opus`
- `~/Documents/*.opus`

### 2. Convert to WAV if needed

whisper-cpp works best with 16kHz WAV. If the input is not `.wav`:

```bash
ffmpeg -i "<input-file>" -ar 16000 -ac 1 -c:a pcm_s16le /tmp/whisper-input.wav
```

### 3. Find a model

Check for models in order of preference:
1. `$(whisper-cli --model-path-default)/ggml-medium.bin`
2. `$(whisper-cli --model-path-default)/ggml-base.bin`
3. `$(whisper-cli --model-path-default)/ggml-small.bin`

If no model exists, download `ggml-base.bin` (see Prerequisites).

### 4. Transcribe

```bash
whisper-cli -m <model-path> --no-timestamps -f /tmp/whisper-input.wav
```

Useful flags:
- `-l auto` — auto-detect language (default is English)
- `-l bn` — force Bengali (useful for Bangladeshi WhatsApp messages)
- `--no-timestamps` — clean text output without `[00:00:00 --> 00:00:05]` markers
- `-t 8` — use 8 threads for faster processing

### 5. Output

Display the transcription text to the user. If the language wasn't English, offer to translate.

### 6. Cleanup

```bash
rm /tmp/whisper-input.wav
```

## Rules

- Always convert to 16kHz mono WAV before transcribing — opus/ogg direct input is unreliable
- Default to `--no-timestamps` for clean output unless user wants timestamps
- If transcription is empty or garbage, suggest trying a larger model
- Don't modify or delete the original audio file
