import QtCore
import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Plugins
import qs.Widgets
import "./components"
import "./components/Palette.js" as Palette
import "./components/MarkdownShortcuts.js" as MD

DesktopPluginComponent {
    id: root

    readonly property real titleBarHeight: 28
    readonly property real toolbarHeight: 26

    minWidth: 200
    minHeight: titleBarHeight

    property real defaultWidth: 240
    property real defaultHeight: 220
    property bool acceptsKeyboardFocus: true

    readonly property string storageDir: Paths.strip(StandardPaths.writableLocation(StandardPaths.GenericDataLocation)) + "/DankMaterialShell/stickies"

    readonly property string accentName: pluginData.accent ?? "yellow"
    readonly property var accentPalette: Palette.get(accentName)
    readonly property bool pinned: pluginData.showOnOverlay ?? false
    readonly property bool folded: pluginData.folded ?? false
    readonly property bool showToolbar: pluginData.showToolbar ?? true

    // First non-empty line of editor content, shown as the title bar label.
    // Strips leading markdown heading hashes so "# Hello" reads as "Hello".
    readonly property string titleLine: {
        const t = editor.text || "";
        const lines = t.split("\n");
        for (var i = 0; i < lines.length; i++) {
            const stripped = lines[i].replace(/^#+\s*/, "").trim();
            if (stripped.length > 0)
                return stripped;
        }
        return "";
    }

    // Fold animation: animate the body Rectangle's height while the wrapper window stays put.
    // The wrapper resize is triggered before unfold (so window grows first) or after fold
    // completes (so window shrinks last). Empty area inside the wrapper renders transparent.
    property bool _foldAnimating: false
    property real _animatedBodyHeight: 0
    readonly property real _bodyHeight: _foldAnimating ? _animatedBodyHeight : height

    NumberAnimation {
        id: foldAnim
        target: root
        property: "_animatedBodyHeight"
        duration: 220
        easing.type: Easing.InOutCubic

        property bool _foldDirection: false

        onFinished: {
            if (_foldDirection) {
                // Just finished folding — snap wrapper down. Keep _foldAnimating true
                // until root.height actually matches the animated value, otherwise the
                // body Rectangle's height binding flips to root.height (still full) for
                // one frame and we get a regrow flash.
                root.setData("folded", true);
                root._setAllPositionsHeight(root.titleBarHeight);
                foldReleaseFallback.restart();
            } else {
                // Unfold: wrapper grew before animation started, so root.height is
                // already at the target. Safe to release immediately.
                Qt.callLater(() => root._foldAnimating = false);
            }
        }
    }

    Timer {
        id: foldReleaseFallback
        interval: 150
        onTriggered: root._foldAnimating = false
    }

    onHeightChanged: {
        if (_foldAnimating && !foldAnim.running) {
            if (Math.abs(height - _animatedBodyHeight) < 2) {
                _foldAnimating = false;
                foldReleaseFallback.stop();
            }
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root._bodyHeight
        radius: Theme.cornerRadius
        color: root.accentPalette.bodyBg
        clip: true

        StickyTitleBar {
            id: titleBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            accentPalette: root.accentPalette
            pinned: root.pinned
            folded: root.folded
            title: root.titleLine

            onColorClicked: {
                menu.visible = false;
                trashPopover.visible = false;
                colorPalette.visible = !colorPalette.visible;
            }
            onAddClicked: {
                colorPalette.visible = false;
                menu.visible = false;
                trashPopover.visible = false;
                root._newSticky();
            }
            onPinClicked: {
                colorPalette.visible = false;
                menu.visible = false;
                trashPopover.visible = false;
                root.setData("showOnOverlay", !root.pinned);
            }
            onFoldClicked: {
                colorPalette.visible = false;
                menu.visible = false;
                trashPopover.visible = false;
                root._toggleFold();
            }
            onMenuClicked: {
                colorPalette.visible = false;
                trashPopover.visible = false;
                menu.visible = !menu.visible;
            }
            onDragStarted: root._dragStart()
            onDragMoved: (dx, dy) => root._dragMove(dx, dy)
        }

        Item {
            id: toolbar
            visible: !root.folded && root.showToolbar
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.toolbarHeight

            readonly property var _buttons: [
                { icon: "format_bold",          act: "bold" },
                { icon: "format_italic",        act: "italic" },
                { icon: "format_strikethrough", act: "strike" },
                { icon: "code",                 act: "code" },
                { divider: true },
                { icon: "format_h1",            act: "h1" },
                { icon: "format_h2",            act: "h2" },
                { icon: "format_h3",            act: "h3" },
                { divider: true },
                { icon: "format_list_bulleted", act: "bullet" },
                { icon: "format_list_numbered", act: "numbered" },
                { icon: "check_box",            act: "checkbox" },
                { icon: "format_quote",         act: "quote" },
                { divider: true },
                { icon: "link",                 act: "link" }
            ]

            Flickable {
                id: tbScroll
                anchors.fill: parent
                contentWidth: tbRow.implicitWidth + Theme.spacingS * 2
                contentHeight: height
                clip: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: tbRow
                    x: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Repeater {
                        model: toolbar._buttons

                        Item {
                            width: modelData.divider ? 8 : 22
                            height: 22

                            Rectangle {
                                visible: modelData.divider === true
                                anchors.centerIn: parent
                                width: 1
                                height: 12
                                color: Qt.rgba(0, 0, 0, 0.18)
                            }

                            Loader {
                                active: modelData.divider !== true
                                anchors.fill: parent

                                sourceComponent: Item {
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        radius: 3
                                        color: btnHover.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                                    }

                                    DankIcon {
                                        anchors.centerIn: parent
                                        name: modelData.icon
                                        size: 13
                                        color: root.accentPalette?.text ?? Theme.surfaceText
                                        opacity: btnHover.containsMouse ? 1.0 : 0.75
                                    }

                                    MouseArea {
                                        id: btnHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton
                                        onClicked: root._applyAction(modelData.act)
                                    }
                                }
                            }
                        }
                    }
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const max = Math.max(0, tbScroll.contentWidth - tbScroll.width);
                        if (max <= 0) {
                            event.accepted = false;
                            return;
                        }
                        const delta = event.angleDelta.y || event.angleDelta.x;
                        tbScroll.contentX = Math.max(0, Math.min(max, tbScroll.contentX - delta));
                        event.accepted = true;
                    }
                }
            }
        }

        StickyEditor {
            id: editor
            anchors.top: toolbar.visible ? toolbar.bottom : titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Theme.spacingS
            anchors.rightMargin: Theme.spacingS
            anchors.bottomMargin: Theme.spacingS
            anchors.topMargin: Theme.spacingXS
            visible: !root.folded
            instanceId: root.instanceId
            storageDir: root.storageDir
            textColor: root.accentPalette.text
            selectionColor: root.accentPalette.accent
            selectedTextColor: root.accentPalette.bodyBg
        }

        ColorPalette {
            id: colorPalette
            visible: false
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.topMargin: Theme.spacingXS
            anchors.leftMargin: Theme.spacingS
            current: root.accentName
            z: 10

            onPick: name => {
                root.setData("accent", name);
                visible = false;
            }
        }

        Rectangle {
            id: menu
            visible: false
            anchors.top: titleBar.bottom
            anchors.right: parent.right
            anchors.topMargin: Theme.spacingXS
            anchors.rightMargin: Theme.spacingXS
            width: 180
            height: menuColumn.implicitHeight + Theme.spacingS * 2
            color: Theme.surface
            radius: Theme.cornerRadius
            border.color: Theme.outlineVariant
            border.width: 1
            z: 10

            Column {
                id: menuColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingS
                spacing: 0

                Repeater {
                    model: [
                        { icon: root.showToolbar ? "visibility_off" : "visibility", label: root.showToolbar ? "Hide toolbar" : "Show toolbar", action: "toggleToolbar" },
                        { icon: "content_copy", label: "Duplicate", action: "duplicate" },
                        { icon: "text_snippet", label: "Copy as Markdown", action: "copy" },
                        { icon: "restore_from_trash", label: "Restore from trash…", action: "restore" },
                        { icon: "delete_sweep", label: "Empty trash", action: "emptyTrash" },
                        { icon: "delete", label: "Delete", action: "delete", danger: true }
                    ]

                    Item {
                        width: parent.width
                        height: 28

                        readonly property var item: modelData

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: rowHover.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingXS
                            spacing: Theme.spacingS

                            DankIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: parent.parent.item.icon
                                size: 14
                                color: parent.parent.item.danger ? Theme.error : Theme.surfaceText
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.item.label
                                font.pixelSize: Theme.fontSizeSmall
                                color: parent.parent.item.danger ? Theme.error : Theme.surfaceText
                            }
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                menu.visible = false;
                                root._handleMenuAction(parent.item.action);
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: trashPopover
            visible: false
            anchors.top: titleBar.bottom
            anchors.right: parent.right
            anchors.topMargin: Theme.spacingXS
            anchors.rightMargin: Theme.spacingXS
            width: 280
            height: 220
            color: Theme.surface
            radius: Theme.cornerRadius
            border.color: Theme.outlineVariant
            border.width: 1
            z: 11

            property var trashItems: []

            function refresh() {
                const cmd = "cd '" + root.storageDir + "/trash' 2>/dev/null && for f in *.md; do "
                          + "[ -f \"$f\" ] || continue; "
                          + "line=$(head -n1 \"$f\" 2>/dev/null | head -c 80); "
                          + "[ -z \"$line\" ] && line='(empty)'; "
                          + "mtime=$(stat -c %Y \"$f\" 2>/dev/null); "
                          + "printf '%s|%s|%s\\n' \"$f\" \"$mtime\" \"$line\"; "
                          + "done | sort -t'|' -k2 -nr";
                Proc.runCommand("dmsStickies.trash.list." + root.instanceId, ["sh", "-c", cmd], (stdout, exitCode) => {
                    const raw = (stdout || "").trim();
                    if (!raw) {
                        trashItems = [];
                        return;
                    }
                    const lines = raw.split("\n").filter(l => l.length > 0);
                    const items = [];
                    for (var i = 0; i < lines.length; i++) {
                        const l = lines[i];
                        const i1 = l.indexOf("|");
                        const i2 = l.indexOf("|", i1 + 1);
                        if (i1 < 0 || i2 < 0)
                            continue;
                        const fname = l.slice(0, i1);
                        items.push({
                            id: fname.replace(/\.md$/, ""),
                            mtime: parseInt(l.slice(i1 + 1, i2), 10) || 0,
                            preview: l.slice(i2 + 1) || "(empty)"
                        });
                    }
                    trashItems = items;
                }, 0);
            }

            Column {
                id: trashHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacingS
                spacing: Theme.spacingXS

                StyledText {
                    text: "Restore from trash"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }
            }

            ListView {
                id: trashList
                anchors.top: trashHeader.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacingS
                anchors.topMargin: Theme.spacingXS
                clip: true
                spacing: 0
                model: trashPopover.trashItems
                boundsBehavior: Flickable.StopAtBounds
                visible: trashPopover.trashItems.length > 0

                delegate: Item {
                    width: trashList.width
                    height: 30

                    readonly property var item: modelData

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: rh.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                    }

                    StyledText {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingXS
                        anchors.rightMargin: Theme.spacingXS
                        text: parent.item.preview
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    MouseArea {
                        id: rh
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: root._restoreFromTrash(parent.item.id)
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: trashHeader.height / 2
                visible: trashPopover.trashItems.length === 0
                text: "Trash is empty"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }

    function _applyAction(name) {
        const t = editor.text;
        const a = editor.selectionStart;
        const b = editor.selectionEnd;
        let r = null;
        switch (name) {
        case "bold":     r = MD.toggleWrap(t, a, b, "**"); break;
        case "italic":   r = MD.toggleWrap(t, a, b, "*"); break;
        case "strike":   r = MD.toggleWrap(t, a, b, "~~"); break;
        case "code":     r = MD.toggleWrap(t, a, b, "`"); break;
        case "h1":       r = MD.toggleHeading(t, a, b, 1); break;
        case "h2":       r = MD.toggleHeading(t, a, b, 2); break;
        case "h3":       r = MD.toggleHeading(t, a, b, 3); break;
        case "bullet":   r = MD.togglePrefix(t, a, b, "- "); break;
        case "numbered": r = MD.togglePrefix(t, a, b, "1. "); break;
        case "checkbox": r = MD.toggleCheckbox(t, a, b); break;
        case "quote":    r = MD.togglePrefix(t, a, b, "> "); break;
        case "link":     r = MD.insertLink(t, a, b); break;
        }
        if (r)
            editor.setEditorState(r.newText, r.selStart, r.selEnd);
    }

    function _handleMenuAction(action) {
        switch (action) {
        case "toggleToolbar":
            root.setData("showToolbar", !root.showToolbar);
            break;
        case "duplicate":
            _newSticky(true);
            break;
        case "copy":
            _copyMarkdown();
            break;
        case "restore":
            trashPopover.refresh();
            trashPopover.visible = true;
            break;
        case "emptyTrash":
            _emptyTrash();
            break;
        case "delete":
            _deleteSticky();
            break;
        }
    }

    function _toggleFold() {
        if (foldAnim.running)
            return;
        // On Hyprland, the compositor animates layer-shell window resizes itself.
        // Skip the in-plugin body animation so we don't double-animate (otherwise
        // Hyprland's surface scale at the end of the fold visibly squishes the
        // already-shrunk content). The wrapper height write triggers Hyprland's
        // own resize animation, which provides the fold visual.
        if (CompositorService.isHyprland) {
            if (root.folded) {
                const target = pluginData.unfoldedHeight ?? defaultHeight;
                root.setData("folded", false);
                _setAllPositionsHeight(target);
            } else {
                root.setData("unfoldedHeight", widgetHeight);
                root.setData("folded", true);
                _setAllPositionsHeight(titleBarHeight);
            }
            return;
        }
        if (root.folded) {
            // Unfold: grow wrapper window first (instant), then animate body height up.
            const target = pluginData.unfoldedHeight ?? defaultHeight;
            _animatedBodyHeight = titleBarHeight;
            _foldAnimating = true;
            root.setData("folded", false);
            _setAllPositionsHeight(target);
            foldAnim._foldDirection = false;
            foldAnim.from = titleBarHeight;
            foldAnim.to = target;
            foldAnim.start();
        } else {
            // Fold: animate body height down first, then snap wrapper window small.
            const startH = widgetHeight;
            root.setData("unfoldedHeight", startH);
            _animatedBodyHeight = startH;
            _foldAnimating = true;
            foldAnim._foldDirection = true;
            foldAnim.from = startH;
            foldAnim.to = titleBarHeight;
            foldAnim.start();
        }
    }

    function _setAllPositionsHeight(h) {
        const positions = instanceData?.positions ?? {};
        const keys = Object.keys(positions);
        if (keys.length === 0)
            return;
        for (var i = 0; i < keys.length; i++)
            SettingsData.updateDesktopWidgetInstancePosition(instanceId, keys[i], { height: h });
    }

    // Left-click drag on the title bar — moves the wrapper window. Sync mode
    // ("_synced" position with normalized fractions) is skipped; right-click drag
    // continues to work in that case.
    property real _dragOriginX: 0
    property real _dragOriginY: 0
    property string _dragKey: ""

    function _dragStart() {
        const positions = instanceData?.positions ?? {};
        const keys = Object.keys(positions).filter(k => k !== "_synced");
        if (keys.length === 0) {
            _dragKey = "";
            return;
        }
        const k = keys[0];
        _dragKey = k;
        _dragOriginX = positions[k]?.x ?? 0;
        _dragOriginY = positions[k]?.y ?? 0;
    }

    function _dragMove(dx, dy) {
        if (_dragKey === "")
            return;
        SettingsData.updateDesktopWidgetInstancePosition(instanceId, _dragKey, {
            x: _dragOriginX + dx,
            y: _dragOriginY + dy
        });
    }

    function _newSticky(copyContent) {
        const newInst = SettingsData.duplicateDesktopWidgetInstance(instanceId);
        if (!newInst) {
            ToastService.showError("Failed to create sticky");
            return;
        }
        // duplicateDesktopWidgetInstance appends " (Copy)" — strip it
        SettingsData.updateDesktopWidgetInstance(newInst.id, { name: "DMS Stickies" });
        SettingsData.updateDesktopWidgetInstanceConfig(newInst.id, {
            folded: false
        });
        if (copyContent === true) {
            const src = storageDir + "/notes/" + instanceId + ".md";
            const dst = storageDir + "/notes/" + newInst.id + ".md";
            Quickshell.execDetached(["sh", "-c", "mkdir -p '" + storageDir + "/notes' && cp '" + src + "' '" + dst + "' 2>/dev/null || true"]);
        }
    }

    function _copyMarkdown() {
        const text = editor.text || "";
        if (text.length === 0) {
            ToastService.showInfo("Sticky is empty");
            return;
        }
        Proc.runCommand("dmsStickies.copy." + instanceId, ["dms", "cl", "copy", text], (stdout, exitCode) => {
            if (exitCode === 0)
                ToastService.showInfo("Copied " + text.length + " chars");
            else
                ToastService.showError("Copy failed (exit " + exitCode + ")");
        }, 0);
    }

    function _deleteSticky() {
        editor.stopSaving();
        const src = storageDir + "/notes/" + instanceId + ".md";
        const dst = storageDir + "/trash/" + instanceId + ".md";
        Quickshell.execDetached(["sh", "-c", "mkdir -p '" + storageDir + "/trash' && mv '" + src + "' '" + dst + "' 2>/dev/null || true"]);
        SettingsData.removeDesktopWidgetInstance(instanceId);
        ToastService.showInfo("Sticky moved to trash");
    }

    function _restoreFromTrash(trashedId) {
        const newInst = SettingsData.createDesktopWidgetInstance("dmsStickies", "DMS Stickies", {
            accent: "yellow",
            folded: false,
            showOnOverlay: false
        });
        if (!newInst) {
            ToastService.showError("Failed to restore sticky");
            return;
        }
        const src = storageDir + "/trash/" + trashedId + ".md";
        const dst = storageDir + "/notes/" + newInst.id + ".md";
        Quickshell.execDetached(["sh", "-c", "mkdir -p '" + storageDir + "/notes' && mv '" + src + "' '" + dst + "' 2>/dev/null"]);
        ToastService.showInfo("Sticky restored");
        Qt.callLater(() => trashPopover.refresh());
    }

    function _emptyTrash() {
        const dir = storageDir + "/trash";
        Proc.runCommand("dmsStickies.trash.empty." + instanceId, ["sh", "-c",
            "[ -d '" + dir + "' ] || exit 0; "
            + "n=$(find '" + dir + "' -maxdepth 1 -name '*.md' -type f | wc -l); "
            + "rm -f '" + dir + "'/*.md 2>/dev/null; "
            + "echo $n"
        ], (stdout, exitCode) => {
            const n = parseInt((stdout || "0").trim(), 10) || 0;
            if (n === 0)
                ToastService.showInfo("Trash is already empty");
            else
                ToastService.showInfo("Permanently deleted " + n + " sticky" + (n === 1 ? "" : "s"));
            if (trashPopover.visible)
                trashPopover.refresh();
        }, 0);
    }
}
