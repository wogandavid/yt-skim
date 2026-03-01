# YT Skim

Menu bar app for macOS that summarizes YouTube and X links from your clipboard so you can skim content without opening it.

## Who This Release Is For

Technical beta users on macOS who can install CLI dependencies.

## Supported Links

- YouTube: `youtube.com`, `youtu.be` (including mobile links)
- X posts: `x.com/.../status/...`, `twitter.com/.../status/...`

## Requirements

YT Skim app uses external CLIs for summarization and auth.

1. Install `summarize`:

```bash
npm install -g @steipete/summarize
```

2. Install Codex CLI (or Codex app that includes `codex`), then authenticate with your OpenAI account:

```bash
codex login
```

When prompted:

- Choose `Continue with OpenAI`.
- Complete browser sign-in with the OpenAI account you want to use for summaries.
- Return to Terminal after success.

3. Optional but recommended for X reliability:

```bash
brew install steipete/tap/bird
```

## Install From DMG

1. Download `YT-Skim-unsigned.dmg` from Releases.
2. Open DMG and drag `YT Skim.app` to `Applications`.
3. First launch: right-click app in `Applications` -> `Open`.
4. If blocked, go to `System Settings -> Privacy & Security` and click `Open Anyway`.
5. In the app menu, run `First-Run Check` and confirm:
- `summarize` available
- `codex` available
- `Codex login status` is logged in (OpenAI account connected)

## Runtime Behavior

- Default mode: `Standard`
- Trigger: menu item or global hotkey
- Clipboard summary replacement: enabled by default
- No persistent history by default (uses `/tmp` for recent summary)

## Known Limitations

- X support is single-post only (no thread expansion).
- Private/deleted/rate-limited X posts can fail.
- Without `bird`, X fetch reliability is lower.

## Build Release Artifacts (Maintainers)

Build unsigned app:

```bash
./scripts/build-unsigned-app.sh
```

Create unsigned DMG:

```bash
./scripts/create-dmg.sh "$(pwd)/dist/YT Skim.app"
```

Artifacts:

- `dist/YT Skim.app`
- `dist/YT-Skim-unsigned.dmg`

## CLI Engine Contract

Command:

```bash
./bin/yt-skim.sh --app-mode --json --input-url "<url>" --mode short|standard|structured --keep-clipboard
```

Success JSON:

```json
{"ok":true,"summary":"...","mode":"standard","source":"youtube|x","exit_code":0}
```

Failure JSON:

```json
{"ok":false,"error_code":"INVALID_URL|UNSUPPORTED_URL|MISSING_DEP|X_FETCH_UNAVAILABLE|BACKEND_FAIL","message":"...","details":"...","exit_code":2|3|4}
```

## Repo Layout

- `YTSkimNative/` = production app path
- `YTSkimMenuBar/` = legacy reference path
