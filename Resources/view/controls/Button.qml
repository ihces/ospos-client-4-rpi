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
            color: (control.activeFocus || control.pressed)?"white":(control.enabled?borderColor:"#79545454")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    background: Rectangle {
        border.color: control.enabled?borderColor:"#c4d5e6"
        border.width: 1
        color: (control.activeFocus || control.pressed)?borderColor:(control.enabled?"#f7f8f9":"white")
        opacity: (control.activeFocus && !control.pressed)?0.7:1.0
    }
}
