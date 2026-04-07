---
name: build
description: Build the app locally on M2 Mac Mini. Use when the user says "build", "make an APK", "build android", "build ios", or similar.
argument-hint: "[platform] [profile]"
---

Build the app using `scripts/remote-build.sh` which SSHes to the M2 Mac Mini and builds locally. NEVER use `eas build` directly — always use these scripts.

## Usage

Parse the user's request to determine platform and profile. If not specified, ask.

### Available commands

| Command | Platform | Profile | Channel |
|---------|----------|---------|---------|
| `pnpm build:android` | Android | preview | preview |
| `pnpm build:android:staging` | Android | staging | preview |
| `pnpm build:ios` | iOS | production | production |
| `pnpm build:ios:dev` | iOS | development | development |
| `pnpm build:ios:staging` | iOS | staging | preview |

### Steps

1. **Determine the build command** from the user's request and the table above.

2. **Echo the start time** so the user knows when the build kicked off:
   ```bash
   echo "Build started at $(date '+%Y-%m-%d %H:%M:%S')"
   ```

3. **Run the build** in the background using `run_in_background: true`:
   ```bash
   pnpm build:android  # or whichever command
   ```

4. **Set up polling** — use CronCreate to poll every minute for the artifact on the M2:
   ```
   ssh alexmiller@m2mini.local "echo \"[$(date '+%H:%M:%S')] Checking...\" && ls -lt ~/dev/flexbike/flexbike-react-native/build-*.apk 2>/dev/null | head -1 || echo 'No APK yet'"
   ```
   Cancel the poll (CronDelete) once the artifact appears.

5. **Tell the user how to watch progress** — the script logs to `logs/builds/build_YYYY-MM-DD_HH-MM-SS.log`. Give them:
   ```bash
   tail -f logs/builds/$(ls -t logs/builds/ | head -1)
   ```

6. **When the build finishes**, always report a summary with:
   - **Start time** (from the echo in step 2)
   - **End time** (from the build log's final timestamp)
   - **Duration** (from the build log's "Total time" line)
   - **Artifact path** (if success)
   - **Build number and version** (from the post-build output)
   - **Error details** (if failure, show the relevant error from the log)

## Rules

- NEVER run `eas build` or `pnpm eas build` directly
- NEVER use EAS cloud builds — always use the local M2 scripts
- The script handles: git push, SSH sync, local build, artifact copy, and post-build pipeline
- Build logs go to `logs/builds/`
- Build artifacts go to `builds/`
