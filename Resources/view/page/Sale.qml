import QtQuick 2.7
import QtQuick.Controls 2.0
import QtMultimedia 5.9
import posapp.restrequest 1.0

import "../../fonts"
import "../controls"
import "../popups"
import "../helpers/helper.js" as Helper

Page {
    id: salePage
    width:  800
    height:  430
    title: qsTr("Satış")

    property int busyIndicatorCnt: 0
    property bool itemAdded2Cart: false

    Component.onCompleted: {
        salesRequest.get("sales/json", function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    onVisibleChanged: {
        if (visible) {
            salesRequest.get("sales/json", function(code, jsonStr){updateData(JSON.parse(jsonStr));});
        }
    }

    SoundEffect {
        id: add2cartSuccessSound
        source: "../../sounds/add_to_cart_success.wav"
    }

    SoundEffect {
        id: removeFromCartSuccessSound
        source: "../../sounds/delete.wav"
    }

    SoundEffect {
        id: customerSelectedSound
        source: "../../sounds/customer_selected.wav"
    }

    SoundEffect {
        id: customerUnselectedSound
        source: "../../sounds/customer_removed.wav"
    }

    SoundEffect {
        id: unsuspendSound
        source: "../../sounds/unsuspend.wav"
    }

    SoundEffect {
        id: modeChangedSound
        source: "../../sounds/mode_changed.wav"
    }

    SoundEffect {
        id: suspendSound
        source: "../../sounds/suspend.wav"
    }

    SoundEffect {
        id: cancelSound
        source: "../../sounds/cancel.wav"
    }

    SoundEffect {
        id: completeSound
        source: "../../sounds/complete.wav"
    }

    SoundEffect {
        id: increaseItemAmtSound
        source: "../../sounds/item_increase.wav"
    }

    SoundEffect {
        id: decreaseItemAmtSound
        source: "../../sounds/item_decrease.wav"
    }

    RestRequest {
        id:salesRequest

        onSessionTimeout: {
            salePage.parent.pop();
        }

        onRequestTimeout: {
            salePage.parent.pop();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    FavoriteItemsPopup {
        id: favoriteItemsPopup
        onClosed: {
            if (closeReason == "session_timeout")
                salePage.parent.pop();
            else if (closeReason != "ordinary"){
                add2cart(closeReason);
            }
        }
    }

    SuspendedPopup {
        id: suspendedPopup
        onClosed: {
            if (closeReason == "session_timeout")
                salePage.parent.pop();
            else if (closeReason != "ordinary"){
                salesRequest.post("sales/unsuspend/json",{suspended_sale_id: closeReason, submit: "Satışa+Al"},
                                  function(code, jsonStr){
                                      unsuspendSound.play();
                                      updateData(JSON.parse(jsonStr));
                                  });
            }
        }
    }

    SelectCustomerPopup {
        id: selectCustomerPopup
        onClosed: {
            if (closeReason == "session_timeout")
                salePage.parent.pop();
            else if (closeReason != "ordinary"){
                salesRequest.post("sales/select_customer/json",{customer: closeReason},
                                  function(code, jsonStr){
                                      customerSelectedSound.play();
                                      updateData(JSON.parse(jsonStr));
                                  });
            }
        }
    }

    function add2cart(item_id) {
        salesRequest.post("sales/add/json", {item: item_id}, function(code, jsonStr){
            itemAdded2Cart = true;
            updateData(JSON.parse(jsonStr));
        });
        itemList.visible = false
        clearBarcodeTextField();
    }

    function clearBarcodeTextField() {
        barcodeTextField.barcodeTextCleared = true;
        barcodeTextField.text = "";
        barcodeTextField.forceActiveFocus();
    }

    function updateData(data) {
        modeSelectComboBox.enabled = false;
        stockSelectComboBox.enabled = false;

        itemNum.text = data["item_count"] + " Ürün Toplam:";
        totalCost.text = Helper.toCurrency(data["total"]);
        modeSelectComboBox.currentIndex = (data.mode === "sale" ? 0:1);

        customerText.text = data.customer?data.customer:"Müşteri Seç";
        selectCustomerPopup.selectedCustomerId = data.customer_id?parseInt(data.customer_id): -1;
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
            cartListViewModel.append({cart_item_id:keys[cnt], item_id: item.item_id, barcodeNstock: item.item_number + (item.item_number.length > 0? " | ": "") + "Mevcut Stok: " + parseInt(item.in_stock) + " ("+item.stock_name +")",
                                         amount: item.quantity, name: item.name, total: item.total, price: item.price, location: item.item_location});
        }

        modeSelectComboBox.enabled = true;
        stockSelectComboBox.enabled = stockSelectComboBoxModel.count > 0;

        if(itemAdded2Cart) {
            itemAdded2Cart = false;
            add2cartSuccessSound.play();
        }
        clearBarcodeTextField();

        if (popData.length > 0) {
            salesRequest.post("sales/change_mode/json",
                          {
                              mode:'sale',
                              stock_location: stockSelectComboBoxModel.get(stockSelectComboBox.currentIndex).stock_id
                          },
                          function(code, jsonStr){
                              modeSelectComboBox.currentIndex = 0;
                              switch(popData) {
                              case "complete":
                                  completeSound.play();
                                  break;
                              case "cancel":
                                  cancelSound.play();
                                  break;
                              case "suspend":
                                  suspendSound.play();
                                  break;
                              default:
                                  break;
                              }
                          });
        }
        popData = "";
    }

    function updateSearchItemList(data) {
        itemListModel.clear();
        if (parseInt(data.total) === 1 && barcodeTextField.text.trim() === data.rows[0]["item_number"]) {
            add2cart(data.rows[0]["items.item_id"]);
        }
        else {
            for (var cnt=0; cnt < parseInt(data.total); cnt++) {
                itemListModel.append({id: data.rows[cnt]["items.item_id"],
                                         name: data.rows[cnt]["name"],
                                         code_category: data.rows[cnt]["item_number"] + (data.rows[cnt]["item_number"].length > 0 ? " | ":"") + data.rows[cnt]["category"]});
            }

            itemList.visible = itemListModel.count > 0;
        }
    }

    Button{
        id:custSelectButton
        width: parent.width
        anchors.margins: 0
        height: 40
        font.pixelSize: 24
        onClicked: {
            selectCustomerPopup.open();
        }

        Text {
            id: customerText
            font: parent.font
            color: parent.pressed?"white":parent.borderColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            anchors.centerIn: parent
        }

        Button {
            visible: customerText.text != "Müşteri Seç" && customerText.text.length > 0
            anchors.left: customerText.right
            anchors.leftMargin: 4
            text: "Kaldır"
            borderColor: "indianred"
            height: parent.height
            onClicked: {
                salesRequest.get("sales/remove_customer/json", function(code, jsonStr){customerUnselectedSound.play();updateData(JSON.parse(jsonStr))});
            }
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
                                      modeChangedSound.play();
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
        onActiveFocusChanged: {
            if (!activeFocus && !itemList.activeFocus)
                itemList.visible = false;
        }
        onTextChanged: {
            if (barcodeTextCleared) {
                barcodeTextCleared = false
            }
            else {
                salesRequest.get("items/search",
                                 {"search": barcodeTextField.text, order:"asc", limit: 10, start_date: new Date(2010, 1, 1).toISOString(), end_date: new Date().toISOString(), "filters": []},
                                 function(code, jsonStr){updateSearchItemList(JSON.parse(jsonStr))});
            }
        }
        Button {
            id:fastAddButton
            anchors.right: parent.right
            anchors.top: parent.top
            text: "Ürünler"
            height: parent.height
            font.pixelSize: 20
            width: 120
            z:100
            Keys.onReturnPressed: {
                clicked();
            }
            onClicked: {
                favoriteItemsPopup.open();
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
        onActiveFocusChanged: {
            if (!activeFocus && !barcodeTextField.activeFocus)
                itemList.visible = false;
        }
        visible: false
        z: 1000

        clip: true

        Rectangle {
            width: parent.width
            height: parent.height
            color: "white"
            border.color: "slategray"
            border.width: 1
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
                        text: code_category
                        color: "slategray"
                        font.pixelSize: 16
                        font.family: Fonts.fontPlayRegular.name
                        visible: false
                        anchors.leftMargin: 20
                        anchors.top: itemNameText.bottom
                        anchors.topMargin: 7
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
                        add2cart(itemListModel.get(index).id);
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
                    PropertyChanges { target: content989; color: "#CCD1D9"; height: 75;}
                    PropertyChanges { target: itemNameText; font.pixelSize: 22; }
                    PropertyChanges { target: itemCodeText; visible:true}
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
                                      modeChangedSound.play();
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
            color: "slategray"
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
                    anchors.centerIn: parent; width: container.width - 20; height: container.height - 4
                    color: "transparent"
                    antialiasing: true
                    radius: 4
                    z: 99
                    Text {
                        id: cartItemNameText
                        text: name
                        color: "#545454"
                        font.pixelSize: 20
                        font.family: Fonts.fontRubikRegular.name
                        width: parent.width / 2 - 20
                        anchors.left: amountSpinBox.right
                        anchors.leftMargin: 20
                        anchors.top: parent.top
                        anchors.topMargin: (amountSpinBox.height - cartItemNameText.height)/2 + 4
                    }
                    Text {
                        id: barcodeText
                        text: barcodeNstock
                        color: "slategray"
                        visible: false
                        font.pixelSize: 18
                        font.family: Fonts.fontPlayRegular.name
                        anchors.left: cartItemNameText.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: (deleteButton.height - barcodeText.height)/2 + 4
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
                        anchors.topMargin: (amountSpinBox.height - amountText.height)/2 + 4
                    }
                    SpinBox {
                        id: amountSpinBox
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        editable: true
                        visible: false
                        value: amount
                        to: amount < 0 ? -1: 100000
                        from: amount < 0 ? -100000: 1
                        stepSize: 1
                        font.pixelSize: 20
                        font.family: Fonts.fontRubikRegular.name
                        width: amountText.width
                        property bool initialized
                        property int oldValue: amount
                        onValueChanged: {
                            if (!initialized)
                                initialized = true;
                            else {
                                var selectedItemIdx = cartListView.currentIndex;
                                var curItemModel = cartListViewModel.get(selectedItemIdx);
                                if (curItemModel) {
                                    var newValue = parseInt(value);
                                    salesRequest.post("sales/edit_item/" + curItemModel.cart_item_id + "/json",
                                                      {quantity: newValue, price: price.replace('.', ','), discount: 0, location: location}, function(code, jsonStr){
                                                          if (newValue > oldValue)
                                                              increaseItemAmtSound.play();
                                                          else
                                                              decreaseItemAmtSound.play();
                                                          oldValue = newValue;
                                                          updateData(JSON.parse(jsonStr)); cartListView.currentIndex = selectedItemIdx});
                                }
                            }
                        }
                    }

                    Text {
                        id: totalText
                        horizontalAlignment: Text.AlignRight
                        anchors.rightMargin: 4
                        anchors.right : parent.right
                        text: Helper.toCurrency(total)
                        color: "#545454"
                        font.pixelSize: 24
                        font.family: Fonts.fontIBMPlexMonoRegular.name
                        width: parent.width / 4
                        anchors.top: parent.top
                        anchors.topMargin: (amountSpinBox.height - totalText.height)/2 + 4
                    }

                    Text {
                        id: totalDetailText
                        horizontalAlignment: Text.AlignRight
                        anchors.rightMargin: 4
                        anchors.right : parent.right
                        text: amountText.text + " x " + Helper.toCurrency(price)
                        color: "slategray"
                        font.pixelSize: 18
                        font.family: Fonts.fontIBMPlexMonoRegular.name
                        width: parent.width / 4
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: (deleteButton.height-totalDetailText.height)/2 + 4
                        visible: false
                    }

                    Button {
                        id:deleteButton
                        anchors.top: amountSpinBox.bottom
                        anchors.left: amountSpinBox.left
                        anchors.topMargin: 4
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
                                    salesRequest.get("sales/delete_item/" + curItemModel.cart_item_id + "/json",
                                                     function(code, jsonStr){
                                                         removeFromCartSuccessSound.play();
                                                         updateData(JSON.parse(jsonStr));
                                                         if (selectedItemIdx > 0)
                                                             container.ListView.view.currentIndex = selectedItemIdx-1;
                                                     });
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
                    name: "active"; when: container.activeFocus || Helper.anyDescendantHasActiveFocus(container)
                    PropertyChanges { target: container; height: 2*amountSpinBox.height + 12; }
                    PropertyChanges { target: content; color: "#CCD1D9"; height: container.height; width: container.width - 15; anchors.leftMargin: 4; anchors.rightMargin: 15 }
                    PropertyChanges { target: cartItemNameText; font.pixelSize: 22; }
                    PropertyChanges { target: totalText; font.pixelSize: 26; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
                    PropertyChanges { target: deleteButton; visible:true }
                    PropertyChanges { target: amountText; visible:false }
                    PropertyChanges { target: amountSpinBox; visible:true }
                    PropertyChanges { target: barcodeText; visible:true }
                    PropertyChanges { target: totalDetailText; visible:true }
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
            color: "slategray"
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
            suspendedPopup.open();
        }
    }

    Button {
        id:paymentButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        enabled: cartListViewModel.count > 0
        text: "Ödeme"
        height: 50
        width: 150
        font.pixelSize: 24
        Keys.onReturnPressed: {
            clicked();
        }
        onClicked: {
            salesRequest.post("sales/change_mode/json",
                              {
                                  mode: totalCost.text.charAt(0) == '-'?'return': 'sale',
                                  stock_location: stockSelectComboBoxModel.get(stockSelectComboBox.currentIndex).stock_id
                              },
                              function(code, jsonStr){
                                  salePage.parent.push('Payment.qml');
                              });
        }
        borderColor:"salmon"
    }
}
