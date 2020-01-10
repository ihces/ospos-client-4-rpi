import QtQuick 2.7
import QtQuick.Controls 2.0
import posapp.restrequest 1.0

import "./fonts"

ApplicationWindow {
    id: window
    visible: true
    //visibility: ApplicationWindow.FullScreen
    width: 800
    height: 480
    title: qsTr("PosApp")

    RestRequest{
        id: restRequest
        onLoginCompleted: {
            if (succeed)
                loginPopup.close();
        }
    }

    Popup{
        id: loginPopup
        width: parent.width * 0.5
        height: parent.height * 0.6
        x: parent.width * 0.25
        y: parent.height * 0.2
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
                font.pointSize: 16
                activeFocusOnTab: true
                focus: true
                anchors.right: parent.right
                anchors.top: userIcon.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 35
                width: parent.width
                height: 40
                font.family: Fonts.fontProductRegular.name
                placeholderText: "Kullanıcı"
                background: Rectangle {
                    border.color: parent.activeFocus?"dodgerblue":"slategray"
                    border.width: 1
                    color: parent.activeFocus ?"dodgerblue": "white"
                }
                color: activeFocus ? "white": "slategray"
            }
            TextField {
                id: passwordField
                echoMode: TextInput.Password
                font.pointSize: 16
                activeFocusOnTab: true
                focus: true
                anchors.right: parent.right
                anchors.top: userNameField.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 5
                width: parent.width
                height: 40
                font.family: Fonts.fontProductRegular.name
                placeholderText: "Şifre"
                background: Rectangle {
                    border.color: parent.activeFocus?"dodgerblue":"slategray"
                    border.width: 1
                    color: parent.activeFocus ?"dodgerblue": "white"
                }
                color: activeFocus ? "white": "slategray"
            }

            Button {
                id:loginButton
                text: "Giriş"
                autoExclusive: false
                height: 40
                width: parent.width
                anchors.bottom: parent.bottom
                checkable: true
                font.family: Fonts.fontBarlowRegular.name
                font.pointSize: 24
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        checked = true
                        restRequest.login(userNameField.text, passwordField.text);
                    }
                }

                background: Rectangle{
                    anchors.fill:parent
                    color: parent.checked?"steelblue": (parent.activeFocus?"dodgerblue":"slategray")
                }

                Keys.onReleased: {
                    checked = false
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

        ToolButton {
            id: toolButton
            text: stackView.depth > 1 ? "\u25C0" : ""
            font.pixelSize: 24
            activeFocusOnTab: true
            height: parent.height
            anchors.left: parent.left
            KeyNavigation.left: toolButton2
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
            KeyNavigation.left: toolButton
            KeyNavigation.down: stackView
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
            font.pointSize: 24
            font.family: Fonts.fontBlackOpsOneRegular.name
        }
    }

    StackView {
        id: stackView
        initialItem: "view/page/Home.qml"
        anchors.fill: parent
        onCurrentItemChanged: {
            if (currentItem.title === "Giriş" && restRequest.isSessionTimeout)
                loginPopup.open();
        }
    }
}
