import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property var accentPalette: ({})
    property bool pinned: false
    property bool folded: false
    property string title: ""

    signal colorClicked
    signal addClicked
    signal pinClicked
    signal foldClicked
    signal menuClicked
    signal dragStarted
    signal dragMoved(real dx, real dy)
    signal dragEnded(bool cancelled)

    height: 28

    Rectangle {
        anchors.fill: parent
        color: root.accentPalette?.headerBg ?? Theme.surfaceContainerHigh
        topLeftRadius: Theme.cornerRadius
        topRightRadius: Theme.cornerRadius
        bottomLeftRadius: root.folded ? Theme.cornerRadius : 0
        bottomRightRadius: root.folded ? Theme.cornerRadius : 0

        Rectangle {
            visible: !root.folded
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(0, 0, 0, 0.1)
        }
    }

    // Drag handle for left-click move. Sits below the swatch/buttons in z-order
    // (declared earlier than them) so their own MouseAreas still receive clicks.
    MouseArea {
        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real _startGlobalX: 0
        property real _startGlobalY: 0
        property real _lastDx: 0
        property real _lastDy: 0
        // Drag is live from the first frame for zero-latency feel. On release,
        // if the cursor never travelled past the platform threshold the move
        // is treated as accidental and Sticky.qml snaps the position back.
        readonly property int _threshold: Qt.styleHints.startDragDistance

        onPressed: function (mouse) {
            const g = mapToGlobal(mouse.x, mouse.y);
            _startGlobalX = g.x;
            _startGlobalY = g.y;
            _lastDx = 0;
            _lastDy = 0;
            root.dragStarted();
        }

        onPositionChanged: function (mouse) {
            if (!pressed)
                return;
            const g = mapToGlobal(mouse.x, mouse.y);
            _lastDx = g.x - _startGlobalX;
            _lastDy = g.y - _startGlobalY;
            root.dragMoved(_lastDx, _lastDy);
        }

        onReleased: {
            const cancelled = Math.abs(_lastDx) < _threshold && Math.abs(_lastDy) < _threshold;
            root.dragEnded(cancelled);
        }

        onDoubleClicked: root.foldClicked()
    }

    Rectangle {
        id: swatch
        width: 14
        height: 14
        radius: 7
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        color: root.accentPalette?.accent ?? Theme.primary
        border.color: Qt.darker(color, 1.5)
        border.width: 1

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: root.colorClicked()
        }
    }

    StyledText {
        id: titleText
        anchors.left: swatch.right
        anchors.leftMargin: Theme.spacingS
        anchors.right: buttonsRow.left
        anchors.rightMargin: Theme.spacingXS
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: root.accentPalette?.text ?? Theme.surfaceText
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        opacity: 1
        wrapMode: Text.NoWrap
        maximumLineCount: 1
        elide: Text.ElideRight
        clip: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Row {
        id: buttonsRow
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXS
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Item {
            width: 24
            height: 24

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 4
                color: addHover.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
            }

            DankIcon {
                anchors.centerIn: parent
                name: "add"
                size: 14
                color: root.accentPalette?.text ?? Theme.surfaceText
                opacity: 0.85
            }

            MouseArea {
                id: addHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: root.addClicked()
            }
        }

        Item {
            width: 24
            height: 24

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 4
                color: pinHover.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
            }

            DankIcon {
                anchors.centerIn: parent
                name: "push_pin"
                size: 14
                color: root.accentPalette?.text ?? Theme.surfaceText
                filled: root.pinned
                opacity: root.pinned ? 1.0 : 0.6
            }

            MouseArea {
                id: pinHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: root.pinClicked()
            }
        }

        Item {
            width: 24
            height: 24

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 4
                color: foldHover.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
            }

            DankIcon {
                anchors.centerIn: parent
                name: root.folded ? "unfold_more" : "unfold_less"
                size: 14
                color: root.accentPalette?.text ?? Theme.surfaceText
                opacity: 0.8
            }

            MouseArea {
                id: foldHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: root.foldClicked()
            }
        }

        Item {
            width: 24
            height: 24

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 4
                color: menuHover.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
            }

            DankIcon {
                anchors.centerIn: parent
                name: "more_vert"
                size: 14
                color: root.accentPalette?.text ?? Theme.surfaceText
                opacity: 0.8
            }

            MouseArea {
                id: menuHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: root.menuClicked()
            }
        }
    }
}
