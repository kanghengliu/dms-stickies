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

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: root.accentPalette.bodyBg
        border.color: Qt.rgba(0, 0, 0, 0.18)
        border.width: 1
        clip: true

        StickyTitleBar {
            id: titleBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            accentPalette: root.accentPalette
            pinned: root.pinned
            folded: root.folded

            onColorClicked: {
                menu.visible = false;
                colorPalette.visible = !colorPalette.visible;
            }
            onAddClicked: {
                colorPalette.visible = false;
                menu.visible = false;
                root._newSticky();
            }
            onPinClicked: {
                colorPalette.visible = false;
                menu.visible = false;
                root.setData("showOnOverlay", !root.pinned);
            }
            onFoldClicked: {
                colorPalette.visible = false;
                menu.visible = false;
                root._toggleFold();
            }
            onMenuClicked: {
                colorPalette.visible = false;
                menu.visible = !menu.visible;
            }
        }

        Item {
            id: toolbar
            visible: !root.folded
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
                        { icon: "content_copy", label: "Duplicate", action: "duplicate" },
                        { icon: "text_snippet", label: "Copy as Markdown", action: "copy" },
                        { icon: "restore_from_trash", label: "Restore from trash…", action: "restore" },
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
        case "duplicate":
            _newSticky(true);
            break;
        case "copy":
            _copyMarkdown();
            break;
        case "restore":
            _restoreLast();
            break;
        case "delete":
            _deleteSticky();
            break;
        }
    }

    function _toggleFold() {
        if (root.folded) {
            const h = pluginData.unfoldedHeight ?? defaultHeight;
            root.setData("folded", false);
            _setAllPositionsHeight(h);
        } else {
            root.setData("unfoldedHeight", widgetHeight);
            root.setData("folded", true);
            _setAllPositionsHeight(titleBarHeight);
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

    function _newSticky(copyContent) {
        const newInst = SettingsData.duplicateDesktopWidgetInstance(instanceId);
        if (!newInst) {
            ToastService.showError("Failed to create sticky");
            return;
        }
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

    function _restoreLast() {
        ToastService.showInfo("Trash restore UI coming in M6 — files are at " + storageDir + "/trash/");
    }
}
