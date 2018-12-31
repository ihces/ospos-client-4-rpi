import QtQuick 2.7
import QtQuick.Controls 2.0

Page {
    width: parent
    height: parent

    title: qsTr("Satış")

    TextField {
        id: barcodeTextField
        font.pointSize: 32
        activeFocusOnTab: true
        focus: true
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 5
        anchors.topMargin: 5
        width: parent.width * 0.6
        padding: 5
        height: 60
        font.family: "Arial"
        placeholderText: "Ürün Adı veya Barkod"
        KeyNavigation.right: selectCustButton
        KeyNavigation.down: listMenu
        background: Rectangle {
            border.color: parent.activeFocus?"navy":"slategray"
            border.width: 2
            color: parent.activeFocus ?"navy": "white"
        }
        Text{
            anchors.right: parent.right
            text: "F10"
            font.pointSize: 12
            font.family: "Courier"
            color: "darkturquoise"
            font.bold: true
            rightPadding: 10
            topPadding: 4
        }
        color: activeFocus ? "white": "slategray"
    }

    Button {
        id: selectCustButton
        KeyNavigation.left: barcodeTextField
        KeyNavigation.down: listMenu
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.rightMargin: 5
        text: "Müşteri Seç"
        spacing: 5
        autoExclusive: false
        height: 60
        padding: 10
        checkable: true
        font.family: "Arial"
        font.pointSize: 24
        Text{
            anchors.right: parent.right
            text: "F11"
            font.pointSize: 12
            font.family: "Courier"
            color: "darkturquoise"
            font.bold: true
            rightPadding: 10
            topPadding: 4
        }
        Keys.onPressed: {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                checked = true
                console.log("musteri sec enter")
            }
        }

        background: Rectangle{
            anchors.fill:parent
            color: parent.checked?"steelblue": (parent.activeFocus?"navy":"slategray")
        }

        Keys.onReleased: {
            checked = false
        }
    }

    FocusScope {
        id: listMenu
        y: 70
        width: parent.width
        height: parent.height - 140
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 2
            color: list1.activeFocus?"navy":"slategray"
        }

        ListView {
            id: list1
            width: parent.width; height: parent.height
            focus: true
            /*Keys.onLeftPressed: {
              drawer.open()
            }*/
            KeyNavigation.down: paymentButton
            model: ListModel{
             ListElement{
                amount: "10 Torba"
                name: "Aşkale Çimento"
                cost: "10,00"
             }
             ListElement{
                amount: "2,5 Lt"
                name: "Marshall Silikonlu Özel Mat"
                cost: "40,00"
             }
             ListElement{
                amount: "3,9 Kg"
                name: "Taş Kireç"
                cost: "7,8"
             }
             ListElement{
                amount: "1 Adet"
                name: "İzmir Oto Fırça"
                cost: "5,75"
             }
             ListElement{
                amount: "10 Torba"
                name: "Aşkale Çimento"
                cost: "10,00"
             }
             ListElement{
                amount: "2,5 Lt"
                name: "Marshall Silikonlu Özel Mat"
                cost: "40,00"
             }
             ListElement{
                amount: "3,9 Kg"
                name: "Taş Kireç"
                cost: "7,8"
             }
             ListElement{
                amount: "1 Adet"
                name: "İzmir Oto Fırça"
                cost: "5,75"
             }
             ListElement{
                amount: "10 Torba"
                name: "Aşkale Çimento"
                cost: "10,00"
             }
             ListElement{
                amount: "2,5 Lt"
                name: "Marshall Silikonlu Özel Mat"
                cost: "40,00"
             }
             ListElement{
                amount: "3,9 Kg"
                name: "Taş Kireç"
                cost: "7,8"
             }
             ListElement{
                amount: "1 Adet"
                name: "İzmir Oto Fırça"
                cost: "5,75"
             }
            }
            cacheBuffer: 200
            delegate: Item {
                id: container
                width: ListView.view.width; height: 50; anchors.leftMargin: 5; anchors.rightMargin: 5

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
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: name
                            color: "#545454"
                            font.pixelSize: 24
                            font.family: "Arial"
                            width: parent.width / 2
                        }

                        Text {
                            id: label2
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            text: amount
                            color: "#545454"
                            font.pixelSize: 24
                            font.family: "Arial"
                            width: parent.width / 4
                        }

                        Text {
                            id: label3
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 15
                            anchors.right: label4.left
                            text: cost
                            color: "#545454"
                            font.pixelSize: 24
                            font.family: "Courier"
                            font.bold: true
                            width: parent.width / 4 - 40
                        }

                        Text {
                            id: label4

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 5
                            anchors.right: parent.right
                            text: "\u20BA"
                            color: "#545454"
                            font.pixelSize: 24
                            font.family: "Arial"
                            width: 20
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
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color: "navy"; height: 60; width: container.width - 10; anchors.leftMargin: 10; anchors.rightMargin: 10 }
                    PropertyChanges { target: label; font.pixelSize: 32; font.bold: true; color: "white" }
                    PropertyChanges { target: label2; font.pixelSize: 32; font.bold: true; color: "white" }
                    PropertyChanges { target: label3; font.pixelSize: 32; color: "white" }
                    PropertyChanges { target: label4; font.pixelSize: 32; color: "white" }
                }

                transitions: Transition {
                    NumberAnimation { properties: "height"; duration: 100 }
                    NumberAnimation { properties: "width"; duration: 100 }
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
            color: list1.activeFocus?"navy":"slategray"
        }
    }

    Label {
        id: itemNum
        text: "Ürün Kalemi: 12"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 23
        anchors.leftMargin: 5
        font.family: "Arial"
        font.pointSize: 16
    }

    Rectangle {
        anchors.bottom: parent.bottom
        x: parent.width / 4
        width: parent.width / 2
        height: 70

        Label {
            anchors.fill: parent
            id: totalCostLabel
            text: "Toplam:"
            font.family: "Arial"
            font.pointSize: 18

            anchors.right: totalCost.left
            padding: 20

            color: "crimson"
        }
        Label {
            id: totalCost
            anchors.centerIn: parent
            text: "9999,99"
            font.family: "Courier"
            font.pointSize: 32
            font.bold: true
            color: "crimson"
        }
        Label {
            anchors.left: totalCost.right
            padding: 14
            anchors.leftMargin: 2
            text: "\u20BA"
            horizontalAlignment: Text.AlignLeft
            font.family: "Arial"
            font.pointSize: 28
            color: "crimson"
        }
    }

    Button {
        id:paymentButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        anchors.rightMargin: 5
        text: "Ödeme"
        spacing: 5
        autoExclusive: false
        height: 60
        padding: 10
        checkable: true
        font.family: "Arial"
        font.pointSize: 24
        Text{
            anchors.right: parent.right
            text: "F12"
            font.pointSize: 12
            font.family: "Courier"
            color: "darkturquoise"
            font.bold: true
            rightPadding: 10
            topPadding: 4
        }
        Keys.onPressed: {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                checked = true
                console.log("odeme enter")
            }
        }

        background: Rectangle{
            anchors.fill:parent
            color: parent.checked?"steelblue": (parent.activeFocus?"navy":"slategray")
        }

        Keys.onReleased: {
            checked = false
        }
    }
}
