import QtQuick 2.7
import QtQuick.Controls 2.0

import "../../fonts"

Page {
    id: homePage
    width:  800 //parent
    height:  440 //parent

    title: qsTr("Giriş")

    FocusScope {
        id: listMenu
        width: parent.width
        height: parent.height
        activeFocusOnTab: true

        clip: true
        ListView {
            id: list1
            width: parent.width; height: 180
            anchors.centerIn: parent
            orientation: ListView.Horizontal
            focus: true
            model: ListModel{
             ListElement{
                icon: "\uF291"
                name: "Satış"
                page: "Sale.qml"
             }
             ListElement{
                icon: "\uF472"
                name: "Alım"
                page: "Sale.qml"
             }
             ListElement{
                icon: "\uF02C"
                name: "Ürünler"
                page: "Items.qml"
             }
             ListElement{
                icon: "\uF2B9"
                name: "Hesaplar"
                page: "Accounts.qml"
             }
             ListElement{
                icon: "\uF200"
                name: "Rapor"
                page: "Sale.qml"
             }
             ListElement{
                icon: "\uF013"
                name: "Ayarlar"
                page: "Sale.qml"
             }
            }
            cacheBuffer: 200
            delegate: Item {
                id: container
                width: 130
                height: 180

                Rectangle {
                    id: content
                    anchors.centerIn: parent
                    width: container.width - 20
                    height: container.height - 10
                    color:"#545454"
                    antialiasing: true
                    radius: 4

                    Rectangle {
                        id: innerContent
                        anchors.fill: parent;
                        anchors.margins: 3;
                        antialiasing: true;
                        color: "white"

                        Text {
                            id: label1
                            text: icon
                            color: "#545454"
                            font.pixelSize: 48
                            font.family: Fonts.fontAwesomeSolid.name
                            anchors.centerIn: parent
                        }
                        Text {
                            id: label2
                            text: name
                            color: "#545454"
                            font.pixelSize: 20
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
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
                    onDoubleClicked: {
                        container.ListView.view.currentIndex = index
                        container.forceActiveFocus()
                        homePage.parent.push(page)
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color: "dodgerblue"; width: container.width - 10; anchors.leftMargin: 10; anchors.rightMargin: 10 }
                    PropertyChanges { target: innerContent; color: "dodgerblue"}
                    PropertyChanges { target: label1; font.pixelSize: 52; color: "white" }
                    PropertyChanges { target: label2; font.pixelSize: 24; font.bold: true; color: "white" }
                }
            }
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
            }

            Behavior on y {
                NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
            }
        }
    }
}
