import QtQuick
import qs.Common
import "Palette.js" as Palette

Item {
    id: root

    property string current: ""
    signal pick(string name)

    readonly property int swatchSize: 22
    readonly property int cols: 4
    readonly property int rows: 2
    readonly property int gap: Theme.spacingXS
    readonly property int pad: Theme.spacingS

    width: cols * swatchSize + (cols - 1) * gap + 2 * pad
    height: rows * swatchSize + (rows - 1) * gap + 2 * pad

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: Theme.cornerRadius
        border.color: Theme.outlineVariant
        border.width: 1
    }

    Grid {
        anchors.centerIn: parent
        columns: root.cols
        spacing: root.gap

        Repeater {
            model: Palette.names()

            Item {
                width: root.swatchSize
                height: root.swatchSize

                readonly property string accentName: modelData
                readonly property var pal: Palette.get(modelData)
                readonly property bool isCurrent: root.current === modelData

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: parent.pal.accent
                    border.color: parent.isCurrent ? Theme.surfaceText : Qt.darker(color, 1.4)
                    border.width: parent.isCurrent ? 2 : 1
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.pick(parent.accentName)
                }
            }
        }
    }
}
