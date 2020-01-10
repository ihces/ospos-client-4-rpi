import QtQuick 2.7
import QtQuick.Controls 2.0

import "../../fonts"

Page {
    id: accountsPage
    width:  800 //parent
    height:  440 //parent

    title: qsTr("Hesaplar")

    ComboBox {
        id: typeButton
        KeyNavigation.left: barcodeTextField
        KeyNavigation.down: listMenu
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.leftMargin: 4
        model:["Müşteri", "Satıcı"]
        spacing: 5
        height: 50
        padding: 10
        font.pixelSize: 28
        font.family: Fonts.fontBarlowRegular.name
        width: 150
        background: Rectangle{
            implicitHeight: parent.height
            implicitWidth: parent.width
            color: parent.activeFocus?"dodgerblue":"lightslategray"
            radius: 0
        }
    }

    TextField {
        id: barcodeTextField
        font.pointSize: 22
        activeFocusOnTab: true
        focus: true
        anchors.left: typeButton.right
        anchors.top: parent.top
        anchors.leftMargin: 4
        anchors.topMargin: 4
        width: parent.width - 316
        height: 50
        leftPadding: 10
        topPadding: 8
        font.family: Fonts.fontOrbitronRegular.name
        verticalAlignment: "AlignVCenter"
        placeholderText: "Müşteri Ara"
        KeyNavigation.right: selectCustButton
        KeyNavigation.down: listMenu
        background: Rectangle {
            border.color: parent.activeFocus?"dodgerblue":"lightslategray"
            border.width: 2
            color: parent.activeFocus ?"dodgerblue": "white"
        }
        color: activeFocus ? "white": "#545454"
    }

    Button {
        id: selectCustButton
        KeyNavigation.left: barcodeTextField
        KeyNavigation.down: listMenu
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.rightMargin: 4
        text: "Yeni Müşteri"
        spacing: 5
        autoExclusive: false
        height: 50
        width: 150
        padding: 10
        checkable: true
        font.pixelSize: 28
        font.family: Fonts.fontBarlowRegular.name
        Keys.onPressed: {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                checked = true
                console.log("musteri sec enter")
                itemList.visible = true
                itemList.forceActiveFocus()
            }
        }

        background: Rectangle{
            anchors.fill:parent
            color: parent.checked?"steelblue": (parent.activeFocus?"dodgerblue":"lightslategray")
        }

        Keys.onReleased: {
            checked = false
        }
    }

    FocusScope {
        id: listMenu
        y: 70
        width: parent.width
        anchors.top: selectCustButton.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 2
            color: list1.activeFocus?"dodgerblue":"lightslategray"
        }

        ListView {
            id: list1
            width: parent.width; height: parent.height
            focus: true
            /*Keys.onLeftPressed: {
              drawer.open()
            }*/
            model: ListModel{
             ListElement{
                 num: 81
                name: "İbrahim Hakkı ÇEŞME"
                cost: "10,00₺"
             }
             ListElement{
                 num: 41
                name: "Mehmet KARTALKAYA"
                cost: "40,00₺"
             }
             ListElement{
                 num: 25
                name: "Ahmet PALANDÖKEN"
                cost: "7,8₺"
             }
             ListElement{
                 num: 38
                name: "Kaya ERCİYES"
                cost: "5,75₺"
             }
             ListElement{
                num: 16
                name: "Umut ULUDAĞ"
                cost: "10,00₺"
             }
            }
            cacheBuffer: 200
            delegate: Item {
                id: container
                width: ListView.view.width; height: 50; anchors.leftMargin: 4; anchors.rightMargin: 4


                Rectangle {
                    id: content
                    anchors.centerIn: parent; width: container.width - 20; height: container.height - 10
                    color: "transparent"
                    antialiasing: true
                    radius: 4

                    Rectangle {
                        anchors.fill: parent;
                        anchors.margins: 3;
                        antialiasing: true;
                        color: "transparent"
                        Text {
                            id: label
                            text: num
                            color: "#545454"
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Fonts.fontRubikRegular.name
                            width: 150
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }

                        Text {
                            id: label1
                            text: name
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width * 0.75 -160
                            anchors.left: label.right
                            anchors.leftMargin: 20
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }

                        Text {
                            id: label3
                            horizontalAlignment: Text.AlignRight
                            anchors.rightMargin: 4
                            anchors.right : parent.right
                            text: cost
                            color: "#545454"
                            font.pixelSize: 24
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width / 4
                            anchors.top: parent.top
                            anchors.topMargin: 4
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        container.ListView.view.currentIndex = index
                        container.forceActiveFocus()
                        editDelete.visible = true
                        listMenu.height = 160
                    }
                    onDoubleClicked: {
                        accountsPage.parent.push('Account.qml')
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color: "dodgerblue"; width: container.width - 10; height:50; anchors.leftMargin: 10; anchors.rightMargin: 10;}
                    PropertyChanges { target: label; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label1; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label3; font.pixelSize: 28; color: "white"; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
                }

                transitions: Transition {
                    //NumberAnimation { properties: "height"; duration: 100 }
                    //NumberAnimation { properties: "width"; duration: 100 }
                }
            }
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
            }

            Behavior on y {
                NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
            }
        }

        Rectangle {
            width: parent.width
            anchors.bottom: parent.bottom
            height: 2
            color: list1.activeFocus?"dodgerblue":"lightslategray"
        }
    }

    Rectangle {
        id: editDelete
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width
        height: 194
        visible: false
        color: "#f7f8f9"

        TextField {
            id: nameTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 2 - 7.5
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            horizontalAlignment: horizontalCenter
            placeholderText: "Adı"
            KeyNavigation.right: selectCustButton
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: surnameTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 2 - 7.5
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Soyadı"
            KeyNavigation.right: selectCustButton
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: phoneTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: parent.left
            anchors.top: nameTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 2 - 7.5
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Telefon"
            KeyNavigation.right: selectCustButton
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: mailTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.right: parent.right
            anchors.top: surnameTextField.bottom
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 2 - 7.5
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "E-Posta"
            KeyNavigation.right: selectCustButton
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: addressTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: parent.left
            anchors.top: phoneTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 2 - 7.5
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Adres"
            KeyNavigation.right: selectCustButton
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: commentTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.right: parent.right
            anchors.top: mailTextField.bottom
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 2 - 7.5
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Yorum"
            KeyNavigation.right: selectCustButton
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        Button {
            id: deleteCustButton
            KeyNavigation.left: barcodeTextField
            KeyNavigation.down: listMenu
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            anchors.leftMargin: 4
            text: "Sil"
            spacing: 5
            autoExclusive: false
            height: 50
            width: 150
            padding: 10
            checkable: true
            font.pixelSize: 28
            font.family: Fonts.fontBarlowRegular.name
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    checked = true
                    console.log("musteri sec enter")
                    itemList.visible = true
                    itemList.forceActiveFocus()
                }
            }

            background: Rectangle{
                anchors.fill:parent
                color: parent.checked?"steelblue": (parent.activeFocus?"dodgerblue":"crimson")
            }

            Keys.onReleased: {
                checked = false
            }
        }

        Button {
            id: saveCustButton
            KeyNavigation.left: barcodeTextField
            KeyNavigation.down: listMenu
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            anchors.rightMargin: 4
            text: "Kaydet"
            spacing: 5
            autoExclusive: false
            height: 50
            width: 150
            padding: 10
            checkable: true
            font.pixelSize: 28
            font.family: Fonts.fontBarlowRegular.name
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    checked = true
                    console.log("musteri sec enter")
                    itemList.visible = true
                    itemList.forceActiveFocus()
                }
            }

            background: Rectangle{
                anchors.fill:parent
                color: parent.checked?"steelblue": (parent.activeFocus?"dodgerblue":"mediumseagreen")
            }

            Keys.onReleased: {
                checked = false
            }
        }
    }
}
