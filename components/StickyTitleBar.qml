import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    property var accentPalette: ({})
    property bool pinned: false
    property bool folded: false

    signal colorClicked
    signal addClicked
    signal pinClicked
    signal foldClicked
    signal menuClicked

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

    Row {
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
