import QtQuick 2.7
import QtQuick.Controls 2.0
import "../../fonts"

Button {
    id: control
    spacing: 5
    height: 40
    width: 80
    padding: 10
    font.pixelSize: 22
    font.family: Fonts.fontBarlowRegular.name
    property color borderColor: "lightslategray"
    contentItem: Text {
            text: control.text
            font: control.font
            color: control.pressed?"white":borderColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    background: Rectangle {
        border.color: borderColor
        border.width: 1
        color: control.pressed?borderColor:"#f7f8f9"
    }
}
