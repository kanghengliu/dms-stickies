# DMS Stickies

A Stickies-style notes plugin for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell). Free-floating, draggable, resizable note windows that live on the desktop layer by default and can be pinned over other windows. Markdown source with formatting shortcuts, per-note accent colors, fold/unfold, save-to-disk as `.md`.

## Install (development)

Symlink or copy to plugins directory, then

In DMS:

1. Open **Settings → Plugins**, click **Scan for Plugins**, enable **DMS Stickies**.
2. Open **Settings → Desktop Widgets**, add an instance of **DMS Stickies**.

A blank placeholder sticky should appear on your desktop.

## Usage (current state)

- **Left-click** the sticky body to focus and type.
- **Right-click + drag** anywhere on the sticky to move it.
- **Right-click + drag the bottom-right corner** to resize.
- Position, size, and note content persist across shell restarts. Notes are stored as `~/.local/share/DankMaterialShell/stickies/notes/<instanceId>.md`.

## Hot reload

```bash
dms ipc call plugins reload dmsStickies
```

## Roadmap

- [x] M1 — skeleton (this milestone)
- [x] M2 — markdown editor + on-disk persistence
- [x] M3 — title bar with pin / fold / accent color
- [x] M4 — `+` to spawn new sticky, delete-to-trash
- [x] M5 — markdown editor toolbar
- [ ] M6 — global plugin settings & polish
- [ ] Backlog — image paste & inline rendering
- [ ] Backlog — keyboard shortcuts
