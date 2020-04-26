import QtQuick 2.7
import QtQuick.Controls 2.0
import posapp.restrequest 1.0

import "../../fonts"
import "../controls"

Page {
    id: salePage
    width:  800 //parent
    height:  440 //parent

    title: qsTr("Satış")

    RestRequest {
        id:salesRequest

        onSessionTimeout: {
            salePage.parent.pop();
        }
    }

    Component.onCompleted: {
        salesRequest.get("sales/json", function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        modeSelectComboBox.enabled = false;
        stockSelectComboBox.enabled = false;

        itemNum.text = data["item_count"] + " Ürün Toplam:";
        totalCost.text = parseFloat(data["total"]).toFixed(2) + "₺";
        modeSelectComboBox.currentIndex = (data.mode === "sale" ? 0:1);

        custSelectButton.text = data.customer?data.customer:"Müşteri Seçilmedi";

        stockSelectComboBoxModel.clear();
        var location_keys = Object.keys(data.stock_locations);
        for (var cnt = 0; cnt < location_keys.length; ++cnt) {
            stockSelectComboBoxModel.append({
                                                name: data.stock_locations[location_keys[cnt]],
                                                stock_id: location_keys[cnt]
                                            });
            if (data.stock_location === location_keys[cnt]){
                stockSelectComboBox.currentIndex = cnt;
            }
        }

        cartListViewModel.clear();
        var keys = Object.keys(data.cart);
        for (cnt = 0; cnt < keys.length; ++cnt) {
            var item = data.cart[keys[cnt]];
            cartListViewModel.append({sale_idx:keys[cnt], item_id: item.item_id, barcode: item.serialnumber +" | ", stock: "Kalan Stok: " + parseInt(item.in_stock) + " ("+item.stock_name +")",
                amount: item.quantity, name: item.name, cost: parseFloat(item.total).toFixed(2) + "₺"});
        }

        modeSelectComboBox.enabled = true;
        stockSelectComboBox.enabled = true;
    }

    function updateSearchItemList(data) {
        itemListModel.clear();
        for (var cnt=0; cnt < parseInt(data.total); cnt++) {
            itemListModel.append({id: data.rows[cnt]["items.item_id"],
                                     code: data.rows[cnt]["item_number"] + " | ",
                                     name: data.rows[cnt]["name"],
                                    stock: data.rows[cnt]["category"]});
        }

        itemList.visible = true;
    }

    function searchCustomer() {
        customerNameTextField.customerNameTextCleared = true;
        customerNameTextField.text = customerNameTextField.text.trim();
        salesRequest.get("customers/search?search="+encodeURIComponent(customerNameTextField.text)+
                            "&order=asc&offset=0&limit=25", function(code, jsonStr){
            var customerList = JSON.parse(jsonStr)["rows"];
            customerListViewModel.clear();
            for (var cnt=0; cnt < customerList.length; ++cnt){
                var suspended = customerList[cnt];
                customerListViewModel.append({
                    num: customerList[cnt]["people.person_id"],
                    name: customerList[cnt]["first_name"] + " " + customerList[cnt]["last_name"],
                    amount:customerList[cnt]["total"]
                });
            }
        });
    }

    Popup{
        id: selectCustomerPopup

        width: parent.width * 0.75
        height: parent.height * 0.75
        x: parent.width * 0.125
        y: parent.height * 0.125
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Rectangle{
            id: selectCustomerTitle
            width: parent.width
            height: 40
            Text {
                text: "Müşteri Seç"
                color: "#545454"
                font.pixelSize: 20
                font.family: Fonts.fontBlackOpsOneRegular.name
                anchors.left: parent.left
                width: parent.width/2
                anchors.verticalCenter: parent.verticalCenter
            }
            TextField {
                id: customerNameTextField
                x: 400
                font.pixelSize: 20
                activeFocusOnTab: true
                focus: true
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 4
                leftPadding: 10
                topPadding: 2
                anchors.topMargin: 2
                width: parent.width / 2
                height: parent.height
                font.family: Fonts.fontTekoRegular.name
                placeholderText: "İsim veya Soyisim"
                background: Rectangle {
                    border.color: parent.activeFocus?"dodgerblue":"slategray"
                    border.width: 2
                    color: parent.activeFocus ?"dodgerblue": "white"
                }
                property bool customerNameTextCleared: false
                onTextChanged: {
                    if (customerNameTextCleared)
                        customerNameTextCleared = false;
                    else {
                        searchCustomer();
                    }
                }
                color: activeFocus ? "white": "slategray"
                anchors.rightMargin: 0
            }
        }
        FocusScope {
            id: selectCustomerList
            anchors.left: parent.Left
            width: parent.width
            anchors.top: selectCustomerTitle.bottom
            anchors.topMargin: 10
            height: parent.height - selectCustomerTitle.height - 10
            activeFocusOnTab: true
            z: 1000

            clip: true

            Rectangle {
                width: parent.width
                height: parent.height
                color: "white"
                border.color: "dodgerblue"
                border.width: 2
            }

            ListView {
                id: selectCustomerListView
                width: parent.width; height: parent.height
                focus: true
                model: ListModel{
                    id: customerListViewModel
                }
                cacheBuffer: 200
                delegate: Item {
                    id: selectCustomerItemContainer
                    width: ListView.view.width; height: 35; anchors.leftMargin: 4; anchors.rightMargin: 4
                    Rectangle {
                        id: selectCustomerItemContent
                        anchors.centerIn: parent; width: selectCustomerItemContainer.width - 20; height: selectCustomerItemContainer.height
                        antialiasing: true
                        color: "transparent"
                        Rectangle {
                            anchors.fill: parent;
                            antialiasing: true;
                            color:"transparent"
                            Text {
                                id: selectCustomerItemNum
                                text: num
                                color: "#545454"
                                font.pixelSize: 18
                                font.family: Fonts.fontRubikRegular.name
                                width: parent.width / 3
                                anchors.left: parent.left
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                            }

                            Text {
                                id: selectCustomerItemName
                                text: name
                                color: "#545454"
                                font.pixelSize: 18
                                font.family: Fonts.fontPlayRegular.name
                                anchors.left: selectCustomerItemNum.right
                                width: parent.width / 3
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                            }

                            Text {
                                id: selectCustomerItemDebtAmount
                                text: amount
                                color: "#545454"
                                font.pixelSize: 18
                                font.family: Fonts.fontIBMPlexMonoRegular.name
                                anchors.right: parent.right
                                horizontalAlignment: Text.AlignRight
                                width: parent.width/3
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            selectCustomerItemContainer.forceActiveFocus()
                            selectCustomerItemContainer.ListView.view.currentIndex = index
                        }

                        onDoubleClicked: {
                            selectCustomerItemContainer.ListView.view.currentIndex = index;
                            selectCustomerItemContainer.forceActiveFocus();
                            salesRequest.post("sales/select_customer/json",{customer: customerListViewModel.get(index).num},
                                                 function(code, jsonStr){
                                                    updateData(JSON.parse(jsonStr));
                                                    selectCustomerPopup.close();
                                                 });

                        }
                    }

                    states: State {
                        name: "active"; when: selectCustomerItemContainer.activeFocus
                        PropertyChanges { target: selectCustomerItemContainer; height: 38}
                        PropertyChanges { target: selectCustomerItemContent; color: "dodgerblue"; height: 38; width: selectCustomerItemContainer.width - 10; anchors.leftMargin: 10; anchors.rightMargin: 10}
                        PropertyChanges { target: selectCustomerItemNum; font.pixelSize: 22; font.bold: true; color: "white" }
                        PropertyChanges { target: selectCustomerItemName; font.pixelSize: 22; font.bold: true; color: "white" }
                        PropertyChanges { target: selectCustomerItemDebtAmount; font.pixelSize: 24; font.bold: true; color: "white"; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
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

    Popup{
        id: suspendedListPopup
        width: parent.width * 0.75
        height: parent.height * 0.75
        x: parent.width * 0.125
        y: parent.height * 0.125
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Rectangle{
            id: suspendTitle
            width: parent.width
            height: 40
            Text {
                text: "Bekleyen İşlemler"
                wrapMode: Text.WrapAnywhere
                color: "#545454"
                font.pixelSize: 20
                font.family: Fonts.fontBlackOpsOneRegular.name
                anchors.centerIn: parent
            }
        }
        FocusScope {
            id: suspendList
            anchors.left: parent.Left
            width: parent.width
            anchors.top: suspendTitle.bottom
            height: parent.height - suspendTitle.height
            activeFocusOnTab: true
            z: 1000

            clip: true

            Rectangle {
                width: parent.width
                height: parent.height
                color: "white"
                border.color: "dodgerblue"
                border.width: 2
            }

            ListView {
                id: suspendListView
                width: parent.width; height: parent.height
                focus: true
                model: ListModel{id: suspendedListViewModel}
                cacheBuffer: 200
                delegate: Item {
                    id: suspendItemContainer
                    width: ListView.view.width;
                    height: 35;
                    anchors.leftMargin: 4;
                    anchors.rightMargin: 4
                    Rectangle {
                        id: suspendItemContent
                        anchors.centerIn: parent;
                        width: suspendItemContainer.width - 20;
                        height: suspendItemContainer.height
                        antialiasing: true
                        color: "transparent"
                        Rectangle {
                            anchors.fill: parent;
                            anchors.margins: 3;
                            antialiasing: true;
                            color:"transparent"

                            Text {
                                id: suspendedItemId
                                text: sale_id
                                color: "#545454"
                                font.pixelSize: 16
                                font.family: Fonts.fontRubikRegular.name
                                width: parent.width / 6
                                anchors.left: parent.left
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                id: suspendedItemDate
                                text: date
                                color: "#545454"
                                font.pixelSize: 18
                                font.family: Fonts.fontPlayRegular.name
                                anchors.left: suspendedItemId.right
                                width: (parent.width / 6) * 2.5
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                id: suspendedItemCustomer
                                text: customer
                                color: "#545454"
                                font.pixelSize: 16
                                font.family: Fonts.fontPlayRegular.name
                                anchors.right: parent.right
                                horizontalAlignment: Text.AlignRight
                                width: (parent.width/6)*2.5
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            suspendItemContainer.forceActiveFocus()
                        }

                        onDoubleClicked: {
                            suspendItemContainer.forceActiveFocus();
                            salesRequest.post("sales/unsuspend/json",{suspended_sale_id: suspendedListViewModel.get(index).sale_id, submit: "Satışa+Al"},
                                                 function(code, jsonStr){
                                                    updateData(JSON.parse(jsonStr));
                                                    suspendedListPopup.close();
                                                 });
                        }
                    }

                    states: State {
                        name: "active"; when: suspendItemContainer.activeFocus
                        PropertyChanges { target: suspendItemContainer; height: 38; anchors.leftMargin: 10; anchors.rightMargin: 10}
                        PropertyChanges { target: suspendItemContent; color: "dodgerblue"; height: 38;}
                        PropertyChanges { target: suspendedItemId; font.pixelSize: 20; font.bold: true; color: "white" }
                        PropertyChanges { target: suspendedItemDate; font.pixelSize: 20; font.bold: true; color: "white" }
                        PropertyChanges { target: suspendedItemCustomer; font.pixelSize: 20; font.bold: true; color: "white"}
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

    Button{
        id:custSelectButton
        width: parent.width
        height: 25
        font.pixelSize: 18
        onClicked: {
            searchCustomer();
            selectCustomerPopup.open();
        }
    }
    ComboBox {
        id: modeSelectComboBox
        anchors.left: parent.left
        anchors.top: custSelectButton.bottom
        anchors.topMargin: 4
        anchors.leftMargin: 4
        placeholderText: "İşlem Türü"
        model:ListModel{
            id:modeSelectComboBoxModel
            ListElement{name: "Satış"; mode: "sale"}
            ListElement{name: "İade"; mode: "return"}
        }
        enabled: false
        height: 50
        font.pixelSize: 24
        width: 150

        onCurrentIndexChanged: {
            if (modeSelectComboBox.enabled && stockSelectComboBox.enabled)
                salesRequest.post("sales/change_mode/json",
                                     {
                                         mode: modeSelectComboBoxModel.get(modeSelectComboBox.currentIndex).mode,
                                         stock_location: stockSelectComboBoxModel.get(stockSelectComboBox.currentIndex).stock_id
                                     },
                                     function(code, jsonStr){
                                        updateData(JSON.parse(jsonStr))
                                     });
        }
    }

    TextField {
        id: barcodeTextField
        font.pixelSize: 20
        anchors.left: modeSelectComboBox.right
        anchors.top: custSelectButton.bottom
        anchors.topMargin: 4
        anchors.leftMargin: 4
        width: parent.width - 316
        height: 50
        font.family: Fonts.fontOrbitronRegular.name
        placeholderText: "Ürün Adı veya Barkod"
        leftPadding: 10
        property bool barcodeTextCleared: false
        onTextChanged: {
            if (barcodeTextCleared) {
                barcodeTextCleared = false
            }
            else {
                salesRequest.get("items/search",
                                {"search": barcodeTextField.text, order:"asc", limit: 10, start_date: new Date(2010, 1, 1).toISOString(), end_date: new Date().toISOString(), "filters[]": []},
                                function(code, jsonStr){updateSearchItemList(JSON.parse(jsonStr))});
            }
        }

        Button {
            id:fastAddButton
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.rightMargin: 6
            text: "Favoriler"
            height: 38
            width: 100
            font.pixelSize: 14
            z:100
            Keys.onReturnPressed: {
                clicked();
            }
            onClicked: {
            }
            borderColor: "hotpink"
        }
    }


    FocusScope {
        id: itemList
        anchors.top: barcodeTextField.bottom
        anchors.topMargin: 2
        anchors.left: barcodeTextField.left
        width: barcodeTextField.width
        height: parent.height / 2
        activeFocusOnTab: true
        visible: false
        z: 1000

        clip: true

        Rectangle {
            width: parent.width
            height: parent.height
            color: "white"
            border.color: "dodgerblue"
            border.width: 2
        }

        ListView {
            id: itemListView
            width: parent.width; height: parent.height
            focus: true
            cacheBuffer: 200
            model: ListModel{id:itemListModel}
            delegate: Item {
                id: container2
                width: ListView.view.width; height: 50; anchors.leftMargin: 4; anchors.rightMargin: 4
                Rectangle {
                    id: content989
                    anchors.centerIn: parent; width: container2.width - 20; height: container2.height - 10
                    antialiasing: true
                    color: "transparent"
                    Rectangle {
                        anchors.fill: parent;
                        anchors.margins: 3;
                        antialiasing: true;
                        color:"transparent"

                        Text {
                            id: itemNameText
                            text: name
                            color: "#545454"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width
                            anchors.leftMargin: 0
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }

                        Text {
                            id: itemCodeText
                            text: code
                            color: "white"
                            font.pixelSize: 16
                            font.family: Fonts.fontPlayRegular.name
                            visible: false
                            anchors.leftMargin: 20
                            anchors.top: itemNameText.bottom
                            anchors.topMargin: 7
                        }

                        Text {
                            id: itemStockText
                            text: stock
                            color: "white"
                            font.pixelSize: 16
                            font.family: Fonts.fontRubikRegular.name
                            font.italic: true
                            visible: false
                            anchors.top: itemNameText.bottom
                            anchors.left: itemCodeText.right
                            anchors.topMargin: 7
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        container2.ListView.view.currentIndex = index
                        container2.forceActiveFocus()
                    }

                    onDoubleClicked: {
                        salesRequest.post("sales/add/json", {item: itemListModel.get(index).id}, function(code, jsonStr){updateData(JSON.parse(jsonStr))});
                        itemList.visible = false

                        barcodeTextField.barcodeTextCleared = true;
                        barcodeTextField.text = "";
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            clicked();
                        }
                    }
                }

                states: State {
                    name: "active"; when: container2.activeFocus

                    PropertyChanges { target: container2; height: 75}
                    PropertyChanges { target: content989; color: "dodgerblue"; height: 75;}
                    PropertyChanges { target: itemNameText; font.pixelSize: 22; font.bold: true; color: "white" }
                    PropertyChanges { target: itemCodeText; visible:true}
                    PropertyChanges { target: itemStockText; visible:true}
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

    ComboBox {
        id: stockSelectComboBox
        anchors.right: parent.right
        anchors.top: custSelectButton.bottom
        anchors.topMargin: 4
        anchors.rightMargin: 4
        model:ListModel{id: stockSelectComboBoxModel}
        enabled: false
        height: 50
        font.pixelSize: 24
        width: 150
        placeholderText: "Stok"
        onCurrentIndexChanged: {
            if (stockSelectComboBox.enabled && modeSelectComboBox.enabled)
                salesRequest.post("sales/change_mode/json",
                                     {
                                         mode: modeSelectComboBoxModel.get(modeSelectComboBox.currentIndex).mode,
                                         stock_location: stockSelectComboBoxModel.get(stockSelectComboBox.currentIndex).stock_id
                                     },
                                     function(code, jsonStr){
                                        updateData(JSON.parse(jsonStr))
                                     });
        }
    }

    FocusScope {
        id: cartList
        width: parent.width
        anchors.top: modeSelectComboBox.bottom
        anchors.bottom: suspendedButton.top
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 1
            color: cartListView.activeFocus?"dodgerblue":"slategray"
        }

        ListView {
            id: cartListView
            width: parent.width; height: parent.height
            focus: true
            model: ListModel{id: cartListViewModel}
            cacheBuffer: 200
            delegate: Item {
                id: container
                width: parent.width; height: 50; anchors.leftMargin: 4; anchors.rightMargin: 4
                Rectangle {
                    id: content
                    anchors.centerIn: parent; width: container.width - 20; height: container.height - 10
                    color: "transparent"
                    antialiasing: true
                    radius: 4
                    z: 99
                    Rectangle {
                        anchors.fill: parent;
                        anchors.margins: 3;
                        antialiasing: true;
                        color: "transparent"
                        z: 99
                        Text {
                            id: label
                            text: name
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width / 2 - 20
                            anchors.left: amountSpinBox.right
                            anchors.leftMargin: 20
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }

                        Text {
                            id: barcodeText
                            text: barcode
                            color: "white"
                            visible: false
                            font.pixelSize: 20
                            font.family: Fonts.fontPlayRegular.name
                            anchors.left: label.left
                            anchors.top: label.bottom
                            anchors.topMargin: 20
                        }

                        Text {
                            id: stockText
                            text: stock
                            font.italic: true
                            color: "white"
                            visible: false
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: barcodeText.right
                            anchors.top: label.bottom
                            anchors.topMargin: 20
                        }

                        Text {
                            id: amountText
                            text: parseInt(amount)
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: parent.left
                            width: 152
                            horizontalAlignment: Text.AlignHCenter
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }

                        SpinBox {
                            id: amountSpinBox
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.top: parent.top
                            anchors.topMargin: 3
                            visible: false
                            value: amount
                            to: 100000
                            from: 1
                            stepSize: 1
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            width: amountText.width
                            property bool initialized
                            onValueChanged: {
                                if (!initialized)
                                    initialized = true;
                                else {
                                    var selectedItemIdx = cartListView.currentIndex;
                                    var curItemModel = cartListViewModel.get(selectedItemIdx);
                                    if (curItemModel) {
                                        salesRequest.post("sales/edit_item/" + curItemModel.sale_idx + "/json",
                                                            {quantity: parseInt(value), price: parseFloat(cost)/parseFloat(amount), discount: 0}, function(code, jsonStr){
                                                                updateData(JSON.parse(jsonStr)); cartListView.currentIndex = selectedItemIdx});
                                    }
                                }
                            }
                        }

                        Text {
                            id: costText
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

                        Button {
                            id:deleteButton
                            anchors.top: amountSpinBox.bottom
                            anchors.left: amountSpinBox.left
                            anchors.topMargin: 7
                            visible: false
                            text: "Sil"
                            height: amountSpinBox.height
                            width: amountSpinBox.width
                            font.pixelSize: 14
                            z: 100

                            borderColor:"indianred"
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    mouse.accepted = true;
                                    var selectedItemIdx = container.ListView.view.currentIndex;
                                    var curItemModel = cartListViewModel.get(selectedItemIdx);
                                    if (curItemModel) {
                                        salesRequest.get("sales/delete_item/" + curItemModel.sale_idx + "/json",
                                                        function(code, jsonStr){
                                                            updateData(JSON.parse(jsonStr));
                                                            if (selectedItemIdx > 0)
                                                                container.ListView.view.currentIndex = selectedItemIdx-1;
                                                        });
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    propagateComposedEvents: true
                    z: 98
                    onClicked: {
                        cartListView.currentIndex = index
                        container.forceActiveFocus()
                    }

                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color: "#CCD1D9"; height: 100; width: container.width - 15; anchors.leftMargin: 10; anchors.rightMargin: 15 }
                    PropertyChanges {
                        target: container
                        height: 100
                    }
                    PropertyChanges { target: label; font.pixelSize: 24; }
                    PropertyChanges { target: costText; font.pixelSize: 24; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
                    PropertyChanges { target: deleteButton; visible:true }
                    PropertyChanges { target: amountText; visible:false }
                    PropertyChanges { target: amountSpinBox; visible:true }
                    PropertyChanges { target: barcodeText; visible:true }
                    PropertyChanges { target: stockText; visible:true }
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
            color: cartListView.activeFocus?"dodgerblue":"slategray"
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: suspendedButton.right
        anchors.margins: 4
        width: parent.width - 316
        height: 50

        Label {
            id: itemNum
            text: "0 Ürün Toplam:"
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 3
            horizontalAlignment: "AlignHCenter"
            font.family: "Arial"
            font.pixelSize: 12
            color: "steelblue"
        }
        Label {
            id: totalCost
            anchors.top: itemNum.bottom
            anchors.topMargin: -9
            horizontalAlignment: "AlignHCenter"
            width: parent.width
            text: "0,00₺"
            font.family: Fonts.fontIBMPlexMonoRegular.name
            font.pixelSize: 32
            font.bold: true
            color: "steelblue"
        }
    }
    Button {
        id:suspendedButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.leftMargin: 4
        text: "Bekleyenler"
        height: 50
        width: 150
        font.pixelSize: 24
        Keys.onReturnPressed: {
            clicked();
        }

        onClicked: {
            salesRequest.get("sales/suspended/json", function(code, jsonStr){
                var suspendedList = JSON.parse(jsonStr)["suspended_sales"];
                var options = {day: '2-digit', month: '2-digit', year: 'numeric',  hour: '2-digit', minute: '2-digit'};
                suspendedListViewModel.clear();
                for (var idx in suspendedList){
                    var suspended = suspendedList[idx];
                    suspendedListViewModel.append({
                        sale_id: suspended.sale_id,
                        date: new Date(suspended.sale_time).toLocaleString("tr-TR", options),
                        customer:suspended.customer
                    });
                }
            });

            suspendedListPopup.open();
        }
    }

    Button {
        id:paymentButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        text: "Ödeme"
        height: 50
        width: 150
        font.pixelSize: 24
        Keys.onReturnPressed: {
            clicked();
        }
        onClicked: {
            salePage.parent.push('Payment.qml')
        }
        borderColor:"salmon"
    }
}
