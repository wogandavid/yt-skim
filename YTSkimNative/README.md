# YTSkimNative (Proper AppKit Menu Bar App)

This is the production menu bar implementation.

## Supported Links

- YouTube videos
- X post URLs (`x.com/.../status/...`, `twitter.com/.../status/...`)

## Optional Dependency For X

- `bird` improves X fetch reliability and is optional.
- Install: <https://github.com/steipete/bird>

## Known Limitations

- X support is single-post only (no thread expansion).
- Private/deleted/rate-limited X posts can fail.

## Architecture

- AppKit lifecycle with persistent `NSStatusItem`
- SwiftUI views hosted in `NSHostingController` popovers
- Shell backend contract via bundled `Resources/yt-skim.sh`
- Global hotkey via `KeyboardShortcuts`
- Launch at login via `LaunchAtLogin-Modern`

## Build

```bash
/Users/david/Documents/tldr/scripts/build-unsigned-app.sh
```

## Package DMG

```bash
/Users/david/Documents/tldr/scripts/create-dmg.sh "/Users/david/Documents/tldr/dist/YT Skim.app"
```

## Manual Reliability Checklist

1. Launch app and confirm menu bar item appears immediately.
2. Verify exactly one app process is running.
3. Copy valid YouTube URL and run `Summarize Clipboard`.
4. Copy valid X post URL and run `Summarize Clipboard`.
5. Verify invalid/unsupported URL shows friendly error + details.
6. Toggle mode, launch at login, replace clipboard, and Dock debug visibility.
7. Validate hotkey trigger and persistence after relaunch.
8. Use `First-Run Check` and confirm dependency diagnostics (including optional `bird` check).
9. Run 1-hour soak (repeat summarize/open menu/idle cycles) with no crashes or disappearing menu bar item.

## Open in Xcode

1. Generate project:
```bash
cd /Users/david/Documents/tldr/YTSkimNative
xcodegen generate
```
2. Open:
```bash
open /Users/david/Documents/tldr/YTSkimNative/YTSkimNative.xcodeproj
```
