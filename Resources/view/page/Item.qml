import QtQuick 2.7
import QtQuick.Controls 2.0
import QtMultimedia 5.9
import posapp.restrequest 1.0

import "../../fonts"
import "../controls"
import "../helpers/helper.js" as Helper

Page {
    id: itemPage
    width:  800 //parent
    height:  430 //parent
    property string unitPrice
    property string companyName
    property int item_id
    property int busyIndicatorCnt: 0

    title: qsTr("Ürün Detayı")

    RestRequest {
        id:itemRequest

        onSessionTimeout: {
            itemPage.parent.pop();
        }

        onRequestTimeout: {
            itemPage.parent.pop();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    Component.onCompleted: {
        selectLastTransactionsByDate.currentIndex = 4
    }

    ToastManager {
        id: toast
    }

    function getTransactions() {
        var stockQuery = "";
        if (selectStock.currentIndex >= 0)
            stockQuery = "/" + stockSelectComboBoxModel.get(selectStock.currentIndex).stock_id;
        var startDateStr;
        var nowDate = new Date();
        nowDate.setTime( nowDate.getTime() - nowDate.getTimezoneOffset()*60*1000 );
        var endDateStr = new Date(nowDate).toISOString();

        var startDate = new Date(nowDate);
        switch(selectLastTransactionsByDate.currentIndex) {
        case 0:
            startDate.setDate(startDate.getDate()-1);
            startDateStr = startDate.toISOString();
            break;
        case 1:
            startDate.setDate(startDate.getDate()-3);
            startDateStr = startDate.toISOString();
            break;
        case 2:
            startDate.setDate(startDate.getDate()-7);
            startDateStr = startDate.toISOString();
            break;
        case 3:
            startDate.setMonth(startDate.getMonth()-1);
            startDateStr = startDate.toISOString();
            break;
        case 4:
            startDate.setMonth(startDate.getMonth()-6);
            startDateStr = startDate.toISOString();
            break;
        case 5:
            startDate.setFullYear(startDate.getFullYear()-1);
            startDateStr = startDate.toISOString();
            break;
        default:
            startDateStr = new Date(2010, 1, 1).toISOString();
            break;
        }

        itemRequest.get("items/count_details/" + itemPage.item_id + "/json" + stockQuery,
                        {start_date: startDateStr, end_date: endDateStr},
                        function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        companyName = data.company_name;
        barcodeText.text = data.item_info.item_number;
        itemNameText.text = data.item_info.name;
        var location_keys = Object.keys(data.stock_locations);
        var stockId = selectStock.currentIndex < 0 ? -1:stockSelectComboBoxModel.get(selectStock.currentIndex).stock_id;
        stockSelectComboBoxModel.clear();
        for (var cnt = 0; cnt < location_keys.length; ++cnt) {
            stockSelectComboBoxModel.append({
                                                name: data.stock_locations[location_keys[cnt]],
                                                stock_id: location_keys[cnt]
                                            });
            if (stockId === location_keys[cnt]) {
                selectStock.changeIndexWithoutAction = true;
                selectStock.currentIndex = cnt;
            }
        }

        if (location_keys.length > 0 && selectStock.currentIndex < 0) {
            selectStock.changeIndexWithoutAction = true;
            selectStock.currentIndex = 0;
        }

        var options = {day: '2-digit', month: '2-digit', year: 'numeric',  hour: '2-digit', minute: '2-digit'};
        var currentStockId = stockSelectComboBoxModel.get(selectStock.currentIndex).stock_id;

        stockQuantity.text = parseInt(data.item_quantities[currentStockId]);

        itemTransactionListModel.clear();
        for (cnt = 0; cnt < data.inventory.length; ++cnt) {
            var transaction = data.inventory[cnt];
            if (currentStockId === transaction["trans_location"])
                itemTransactionListModel.append({
                                                date: new Date(transaction["trans_date"]).toLocaleString("tr-TR", options),
                                                user: data.employees[transaction["trans_user"]],
                                                description: transaction["trans_comment"],
                                                quantity: parseInt(transaction["trans_inventory"])
                                            });
        }
    }

    SoundEffect {
        id: clickBasicSound
        source: "../../sounds/click.wav"
    }

    Popup{
        id: updateStockPopup
        width: parent.width * 0.5
        height: parent.height * 0.5
        x: parent.width * 0.25
        y: parent.height * 0.2
        z: 200
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        onVisibleChanged: {
            if (!visible) {
                newQuantityField.text = "";
                newQuantityField.needValidate = false;
                commentField.text = "";
            }
        }

        Rectangle{
            width: parent.width * 0.9
            height: parent.height * 0.9
            anchors.centerIn: parent
            Text {
                id: descriptionText
                text: "Stoğu Güncelle"
                color: "slategray"
                font.pixelSize: 24
                font.family: Fonts.fontRubikRegular.name
                anchors.top: parent.top
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            TextField {
                id: newQuantityField
                required: true
                anchors.right: parent.right
                anchors.top: descriptionText.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 20
                width: parent.width
                validator: IntValidator {}
                font.family: Fonts.fontRubikRegular.name
                placeholderText: "Stok Miktarı"
            }
            TextField {
                id: commentField
                anchors.right: parent.right
                anchors.top: newQuantityField.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 5
                width: parent.width
                font.family: Fonts.fontRubikRegular.name
                placeholderText: "Açıklama"
            }

            Button {
                id:cancelButton
                text: "İptal"
                height: 40
                width: 100
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                font.pixelSize: 24
                onClicked:{
                    updateStockPopup.visible = false
                }
            }

            Button {
                id:updateButton
                text: "Güncelle"
                height: 40
                width: 100
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                font.pixelSize: 24
                borderColor: "mediumseagreen"
                onClicked:{
                    newQuantityField.needValidate = true;

                    if (newQuantityField.isInvalid())
                        toast.showError("Stok Miktarı Boş Bırakılamaz!", 3000);
                    else
                        itemRequest.post("items/save_inventory/" + item_id,
                                     {
                                         stock_location: stockSelectComboBoxModel.get(selectStock.currentIndex).stock_id,
                                         newquantity: newQuantityField.text,
                                         trans_comment: commentField.text
                                     },
                                     function(code, jsonStr) {
                                         var response = JSON.parse(jsonStr);
                                         if (response.success) {
                                             toast.showSuccess(response.message, 3000);
                                             getTransactions();
                                         }
                                         else
                                             toast.showError(response.message, 3000);
                                         updateStockPopup.visible = false;
                                     });
                }
            }
        }
    }

    ComboBox {
        id: selectLastTransactionsByDate
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.leftMargin: 4
        model: ListModel{
            ListElement{name:"Son 1 Gün"}
            ListElement{name:"Son 3 Gün"}
            ListElement{name:"Son 1 Hafta"}
            ListElement{name:"Son 1 Ay"}
            ListElement{name:"Son 6 Ay"}
            ListElement{name:"Son 1 Yıl"}
            ListElement{name:"Tüm Zamanlar"}
        }
        spacing: 5
        height: 50
        font.pixelSize: 24
        width: 150
        placeholderText: "İşlem Geçmişi"
        property bool currentIndexFirstChange: false
        onCurrentIndexChanged: {
            if (!currentIndexFirstChange)
                currentIndexFirstChange = true;
            else
                getTransactions();
        }
    }

    ComboBox {
        id: selectStock
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.rightMargin: 4
        model:ListModel{id: stockSelectComboBoxModel}
        enabled: stockSelectComboBoxModel.count > 1
        spacing: 5
        height: 50
        font.pixelSize: 24
        width: 150
        property bool changeIndexWithoutAction:true
        placeholderText: "Stok"
        onCurrentIndexChanged: {
            if (changeIndexWithoutAction)
                changeIndexWithoutAction = false
            else if (currentIndex >= 0)
                getTransactions();
        }
    }

    Rectangle {
        id: accountTitle
        anchors.right: selectStock.left
        anchors.left: selectLastTransactionsByDate.right
        anchors.top: parent.top
        antialiasing: true;
        anchors.margins: 4
        color: "#f7f8fa"
        height: 50
        Text {
            id: barcodeText
            text: ""
            color: "slategray"
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
            color: "slategray"
            font.pixelSize: 24
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
            height: 1
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
                    ListViewColumnLabel{
                        text: "İşlem Tarihi"
                        labelOf: dateText
                    }
                        Text {
                            id: dateText
                            text: date
                            color: "#545454"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: parent.left
                            width: parent.width/4
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "Kullanıcı"
                            labelOf: userText
                        }
                        Text {
                            id: userText
                            text: user
                            color: "#545454"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: dateText.right
                            width: parent.width/4
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "Açıklama"
                            labelOf: descText
                        }
                        Text {
                            id: descText
                            text: description
                            color: "#545454"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            width: (parent.width/8)*3
                            anchors.left: userText.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "Miktar"
                            labelOf: quantityText
                        }
                        Text {
                            id: quantityText
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            anchors.rightMargin: 4
                            anchors.right : parent.right
                            text: quantity
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width/8
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
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
                    PropertyChanges { target: content; color: "#CCD1D9"; height: 50; width: container.width - 15; anchors.leftMargin: 10; anchors.rightMargin: 15 }
                    PropertyChanges { target: dateText; font.pixelSize: 22; }
                    PropertyChanges { target: userText; font.pixelSize: 22; }
                    PropertyChanges { target: descText; font.pixelSize: 22; }
                    PropertyChanges { target: quantityText; font.pixelSize: 24; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
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
            height: 1
            color: list1.activeFocus?"dodgerblue":"slategray"
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: updateStockButton.right
        anchors.margins: 4
        width: parent.width - 316
        height: 50

        Label {
            id: itemNum
            text: "Stok Miktarı:"
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 3
            horizontalAlignment: "AlignHCenter"
            font.family: "Arial"
            font.pixelSize: 12
            color: "steelblue"
        }
        Label {
            id: stockQuantity
            anchors.top: itemNum.bottom
            anchors.topMargin: -9
            horizontalAlignment: "AlignHCenter"
            width: parent.width
            text: "0"
            font.family: Fonts.fontIBMPlexMonoRegular.name
            font.pixelSize: 32
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
        height: 50
        width: 150
        font.pixelSize: 24
        borderColor:"salmon"
        onClicked: updateStockPopup.visible = true
    }

    Button {
        id:printButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        text: "Barkod Yazdır"
        height: 50
        width: 150
        font.pixelSize: 24
        onClicked: {
            postRequest("print_barcode", {company_name: companyName, item_number:barcodeText.text, name: itemNameText.text, price: unitPrice.substring(0, unitPrice.length-1)}, 5000, function() {
                toast.showError("barkod yazdırılamadı!", 3000);
            });
        }
    }
}
