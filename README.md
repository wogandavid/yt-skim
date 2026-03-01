# YT Skim

YouTube link summarizer that avoids opening/watching videos.

## Production App (Proper Native Path)

The release path is now:
- project spec: [/Users/david/Documents/tldr/YTSkimNative/project.yml](/Users/david/Documents/tldr/YTSkimNative/project.yml)
- generated project: `/Users/david/Documents/tldr/YTSkimNative/YTSkimNative.xcodeproj`
- app source: `/Users/david/Documents/tldr/YTSkimNative/YTSkimNative/`

Core model:
- AppKit `NSStatusItem` lifecycle
- SwiftUI hosted inside AppKit popovers
- backend engine via bundled `yt-skim.sh --app-mode --json`

## Build and Package

Build unsigned app:

```bash
/Users/david/Documents/tldr/scripts/build-unsigned-app.sh
```

Create unsigned DMG:

```bash
/Users/david/Documents/tldr/scripts/create-dmg.sh "/Users/david/Documents/tldr/dist/YT Skim.app"
```

Artifacts:
- `/Users/david/Documents/tldr/dist/YT Skim.app`
- `/Users/david/Documents/tldr/dist/YT-Skim-unsigned.dmg`

## CLI Engine Contract (unchanged)

Command:

```bash
/Users/david/Documents/tldr/bin/yt-skim.sh --app-mode --json --input-url "<url>" --mode short|standard|structured --keep-clipboard
```

Success JSON:

```json
{"ok":true,"summary":"...","mode":"standard","source":"youtube","exit_code":0}
```

Failure JSON:

```json
{"ok":false,"error_code":"INVALID_URL|MISSING_DEP|BACKEND_FAIL","message":"...","details":"...","exit_code":2|3|4}
```

## Legacy Path

`/Users/david/Documents/tldr/YTSkimMenuBar` is now legacy (non-release) and retained only for reference while migration completes.

## Unsigned Install (Gatekeeper)

1. Open `YT-Skim-unsigned.dmg`.
2. Drag `YT Skim.app` into Applications.
3. Right-click app in Applications -> `Open`.
4. If blocked, use `System Settings -> Privacy & Security -> Open Anyway`.
