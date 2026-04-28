# DMS Stickies

A Stickies-style notes plugin for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell). Free-floating, draggable, resizable note windows that live on the desktop layer by default and can be pinned over other windows. Markdown source with a formatting toolbar, per-note accent colors, fold/unfold, writes in `.md`. Save as you write.

---
![preview](assets/screenshot.png)

## Prerequisites
- Latest DankMaterialShell-git
- niri or hyprland

## Install

- Manual

Symlink (or copy) into the DMS plugins directory.

```bash
ln -sf "$PWD" ~/.config/DankMaterialShell/plugins/dmsStickies
```

- In DMS Plugin Store (unreleased):

1. **Settings → Plugins** → click **Scan for Plugins** → enable **DMS Stickies**.
2. **Settings → Desktop Widgets** → add an instance of **DMS Stickies**.

A blank yellow sticky appears on your desktop.

> **Note:** This plugin requires two small PRs (both merged upstream): `acceptsKeyboardFocus` (so clicks-to-type work) and a `screen` property injection (used for left-click drag, spawn-beside, and per-screen fold). The plugin will load without them but those features won't work.

## Usage

### Editing

- Toggle toolbar via drop down menu.

### Title bar

- Select sticky's accent color and opacity via top left color swatch.
- Title is captured from the first non-empty line of the sticky's content.
- Spawn new sticky
- Pin/unpin
- Fold/unfold
- Menu
  - Show/hide toolbar
  - Duplicate
  - Copy
  - Restore from trash
  - Empty trash
  - Delete

### Movement

- Draggable title bar via left/right mouse buttons
- Resize by using right mouse button to drag the bottom-right corner
- Double click title bar to fold/unfold
- Sync sticky **position** across screens via DMS widget settings

## Storage

Each sticky's content lives as a real markdown file:

```
~/.local/share/DankMaterialShell/stickies/
  notes/<instanceId>.md       # active sticky content
  trash/<instanceId>.md       # soft-deleted, recoverable via "Restore from trash…"
```


## Known limitations

### Within-layer z-ordering on Niri

Layer-shell surfaces have a stable Z-rank within their layer, assigned by Niri at surface creation and held for the lifetime of the wayland surface. Drag-induced layer transitions (`Bottom → Overlay → Bottom`) raise the dragged sticky during the drag but Niri restores its original within-`Bottom` rank on release.

Practical consequences:

- **Two unpinned stickies**: dragged-on-top renders above during the drag, snaps back to its original rank on release.
- **Two pinned stickies**: both live on `Overlay` permanently, no transition ever happens, ordering is whatever Niri assigned at creation time.
- **Pinned vs. unpinned**: the pinned one always wins (different layers).


## Roadmap

Done:
- [x] Skeleton (single sticky, drag, resize, position persistence)
- [x] Markdown editor + on-disk persistence + multi-monitor sync
- [x] Title bar with pin / fold / accent color
- [x] `+` to spawn new sticky, delete-to-trash with restore
- [x] Markdown editor toolbar
- [x] Per-sticky toolbar toggle + Empty trash with two-click confirmation
- [x] Title-bar label from first content line
- [x] Left-click drag on title bar
- [x] Double-click title bar to fold/unfold
- [x] Click-outside dismisses popovers
- [x] Per-screen fold state when sync is OFF
- [x] Spawn-new-sticky-beside-parent (per-screen)
- [x] Per-sticky opacity (slider in the color popover, perceptual curve so body and title bar fade in lockstep)
- [x] Active-state opacity boost (fully opaque on focus/hover)
- [ ] Resize font

## Backlog
- [ ] Image paste & inline rendering
- [ ] Basic keyboard shortcuts (toolbar actions, fold, pin, etc.)
- [ ] Lock Y-axis resize while folded — wrapper has no max-height hook; snap-back from plugin side (`heightChanged` debounce or `SettingsData.desktopWidgetInstancesChanged` Connections) doesn't reliably catch drag-release on Niri. Needs upstream wrapper change to expose either a max-height or an `interactive`/`isInteracting` signal so the plugin can detect drag-end deterministically.
