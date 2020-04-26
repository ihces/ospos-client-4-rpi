import QtQuick 2.7
import QtQuick.Controls 2.0
import "../../fonts"

Text {
    id: control
    property Text labelOf
    anchors.left: labelOf.left
    anchors.top: labelOf.top
    anchors.leftMargin: labelOf.anchors.leftMargin
    anchors.rightMargin: labelOf.anchors.rightMargin
    anchors.topMargin: 0
    visible: labelOf.parent.parent.activeFocus
    font.family: Fonts.fontRubikRegular.name
    color: labelOf.color
    opacity: 0.48
    font.pixelSize: 11
    width: labelOf.width
    horizontalAlignment: labelOf.horizontalAlignment
}
