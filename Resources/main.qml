import QtQuick 2.7
import QtQuick.Controls 2.0
import posapp.restrequest 1.0

import "./fonts"
import "./view/controls"

ApplicationWindow {
    id: window
    visible: true
    property ApplicationWindow appWindow : window
    property BusyIndicator busyIndicator: busyIndication
    property StackView stack: stackView
    width: 800
    height: 480
    title: qsTr("PosApp")

    BusyIndicator {
        id: busyIndication
        anchors.centerIn: parent
        running: false
        z: 100
    }

    ToastManager{
        id: toast
    }

    RestRequest{
        id: restRequest
        onLoginCompleted: {
            if (succeed){
                loginPopup.close();
                toast.showSuccess("Giriş Başarılı", 3000);
            }
        }
        onStart: {busyIndicator.running = true}
        onEnd: {busyIndicator.running = false}
    }

    Popup{
        id: loginPopup
        width: parent.width * 0.5
        height: parent.height * 0.6
        x: parent.width * 0.25
        y: parent.height * 0.2
        z: 98
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Rectangle{
            width: parent.width * 0.9
            height: parent.height * 0.9
            anchors.centerIn: parent
            Text {
                id: userIcon
                text: "\uF502"
                color: "slategray"
                font.pixelSize: 42
                font.family: Fonts.fontAwesomeSolid.name
                anchors.top: parent.top
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            TextField {
                id: userNameField
                required: true
                anchors.right: parent.right
                anchors.top: userIcon.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 35
                width: parent.width
                font.family: Fonts.fontProductRegular.name
                placeholderText: "Kullanıcı"
            }
            TextField {
                id: passwordField
                required: true
                echoMode: TextInput.Password
                anchors.right: parent.right
                anchors.top: userNameField.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 5
                width: parent.width
                font.family: Fonts.fontProductRegular.name
                placeholderText: "Şifre"
            }

            Button {
                id:loginButton
                text: "Giriş"
                height: 40
                width: parent.width
                anchors.bottom: parent.bottom
                onClicked: {
                    userNameField.needValidate = true;
                    passwordField.needValidate = true;

                    if (userNameField.isInvalid() || passwordField.isInvalid())
                        toast.showError("Gerekli Alanlar Boş Bırakılamaz!", 3000);
                    else
                        restRequest.login(userNameField.text, passwordField.text)
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        clicked();
                    }
                }
            }
        }
    }

    header: ToolBar {
        background: Rectangle{
            anchors.fill: parent
            color: "slategray"
        }
        contentHeight: 40
        z: 97

        ToolButton {
            id: toolButton
            text: stackView.depth > 1 ? "\u25C0" : ""
            font.pixelSize: 24
            activeFocusOnTab: true
            height: parent.height
            anchors.left: parent.left
            padding: 10
            background: Rectangle{
                anchors.fill: parent
                color: stackView.depth > 1 && toolButton.checked?"steelblue": (stackView.depth > 1 && toolButton.activeFocus?"dodgerblue":"slategray")
            }
            onClicked: {
                if (stackView.depth > 1) {
                    stackView.pop()
                }
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }

        ToolButton {
            id: toolButton2
            activeFocusOnTab: true
            text: "ibrahim hakkı"
            font.pixelSize: 14
            height: parent.height
            anchors.right: parent.right
            padding: 10
            background: Rectangle{
                anchors.fill:parent
                color: toolButton2.checked?"steelblue": (toolButton2.activeFocus?"dodgerblue":"slategray")
            }
            onClicked: {
                loginPopup.open()
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    if (stackView.depth > 1) {
                        stackView.pop()
                    } else {
                        drawer.open()
                    }
                }
            }
        }

        Label {
            text: stackView.currentItem.title
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 24
            font.family: Fonts.fontBlackOpsOneRegular.name
        }
    }

    StackView {
        id: stackView
        initialItem: "view/page/Home.qml"
        anchors.fill: parent
        z: 96
        onCurrentItemChanged: {
            if (currentItem.title === "Giriş" && restRequest.isSessionTimeout)
                loginPopup.open();
        }
    }
}
