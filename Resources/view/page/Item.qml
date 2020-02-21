import QtQuick 2.7
import QtQuick.Controls 2.0
import QtMultimedia 5.9
import posapp.restrequest 1.0

import "../../fonts"

Page {
    id: itemPage
    width:  800 //parent
    height:  440 //parent
    property int item_id
    property var item_transactions
    property var itemQuantities
    property var employees

    title: qsTr("Ürün Detayı")

    RestRequest {
        id:itemRequest

        onSessionTimeout: {
            salePage.parent.pop();
        }
    }

    Component.onCompleted: {
        itemRequest.get("items/count_details/" + itemPage.item_id + "/json", function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        barcodeText.text = data.item_info.item_number;
        itemNameText.text = data.item_info.name;

        itemPage.item_transactions = data.inventory;
        itemPage.employees = data.employees;
        itemPage.itemQuantities = data.item_quantities;
        var location_keys = Object.keys(data.stock_locations);
        for (var cnt = 0; cnt < location_keys.length; ++cnt) {
            stockSelectComboBoxModel.append({
                                                name: data.stock_locations[location_keys[cnt]],
                                                stock_id: location_keys[cnt]
                                            });
        }

    }

    function updateTransactionList() {
        var options = {day: '2-digit', month: '2-digit', year: 'numeric',  hour: '2-digit', minute: '2-digit'};
        itemTransactionListModel.clear();
        var currentStockId = stockSelectComboBoxModel.get(selectStock.currentIndex).stock_id;

        stockQuantity.text = itemPage.itemQuantities[currentStockId];

        for (var cnt = 0; cnt < itemPage.item_transactions.length; ++cnt) {
            var transaction = itemPage.item_transactions[cnt];
            if (currentStockId === transaction["trans_location"])
                itemTransactionListModel.append({
                                                date: new Date(transaction["trans_date"]).toLocaleString("tr-TR", options),
                                                user: itemPage.employees[transaction["trans_user"]],
                                                description: transaction["trans_comment"],
                                                quantity: transaction["trans_inventory"]
                                            });
        }
    }

    SoundEffect {
        id: clickBasicSound
        source: "../../sounds/220197-click-basic.wav"
    }

    ComboBox {
        id: selectLastTransactionsByDate
        KeyNavigation.down: listMenu
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.leftMargin: 4
        model:["Tüm Zamanlar", "Bugün", "Dün", "Geçen Hafta", "Geçen Ay", "Geçen 3 Ay", "Geçen 6 Ay", "Geçen Yıl"]
        spacing: 5
        height: 50
        padding: 10
        font.pixelSize: 18
        font.family: Fonts.fontBarlowRegular.name
        width: 150
        background: Rectangle{
            implicitHeight: parent.height
            implicitWidth: parent.width
            color: parent.activeFocus?"dodgerblue":"lightslategray"
            radius: 0
        }
    }

    ComboBox {
        id: selectStock
        KeyNavigation.down: listMenu
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.rightMargin: 4
        model:ListModel{id: stockSelectComboBoxModel}
        textRole: "name"
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
        onCurrentIndexChanged: {
            updateTransactionList();
        }
    }

    Rectangle {
        id: accountTitle
        anchors.right: selectStock.left
        anchors.left: selectLastTransactionsByDate.right
        anchors.top: parent.top
        antialiasing: true;
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        color: "#d6e6f6"
        height: 58
        Text {
            id: barcodeText
            text: ""
            color: "#545454"
            font.pixelSize: 14
            font.family: Fonts.fontRubikRegular.name
            anchors.left: parent.left
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            anchors.top: parent.top
            anchors.topMargin: 0
        }
        Text {
            id: itemNameText
            text: ""
            anchors.topMargin: -6
            color: "#545454"
            font.pixelSize: 32
            font.family: Fonts.fontTomorrowRegular.name
            anchors.left: parent.left
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            anchors.top: barcodeText.bottom
        }
    }

    FocusScope {
        id: listMenu
        y: 50
        width: parent.width
        height: parent.height - 116
        anchors.top: selectStock.bottom
        anchors.topMargin: 4
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 2
            color: list1.activeFocus?"dodgerblue":"slategray"
        }

        ListView {
            id: list1
            width: parent.width
            height: parent.height
            focus: true
            model: ListModel{
                id: itemTransactionListModel
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
                            id: label1
                            text: date
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: parent.left
                            width: 200
                            horizontalAlignment: Text.AlignHCenter
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }
                        Text {
                            id: label2
                            text: user
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: label1.right
                            width: 150
                            horizontalAlignment: Text.AlignHCenter
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }
                        Text {
                            id: label3
                            text: description
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width - 500
                            anchors.left: label2.right
                            anchors.leftMargin: 20
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }
                        Text {
                            id: label4
                            horizontalAlignment: Text.AlignRight
                            anchors.rightMargin: 4
                            anchors.right : parent.right
                            text: quantity
                            color: "#545454"
                            font.pixelSize: 24
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: 150
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
                        clickBasicSound.play()
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color: "dodgerblue"; height: 50; width: container.width - 10; anchors.leftMargin: 10; anchors.rightMargin: 10 }
                    PropertyChanges { target: label1; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label2; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label3; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label4; font.pixelSize: 28; color: "white"; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
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
            color: list1.activeFocus?"dodgerblue":"slategray"
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: updateStockButton.right
        width: parent.width - 316
        height: 50

        Label {
            id: itemNum
            text: "Stok Miktarı:"
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: -8
            horizontalAlignment: "AlignHCenter"
            font.family: "Arial"
            font.pointSize: 12
            color: "steelblue"
        }
        Label {
            id: stockQuantity
            anchors.top: itemNum.bottom
            anchors.topMargin: -12
            horizontalAlignment: "AlignHCenter"
            width: parent.width
            text: "0"
            font.family: Fonts.fontIBMPlexMonoRegular.name
            font.pointSize: 32
            font.bold: true
            color: "steelblue"
        }
    }

    Button {
        id:updateStockButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.leftMargin: 4
        text: "Stoğu Güncelle"
        spacing: 5
        autoExclusive: false
        height: 50
        width: 150
        padding: 10
        checkable: true
        font.family: Fonts.fontBarlowRegular.name
        font.pointSize: 18
        background: Rectangle{
            anchors.fill:parent
            color: parent.activeFocus?"darksalmon":"salmon"
        }
    }

    Button {
        id:printButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        text: "Barkod Yazdır"
        spacing: 5
        autoExclusive: false
        height: 50
        width: 150
        padding: 10
        checkable: true
        font.family: Fonts.fontBarlowRegular.name
        font.pointSize: 20
        background: Rectangle{
            anchors.fill:parent
            color: parent.activeFocus?"dodgerblue":"slategray"
        }
    }
}
