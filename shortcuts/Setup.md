# macOS Shortcuts Setup (Legacy CLI Workflow)

This is optional and separate from the native menu bar app.

Set `REPO_ROOT` to your local clone path.

## Shortcut 1: `YT Skim`

1. Open **Shortcuts**.
2. Create shortcut `YT Skim`.
3. Add **Run Shell Script** action:

```bash
REPO_ROOT="$HOME/path/to/tldr"
"$REPO_ROOT/bin/yt-skim.sh" --mode standard
```

4. Assign keyboard shortcut (example): `Cmd+Shift+Y`.

## Shortcut 2 (optional): `YT Skim Popup`

1. Create shortcut `YT Skim Popup`.
2. Add **Run Shell Script** action:

```bash
REPO_ROOT="$HOME/path/to/tldr"
"$REPO_ROOT/bin/yt-skim-popup.sh"
```

3. Assign keyboard shortcut (example): `Cmd+Shift+Option+Y`.

## Notes

- Uses clipboard URL unless `--url` is passed.
- Supports YouTube and X URLs.
- Success overwrites clipboard with summary by default.
- Use `--keep-clipboard` to preserve clipboard.
