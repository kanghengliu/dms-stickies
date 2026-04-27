import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets

Item {
    id: root

    property string instanceId: ""
    property string storageDir: ""
    property color textColor: Theme.surfaceText
    property color selectionColor: Theme.primary
    property color selectedTextColor: Theme.background

    readonly property string filePath: instanceId !== "" && storageDir !== "" ? (storageDir + "/notes/" + instanceId + ".md") : ""

    property bool _loaded: false
    property bool _selfWrite: false
    property bool _suppressSave: false
    property string _lastSavedText: ""

    readonly property alias text: editor.text
    readonly property alias selectionStart: editor.selectionStart
    readonly property alias selectionEnd: editor.selectionEnd
    readonly property alias hasFocus: editor.activeFocus

    function stopSaving() {
        saveDebounce.stop();
        _loaded = false;
    }

    function setEditorState(newText, selStart, selEnd) {
        if (!_loaded)
            return;
        _suppressSave = true;
        editor.text = newText;
        _suppressSave = false;
        saveDebounce.restart();
        if (selStart === selEnd)
            editor.cursorPosition = selStart;
        else
            editor.select(selStart, selEnd);
        editor.forceActiveFocus();
    }

    Component.onCompleted: {
        if (storageDir !== "")
            Quickshell.execDetached(["mkdir", "-p", storageDir + "/notes"]);
    }

    onFilePathChanged: {
        _loaded = false;
        _lastSavedText = "";
        _selfWrite = false;
        _suppressSave = true;
        editor.text = "";
        _suppressSave = false;
        retryTimer.stop();
    }

    DankFlickable {
        id: scroller
        anchors.fill: parent
        clip: true
        contentWidth: width

        TextArea.flickable: TextArea {
            id: editor
            wrapMode: TextArea.Wrap
            textFormat: TextEdit.PlainText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMedium
            color: root.textColor
            selectionColor: root.selectionColor
            selectedTextColor: root.selectedTextColor
            selectByMouse: true
            selectByKeyboard: true
            persistentSelection: true
            readOnly: !root._loaded
            focus: true
            activeFocusOnPress: true
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            leftPadding: 0
            topPadding: 0
            rightPadding: 0
            bottomPadding: 0
            background: null

            onTextChanged: {
                if (!root._loaded || root._suppressSave)
                    return;
                saveDebounce.restart();
            }
        }
    }

    Timer {
        id: saveDebounce
        interval: 150
        repeat: false
        onTriggered: root._save()
    }

    Timer {
        id: reloadDebounce
        interval: 50
        repeat: false
        onTriggered: noteFile.reload()
    }

    Timer {
        id: retryTimer
        interval: 500
        repeat: false
        onTriggered: noteFile.reload()
    }

    FileView {
        id: noteFile
        path: root.filePath
        blockWrites: true
        atomicWrites: true
        watchChanges: true
        printErrors: false

        onLoaded: {
            const fileText = noteFile.text() || "";
            if (!root._loaded || editor.text === root._lastSavedText) {
                root._suppressSave = true;
                editor.text = fileText;
                root._lastSavedText = fileText;
                root._suppressSave = false;
            }
            root._loaded = true;
        }

        onLoadFailed: function (error) {
            if (!root._loaded) {
                root._suppressSave = true;
                editor.text = "";
                root._lastSavedText = "";
                root._suppressSave = false;
                retryTimer.restart();
            }
            root._loaded = true;
        }

        onFileChanged: {
            if (root._selfWrite) {
                root._selfWrite = false;
                return;
            }
            reloadDebounce.restart();
        }
    }

    function _save() {
        if (!_loaded || filePath === "")
            return;
        const txt = editor.text;
        _lastSavedText = txt;
        _selfWrite = true;
        noteFile.setText(txt);
    }

    Component.onDestruction: {
        if (saveDebounce.running) {
            saveDebounce.stop();
            _save();
        }
    }
}
