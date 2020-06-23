import QtQuick 2.7
import QtQuick.Controls 2.0
import QtMultimedia 5.9
import "../../fonts"
import "../controls"

Popup{
    id: control
    width: parent.width * 0.5
    height: container.height * 1.1
    x: parent.width * 0.25
    y: parent.height * 0.2
    z: 200
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    property var afterConfirmationFunc

    function confirmation(title, message, afterConfirmation) {
        titleText.text = title;
        messageText.text = message;
        afterConfirmationFunc = afterConfirmation;
        open();
        confirmationSound.play();
    }

    SoundEffect {
        id: confirmationSound
        source: "../../sounds/confirmation.wav"
    }

    Rectangle{
        id: container
        width: parent.width - 40
        height: 140 + messageText.height
        anchors.centerIn: parent
        Text {
            id: titleText
            color: "slategray"
            font.pixelSize: 24
            font.family: Fonts.fontRubikRegular.name
            anchors.top: parent.top
            width: parent.width
            horizontalAlignment: "AlignHCenter"
        }
        Text {
            id: messageText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleText.bottom
            anchors.topMargin: 20
            font.family: Fonts.fontRubikRegular.name
            color: "#545454"
            font.pixelSize: 18
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
        Button {
            id:cancelButton
            text: "Vazgeç"
            height: 40
            width: 100
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            font.pixelSize: 20
            onClicked:{
                close();
            }
        }

        Button {
            id:confirmButton
            text: "Tamam"
            height: 40
            width: 100
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            font.pixelSize: 20
            borderColor: "mediumseagreen"
            onClicked:{
                close();
                afterConfirmationFunc();
            }
        }
    }
}
