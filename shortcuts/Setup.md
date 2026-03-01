# macOS Shortcuts Setup

## Shortcut 1: `YT Skim`

1. Open the **Shortcuts** app.
2. Create a new shortcut named `YT Skim`.
3. Add action: **Run Shell Script**.
4. Set script to:

```bash
/Users/david/Documents/tldr/bin/yt-skim.sh --mode standard
```

5. In shortcut settings, assign keyboard shortcut: `Cmd+Shift+Y` (recommended).

## Shortcut 2 (optional): `YT Skim Popup`

1. Create another shortcut named `YT Skim Popup`.
2. Add action: **Run Shell Script**.
3. Set script to:

```bash
/Users/david/Documents/tldr/bin/yt-skim-popup.sh
```

4. Assign keyboard shortcut: `Cmd+Shift+Option+Y` (recommended).

## Notes

- `YT Skim` uses clipboard URL unless `--url` is passed.
- Script accepts only `youtube.com` and `youtu.be` links in v0.
- On success, summary replaces clipboard by default.
- Use `--keep-clipboard` if you do not want clipboard replacement.
