# DMS Stickies

A Stickies-style notes plugin for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell). Free-floating, draggable, resizable note windows that live on the desktop layer by default and can be pinned over other windows. Markdown source with a formatting toolbar, per-note accent colors, fold/unfold, save-to-disk as `.md`.

## Install

Symlink (or copy) into the DMS plugins directory:

```bash
ln -sf "$PWD" ~/.config/DankMaterialShell/plugins/dmsStickies
```

In DMS:

1. **Settings → Plugins** → click **Scan for Plugins** → enable **DMS Stickies**.
2. **Settings → Desktop Widgets** → add an instance of **DMS Stickies**.

A blank yellow sticky appears on your desktop.

> **Note**: typing into a sticky requires a small upstream patch (merged, unreleased) to `DesktopPluginWrapper.qml` that lets desktop plugins opt into keyboard focus. Without it, clicks land but keystrokes don't.

## Usage

### Editing

- **Left-click** the body to focus and type
- The toolbar above the editor toggles **bold / italic / strikethrough / inline code**, headings (**H1 / H2 / H3**), **bulleted / numbered / checkbox / quote** prefixes, and **link** insertion. All toggles are idempotent — clicking Bold on already-bolded text removes the markers.

### Window controls (title bar)

- **Color swatch** → opens 8-color accent picker
- **+** → spawns a new sticky (inherits color and pin state, blank content)
- **Pin** → flips between desktop layer and overlay layer (always-on-top)
- **Fold** → collapses to the title bar; remembers the unfolded height
- **⋯** → menu: Hide/Show toolbar · Duplicate · Copy as Markdown · Restore from trash · Empty trash · Delete

### Movement

- **Right-click + drag** anywhere on the sticky to move it
- **Right-click + drag the bottom-right corner** to resize
- Position and size are persisted per-screen, per-instance

## Storage

Each sticky's content lives as a real markdown file:

```
~/.local/share/DankMaterialShell/stickies/
  notes/<instanceId>.md       # active sticky content
  trash/<instanceId>.md       # soft-deleted, recoverable via "Restore from trash…"
```

Edit a `.md` externally and the corresponding sticky picks up the change within ~50ms via `inotify`.

## Hot reload (development)

```bash
dms ipc call plugins reload dmsStickies
```

Most changes hot-reload cleanly. Adding new sibling files under `components/`, or adding new signals/properties to existing `components/*.qml` files, requires a full DMS restart due to Qt's QML cache:

```bash
systemctl --user restart dms
```

## Known limitations

### Within-layer ordering on Niri

Layer-shell surfaces have a stable Z-rank within their layer, assigned by Niri at surface creation and held for the lifetime of the wayland surface. Drag-induced layer transitions (`Bottom → Overlay → Bottom`) raise the dragged sticky during the drag but Niri restores its original within-`Bottom` rank on release.

Practical consequences:

- **Two unpinned stickies**: dragged-on-top renders above during the drag, snaps back to its original rank on release.
- **Two pinned stickies**: both live on `Overlay` permanently, no transition ever happens, ordering is whatever Niri assigned at creation time.
- **Pinned vs. unpinned**: the pinned one always wins (different layers).

## Roadmap

- [x] skeleton (single sticky, drag, resize, position persistence)
- [x] markdown editor + on-disk persistence + multi-monitor sync
- [x] title bar with pin / fold / accent color
- [x] `+` to spawn new sticky, delete-to-trash with restore
- [x] markdown editor toolbar
- [x] per-sticky toolbar toggle + Empty trash
- [ ] per sticky title
- [ ] basic keybindings

## Backlog
- [ ] image paste & inline rendering
- [ ] spawn-new-sticky-beside-parent positioning (likely needs upstream wrapper exposure of `widgetX`/`widgetY`/`screenKey`)
- [ ] lock Y-axis resize while folded — wrapper has no max-height hook; snap-back from plugin side (whether via `heightChanged` debounce or `SettingsData.desktopWidgetInstancesChanged` Connections) doesn't reliably catch the drag-release on Niri. Likely needs upstream wrapper change to expose either a max-height or an `interactive`/`isInteracting` signal so the plugin can detect drag-end deterministically.
- [ ] sync-respecting fold (per-screen fold state when `syncPositionAcrossScreens` is OFF) — needs the wrapper to inject the current `screen`/`screenKey` to the plugin component so per-screen config keys can be derived (`Window.window.screen` didn't resolve in the layer-shell context).
