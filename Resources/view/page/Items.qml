import QtQuick 2.7
import QtQuick.Controls 2.0
import posapp.restrequest 1.0

import "../../fonts"

Page {
    id: itemsPage
    width:  800 //parent
    height:  440
    font.family: "Courier" //parent

    title: qsTr("Ürünler")

    RestRequest {
        id:itemsRequest

        onSessionTimeout: {
            itemsPage.parent.pop();
        }
    }

    function getItems() {
        var searchObj = {"search": searchTextField.text, order:"asc", limit: 25, start_date: new Date(2010, 1, 1).toISOString(), end_date: new Date().toISOString()};

        switch (selectFilter.currentIndex) {
        case 1:
            searchObj["filters[]"] = "empty_upc";
            break;
        case 2:
            searchObj["filters[]"] = "low_inventory";
            break;
        case 3:
            searchObj["filters[]"] = "is_deleted";
            break;
        default:
            searchObj["filters[]"] = "";
            break;
        }

        itemsRequest.get("items/search", searchObj, function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        itemListViewModel.clear();
        for (var cnt = 0; cnt < data.rows.length; ++cnt) {
            var item = data.rows[cnt];

            itemListViewModel.append({id: item["items.item_id"], num: item.item_number, name: item.name, cost: parseFloat(item.cost_price.replace('₺', '')).toFixed(2) + "₺"});
        }
    }

    ComboBox {
        id: selectFilter
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.leftMargin: 4
        model:["Tüm", "Barkodsuz", "Tükenmiş", "Silinmiş"]
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
            getItems();
        }
    }

    TextField {
        id: searchTextField
        font.pointSize: 20
        activeFocusOnTab: true
        focus: true
        anchors.left: selectFilter.right
        anchors.right: newItemButton.left
        anchors.top: parent.top
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 4
        height: 50
        leftPadding: 10
        topPadding: 8
        font.family: Fonts.fontOrbitronRegular.name
        placeholderText: "Ürün Adı veya Barkod"
        KeyNavigation.right: selectFilter
        KeyNavigation.down: listMenu
        background: Rectangle {
            border.color: parent.activeFocus?"dodgerblue":"lightslategray"
            border.width: 2
            color: parent.activeFocus ?"dodgerblue": "white"
        }
        color: activeFocus ? "white": "#545454"
        onTextChanged: {
            getItems();
        }
    }

    Button {
        id: newItemButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.rightMargin: 4
        text: "Yeni Ürün"
        spacing: 5
        autoExclusive: false
        height: 50
        width: 150
        padding: 10
        font.pixelSize: 28
        font.family: Fonts.fontBarlowRegular.name
        background: Rectangle{
            anchors.fill:parent
            color: parent.activeFocus?"dodgerblue":"lightslategray"
        }
    }

    FocusScope {
        id: listMenu
        width: parent.width
        anchors.top: searchTextField.bottom
        anchors.bottom: editDelete.visible? editDelete.top:parent.bottom
        anchors.topMargin: 4
        activeFocusOnTab: true

        onActiveFocusChanged: {console.log(focus)}

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

            model: ListModel{id: itemListViewModel}
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
                        itemsPage.parent.push('Item.qml', {item_id: itemListViewModel.get(index).id})
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

    FocusScope {
        id: editDelete
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width
        height: 190
        visible: false
        Rectangle {
            anchors.fill: parent
            color: "#f7f8f9"
        }

        onActiveFocusChanged: {console.log("asdasd" + focus);}
        TextField {
            id: barcodeTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Barkod No"
            KeyNavigation.right: selectFilter
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: itemNameTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: barcodeTextField.right
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Ürün Adı"
            KeyNavigation.right: selectFilter
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        ComboBox {
            editable: true
            id: categoryTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            currentIndex: -1
            displayText: currentIndex === -1 ? "Kategori" : currentText
            model: ["süt", "et", "hazır gıda"]
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            KeyNavigation.right: selectFilter
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
        }

        ComboBox {
            id: companyTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: parent.left
            anchors.top: barcodeTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            leftPadding: 10
            displayText: currentIndex === -1 ? "Sağlayıcı" : currentText
            font.family: Fonts.fontRubikRegular.name
            KeyNavigation.right: selectFilter
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
        }

        TextField {
            id: costPriceTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: companyTextField.right
            anchors.top: itemNameTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Maliyet Fiyatı"
            KeyNavigation.right: selectFilter
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: salePriceTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.right: parent.right
            anchors.top: categoryTextField.bottom
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Satış Fiyatı"
            KeyNavigation.right: selectFilter
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: tax1TextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: parent.left
            anchors.top: companyTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Vergi 1"
            KeyNavigation.right: selectFilter
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: tax2TextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.left: tax1TextField.right
            anchors.top: costPriceTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Vergi 2"
            KeyNavigation.right: selectFilter
            KeyNavigation.down: listMenu
            background: Rectangle {
                border.color: parent.activeFocus?"dodgerblue":"lightslategray"
                border.width: 1
                color: parent.activeFocus ?"dodgerblue": "transparent"
            }
            color: activeFocus ? "white": "#545454"
        }

        TextField {
            id: stockTextField
            font.pointSize: 16
            activeFocusOnTab: true
            focus: true
            anchors.right: parent.right
            anchors.top: salePriceTextField.bottom
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            leftPadding: 10
            font.family: Fonts.fontRubikRegular.name
            placeholderText: "Açıklama"
            KeyNavigation.right: selectFilter
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
            KeyNavigation.left: searchTextField
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
            KeyNavigation.left: searchTextField
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
