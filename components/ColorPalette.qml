import QtQuick
import qs.Common
import "Palette.js" as Palette

Item {
    id: root

    property string current: ""
    property real alpha: 1.0
    signal pick(string name)
    signal alphaPicked(real value)
    signal alphaDragStarted
    signal alphaDragEnded

    readonly property int swatchSize: 22
    readonly property int cols: 4
    readonly property int rows: 2
    readonly property int gap: Theme.spacingXS
    readonly property int pad: Theme.spacingS
    readonly property real alphaMin: 0.2
    readonly property real alphaMax: 1.0

    readonly property int swatchAreaW: cols * swatchSize + (cols - 1) * gap
    readonly property int swatchAreaH: rows * swatchSize + (rows - 1) * gap
    readonly property int sliderH: 14

    width: swatchAreaW + 2 * pad
    height: pad + swatchAreaH + Theme.spacingXS + 1 + Theme.spacingXS + sliderH + pad

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: Theme.cornerRadius
        border.color: Theme.outlineVariant
        border.width: 1
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Theme.spacingXS

        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
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

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        // Compact opacity slider — no internal value state. The thumb position
        // is derived from root.alpha; dragging emits alphaPicked, parent writes
        // back to pluginData, root.alpha re-binds, thumb follows.
        Item {
            id: alphaSlider
            width: parent.width
            height: root.sliderH

            readonly property real ratio: (root.alpha - root.alphaMin) / (root.alphaMax - root.alphaMin)
            readonly property int thumbSize: 10
            readonly property int trackHeight: 3

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: alphaSlider.trackHeight
                radius: height / 2
                color: Theme.outlineVariant

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: Math.max(0, Math.min(1, alphaSlider.ratio)) * parent.width
                    radius: parent.radius
                    color: Theme.primary
                }
            }

            Rectangle {
                id: thumb
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(1, alphaSlider.ratio)) * (alphaSlider.width - width)
                width: alphaSlider.thumbSize
                height: alphaSlider.thumbSize
                radius: width / 2
                color: Theme.primary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onPressed: function (mouse) {
                    root.alphaDragStarted();
                    _set(mouse.x);
                }
                onPositionChanged: function (mouse) {
                    if (pressed)
                        _set(mouse.x);
                }
                onReleased: root.alphaDragEnded()

                function _set(x) {
                    const half = alphaSlider.thumbSize / 2;
                    const usable = Math.max(1, alphaSlider.width - alphaSlider.thumbSize);
                    const r = Math.max(0, Math.min(1, (x - half) / usable));
                    const v = root.alphaMin + r * (root.alphaMax - root.alphaMin);
                    // Snap to 5% steps.
                    const snapped = Math.round(v * 20) / 20;
                    if (Math.abs(snapped - root.alpha) > 0.001)
                        root.alphaPicked(snapped);
                }
            }
        }
    }
}
