import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import posapp.restrequest 1.0
import "../../fonts"

Page {
    id: paymentPage
    width:  800 //parent
    height:  440 //parent

    title: qsTr("Ödeme")

    RestRequest {
        id:pageLoadRequest

        onSessionTimeout: {
            console.log("sale_timeout");
            paymentPage.parent.pop();
        }
    }

    Component.onCompleted: {
        pageLoadRequest.get("sales/json", function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        paymentTextField.text = parseFloat(data["amount_due"]).toFixed(2);
        remainCost.text = paymentTextField.text + "₺";
        custNameText.text = data.customer?data.customer:"Müşteri Seçilmedi";
        paymentListViewModel.clear();

        finishButton.enabled = false;
        paymentTextField.enabled = true;
        typeButton.enabled = true;
        if ((data["mode"] === "sale" && parseFloat(data["amount_due"]) <= 0) ||
                (data["mode"] === "return" && parseFloat(data["amount_due"]) >= 0)) {
            paymentTextField.enabled = false;
            finishButton.enabled = true;
            typeButton.enabled = false;
        }

        paymentListViewModel.append({editable: false, type: "Ara Toplam", cost: parseFloat(data["subtotal"]).toFixed(2) + "₺"});
        var taxes_keys = Object.keys(data["taxes"]);
        for (var cnt=0; cnt < taxes_keys.length; cnt++) {
            var tax = data["taxes"][taxes_keys[cnt]];
            paymentListViewModel.append({editable: false, type: tax.tax_group, cost: parseFloat(tax.sale_tax_amount).toFixed(2) + "₺"});
        }

        paymentListViewModel.append({editable: false, type: "Toplam", cost: parseFloat(data["total"]).toFixed(2) + "₺"});

        var payment_keys = Object.keys(data["payments"]);
        for (cnt=0; cnt < payment_keys.length; cnt++) {
            var payment = data["payments"][payment_keys[cnt]];
            paymentListViewModel.append({editable: true, type: payment.payment_type, cost: parseFloat(payment.payment_amount).toFixed(2) + "₺"});
        }
    }

    function searchCustomer() {
        customerNameTextField.customerNameTextCleared = true;
        customerNameTextField.text = customerNameTextField.text.trim();
        pageLoadRequest.get("customers/search?search="+encodeURIComponent(customerNameTextField.text)+
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
                font.pointSize: 20
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
                            pageLoadRequest.post("sales/select_customer/json",{customer: customerListViewModel.get(index).num},
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

    ComboBox {
        id: typeButton
        KeyNavigation.left: paymentTextField
        KeyNavigation.down: paymentList
        anchors.left: parent.left
        anchors.top: custNameAsTitle.bottom
        anchors.topMargin: 4
        anchors.leftMargin: 4
        model:["Nakit", "Banka Kartı", "Kredi Kartı"]
        spacing: 5
        height: 50
        padding: 10
        font.pixelSize: 28
        font.family: Fonts.fontBarlowRegular.name
        width: 150
        background: Rectangle{
            implicitHeight: parent.height
            implicitWidth: parent.width
            color: !parent.enabled?"gainsboro": (parent.activeFocus?"dodgerblue":"slategray")
            radius: 0
        }
    }

    TextField {
        id: paymentTextField
        font.pointSize: 22
        activeFocusOnTab: true
        focus: true
        anchors.left: typeButton.right
        anchors.top: custNameAsTitle.bottom
        anchors.leftMargin: 4
        anchors.topMargin: 4
        topPadding: 8
        width: parent.width - 316
        height: 50
        font.family: Fonts.fontOrbitronRegular.name
        verticalAlignment: "AlignVCenter"
        z:98
        placeholderText: "Ödenen Tutar"
        background: Rectangle {
            border.color: !enabled?"gainsboro":(parent.activeFocus?"dodgerblue":"slategray")
            border.width: 2
            color: parent.activeFocus ?"dodgerblue": "white"
        }
        color: !enabled?"gainsboro":(activeFocus ? "white": "slategray")
        leftPadding: 10
        validator: DoubleValidator {bottom: 0; top: 100000}
        Keys.onReturnPressed: {
            pageLoadRequest.post("sales/add_payment/json",{payment_type: typeButton.currentText.replace(' ', '+'), amount_tendered: paymentTextField.text},
                                 function(code, jsonStr) {
                                    updateData(JSON.parse(jsonStr));
                                 });
        }

        Button {
            id:addPaymentButton
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.rightMargin: 6
            text: "Ödeme Ekle"
            spacing: 5
            autoExclusive: false
            height: 38
            width: 100
            font.family: Fonts.fontBarlowRegular.name
            font.pointSize: 14
            z:100
            Keys.onReturnPressed: {
                clicked();
            }
            onClicked: {
                pageLoadRequest.post("sales/add_payment/json",{payment_type: typeButton.currentText.replace(' ', '+'), amount_tendered: paymentTextField.text},
                                     function(code, jsonStr) {
                                        updateData(JSON.parse(jsonStr));
                                     });
            }

            background: Rectangle{
                anchors.fill:parent
                color: !enabled?"gainsboro":(parent.activeFocus?"darksalmon":"salmon")
            }
        }
    }

    Rectangle{
        id:custNameAsTitle
        width: parent.width
        height: 25
        color: "#d6e6f6"
        Text{
            id: custNameText
            text: "Müşteri Seçilmedi"
            anchors.centerIn: parent
            font.pixelSize: 18
            color: "slategray"
            font.family: Fonts.fontTomorrowSemiBold.name
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                searchCustomer();
                selectCustomerPopup.open();
            }
        }
    }

    Button {
        id: suspendButton
        KeyNavigation.left: paymentTextField
        KeyNavigation.down: paymentList
        anchors.right: parent.right
        anchors.top: custNameAsTitle.bottom
        anchors.topMargin: 4
        anchors.rightMargin: 4
        text: "Beklet"
        spacing: 5
        autoExclusive: false
        height: 50
        width: 150
        padding: 10
        font.pixelSize: 28
        font.family: Fonts.fontBarlowRegular.name
        background: Rectangle{
            anchors.fill:parent
            color: parent.activeFocus?"dodgerblue":"slategray"
        }
        onClicked: {
            pageLoadRequest.post("sales/suspend/json",{},
                                 function(code, jsonStr){
                                    updateData(JSON.parse(jsonStr));
                                    paymentPage.parent.pop();
                                 });
        }
    }

    FocusScope {
        id: paymentList
        width: parent.width
        height: 200
        anchors.top: suspendButton.bottom
        anchors.bottom: cancelButton.top
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 2
            color: paymentListView.activeFocus?"dodgerblue":"slategray"
        }

        ListView {
            id: paymentListView
            width: parent.width;
            height: parent.height
            focus: true
            /*Keys.onLeftPressed: {
              drawer.open()
            }*/
            KeyNavigation.down: finishButton
            model: ListModel{
                id: paymentListViewModel
            }
            cacheBuffer: 200
            delegate: Item {
                id: paymentContainer
                width: ListView.view.width; height: 40; anchors.leftMargin: 4; anchors.rightMargin: 4
                enabled: editable

                Rectangle {
                    id: paymentContent
                    anchors.centerIn: parent
                    width: enabled?paymentContainer.width - 20:paymentContainer.width
                    height: enabled?paymentContainer.height - 10:paymentContainer.height
                    color: enabled?"transparent":"#d6e6f6"
                    antialiasing: true
                    radius: enabled?4:0
                    z: 99
                    Rectangle {
                        anchors.fill: parent;
                        anchors.margins: 3;
                        antialiasing: true;
                        z: 99
                        color: "transparent"
                        Button {
                            id:deleteButton
                            width: 80
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.topMargin: 4
                            anchors.leftMargin: 40
                            visible: false
                            text: "Sil"
                            spacing: 5
                            autoExclusive: false
                            height: label1.height
                            padding: 10
                            checkable: true
                            font.family: Fonts.fontBarlowRegular.name
                            font.pointSize: 14
                            z:100
                            MouseArea{
                                anchors.fill: parent
                                onClicked: {
                                    mouse.accepted = true;
                                    pageLoadRequest.get("sales/delete_payment/" + encodeURIComponent(typeButton.currentText) + "/json",
                                                    function(code, jsonStr){
                                                        updateData(JSON.parse(jsonStr));
                                                    });
                                }
                            }

                            background: Rectangle{
                                anchors.fill:parent
                                color: parent.checked?"crimson":"indianred"
                            }
                        }

                        Text {
                            id: label1
                            text: type
                            color: "#545454"
                            font.pixelSize: enabled?20: 16
                            font.family: enabled?Fonts.fontRubikRegular.name: Fonts.fontTomorrowRegular.name
                            width: parent.width * 0.75 - 160
                            anchors.left: deleteButton.right
                            anchors.leftMargin: enabled?40:50
                            anchors.top: parent.top
                            anchors.topMargin: enabled?4:0
                        }

                        Text {
                            id: label3
                            horizontalAlignment: Text.AlignRight
                            anchors.rightMargin: enabled?4:14
                            anchors.right : parent.right
                            text: cost
                            color: "#545454"
                            font.pixelSize: enabled?24:20
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width * 0.25
                            anchors.top: parent.top
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    propagateComposedEvents: true
                    z:98
                    onClicked: {
                        paymentContainer.ListView.view.currentIndex = index
                        paymentContainer.forceActiveFocus()
                    }
                }

                states: State {
                    name: "active"; when: paymentContainer.activeFocus
                    PropertyChanges { target: paymentContent; color: "dodgerblue"; width: paymentContainer.width - 10; height:42; anchors.leftMargin: 10; anchors.rightMargin: 10;}
                    PropertyChanges { target: label1; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label3; font.pixelSize: 28; color: "white"; font.family: Fonts.fontIBMPlexMonoSemiBold.name}
                    PropertyChanges { target: deleteButton; visible:true }
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
            color: paymentListView.activeFocus?"dodgerblue":"slategray"
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: cancelButton.right
        width: parent.width - 316
        height: 50

        Label {
            id: itemNum
            text: "Kalan Tutar:"
            anchors.topMargin: -6
            width: parent.width
            anchors.top: parent.top
            horizontalAlignment: "AlignHCenter"
            font.family: "Arial"
            font.pointSize: 10
            color: "steelblue"
        }
        Label {
            id: remainCost
            anchors.top: itemNum.bottom
            anchors.topMargin: -12
            horizontalAlignment: "AlignHCenter"
            width: parent.width
            text: "0,00₺"
            font.family: Fonts.fontIBMPlexMonoRegular.name
            font.pointSize: 32
            font.bold: true
            color: "steelblue"
        }
    }

    Button {
        id:cancelButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.leftMargin: 4
        text: "İptal Et"
        spacing: 5
        autoExclusive: false
        height: 50
        width: 150
        padding: 10
        font.family: Fonts.fontBarlowRegular.name
        font.pointSize: 24
        Keys.onReturnPressed: {
            pageLoadRequest.post("sales/cancel/json",{},
                                 function(code, jsonStr) {
                                    updateData(JSON.parse(jsonStr));
                                     yesNoDialog.close();
                                     paymentPage.parent.pop();
                                 });
        }


        background: Rectangle{
            anchors.fill:parent
            color: parent.activeFocus?"crimson":"indianred"
        }
    }

    Button {
        id:finishButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        text: "Tamamla"
        spacing: 5
        autoExclusive: false
        height: 50
        width: 150
        padding: 10
        font.family: Fonts.fontBarlowRegular.name
        font.pointSize: 24
        Keys.onReturnPressed: {
            pageLoadRequest.post("sales/complete/json",{},
                                 function(code, jsonStr) {
                                    updateData(JSON.parse(jsonStr));
                                     paymentPage.parent.pop();
                                 });
        }

        background: Rectangle{
            anchors.fill:parent
            color: !finishButton.enabled?"gainsboro": (parent.activeFocus?"seagreen":"mediumseagreen")
        }
    }

}
