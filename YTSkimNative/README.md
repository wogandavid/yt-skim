# YTSkimNative

Production AppKit menu bar implementation for YT Skim.

## Supported Links

- YouTube videos
- X post URLs (`x.com/.../status/...`, `twitter.com/.../status/...`)

## External Dependencies

Required:

- `summarize`
- `codex` (authenticated via `codex login` and OpenAI browser sign-in)

OpenAI auth flow:

```bash
codex login
```

- Choose `Continue with OpenAI`.
- Complete browser sign-in.
- Re-run `First-Run Check` in the app to confirm login status.

Optional:

- `bird` for better X fetch reliability

## Build

```bash
./scripts/build-unsigned-app.sh
```

## Package DMG

```bash
./scripts/create-dmg.sh "$(pwd)/dist/YT Skim.app"
```

## Manual Reliability Checklist

1. Launch app and confirm menu bar item appears immediately.
2. Verify exactly one app process is running.
3. Copy valid YouTube URL and run `Summarize Clipboard`.
4. Copy valid X post URL and run `Summarize Clipboard`.
5. Verify unsupported URL shows friendly error + details.
6. Toggle mode, launch at login, replace clipboard, and Dock debug visibility.
7. Validate hotkey trigger and persistence after relaunch.
8. Run `First-Run Check` and confirm dependency/auth diagnostics.
9. Run 1-hour soak (summarize/open menu/idle cycles) with no crashes or disappearing status item.

## Open in Xcode

1. Generate project:

```bash
cd YTSkimNative
xcodegen generate
```

2. Open project:

```bash
open YTSkimNative.xcodeproj
```
