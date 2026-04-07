---
name: transcribe
description: Transcribe audio files (opus, ogg, mp3, wav, m4a) to text using local whisper-cpp. Use when the user says "transcribe", "what does this audio say", or provides an audio file.
argument-hint: "<path-to-audio-file> | dl"
---

Transcribe audio files to text using local whisper-cpp.

## Prerequisites

- `whisper-cli` (install: `brew install whisper-cpp`)
- `ffmpeg` (install: `brew install ffmpeg`)
- A whisper model — the script checks superwhisper's models first (`~/Library/Application Support/superwhisper/`), then whisper-cpp's default location

## Steps

### 1. Locate the audio file(s)

If $ARGUMENTS is `dl`:
- Scan `~/Downloads/` for audio files (opus, ogg, mp3, wav, m4a) modified in the last 24 hours
- Collect all matching file paths

Otherwise, use $ARGUMENTS as the file path. If not provided, ask the user.

### 2. Run the transcribe script

Pass all files to the script. It handles conversion, model selection, chronological ordering, and pbcopy automatically:

```bash
bash /Users/fotoflo/.claude/skills/transcribe/transcribe.sh "<file1>" "<file2>" ...
```

The script:
- Sorts files oldest-first (chronological order)
- Extracts timestamps from WhatsApp filenames or falls back to file modification time
- Converts each file to 16kHz mono WAV
- Transcribes with auto language detection
- Outputs all transcriptions with context headers
- Copies combined output to clipboard via pbcopy

### 3. Display and offer next steps

Show the transcription output to the user. Then mention:
- The text has been copied to clipboard
- If any language wasn't English, offer to translate

## Rules

- Don't modify or delete the original audio files
- If transcription is empty or garbage, suggest trying a larger model
- If the script fails, fall back to running the steps manually
