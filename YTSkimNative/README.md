# YTSkimNative (Proper AppKit Menu Bar App)

This is the production menu bar implementation.

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
4. Verify invalid URL shows friendly error + details.
5. Toggle mode, launch at login, replace clipboard, and Dock debug visibility.
6. Validate hotkey trigger and persistence after relaunch.
7. Use `First-Run Check` and confirm dependency diagnostics.
8. Run 1-hour soak (repeat summarize/open menu/idle cycles) with no crashes or disappearing menu bar item.

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
