import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtMultimedia 5.9
import posapp.restrequest 1.0
import "../../fonts"
import "../controls"
import "../popups"
import "../helpers/helper.js" as Helper

Page {
    id: paymentPage
    width:  800 //parent
    height:  430 //parent
    title: qsTr("Ödeme")
    property int busyIndicatorCnt: 0

    RestRequest {
        id:paymentRequest

        onSessionTimeout: {
            paymentPage.parent.pop();
        }

        onRequestTimeout: {
            paymentPage.parent.pop();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    SoundEffect {
        id: removeFromPaymentSound
        source: "../../sounds/delete.wav"
    }

    SoundEffect {
        id: doPaymentSound
        source: "../../sounds/payment.wav"
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
        id: switchSound
        source: "../../sounds/switch.wav"
    }

    ReceiptPopup {
        id: receiptPopup
        onVisibleChanged: {
            if (!visible) {
                popData = "complete";
                paymentPage.parent.pop();
            }
        }
    }

    ToastManager {
        id: toast
    }

    DialogPopup {
        id: dialogPopup
    }

    Component.onCompleted: {
        paymentRequest.get("sales/json", function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        paymentTextField.text = parseFloat(data["amount_due"]).toFixed(2).replace('.', ',');
        remainCost.text = Helper.toCurrency(data["amount_due"]);
        customerText.text = data.customer?data.customer:"Müşteri Seç";
        selectCustomerPopup.selectedCustomerId = data.customer_id?parseInt(data.customer_id): -1;
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

        paymentListViewModel.append({editable: false, type: "Ara Toplam", cost: Helper.toCurrency(data["subtotal"])});
        var taxes_keys = Object.keys(data["taxes"]);
        for (var cnt=0; cnt < taxes_keys.length; cnt++) {
            var tax = data["taxes"][taxes_keys[cnt]];
            paymentListViewModel.append({editable: false, type: tax.tax_group, cost: Helper.toCurrency(tax.sale_tax_amount)});
        }

        paymentListViewModel.append({editable: false, type: "Toplam", cost: Helper.toCurrency(data["total"])});

        var payment_keys = Object.keys(data["payments"]);
        for (cnt=0; cnt < payment_keys.length; cnt++) {
            var payment = data["payments"][payment_keys[cnt]];
            paymentListViewModel.append({editable: true, type: payment.payment_type.replace('+', ' '), cost: Helper.toCurrency(payment.payment_amount)});
        }

        paymentTextField.forceActiveFocus();
        printEnabledSign.visible = data.print_after_sale === "1";

        typeModel.clear();
        typeModel.append({name: "Nakit"});
        typeModel.append({name: "Kredi Kartı"});
        if (selectCustomerPopup.selectedCustomerId > 0)
            typeModel.append({name: "Veresiye"});
        typeButton.currentIndex = 0;
    }

    SelectCustomerPopup {
        id: selectCustomerPopup
        onClosed: {
            if (closeReason == "session_timeout")
                salePage.parent.pop();
            else if (closeReason != "ordinary"){
                paymentRequest.post("sales/select_customer/json",{customer: closeReason},
                                  function(code, jsonStr){
                                      customerSelectedSound.play();
                                      updateData(JSON.parse(jsonStr));
                                  });
            }
        }
    }

    ComboBox {
        id: typeButton
        anchors.left: parent.left
        anchors.top: custSelectButton.bottom
        anchors.topMargin: 4
        anchors.leftMargin: 4
        placeholderText: "Ödeme Türü"
        model:ListModel{
            id: typeModel
        }
        height: 50
        font.pixelSize: 24
        width: 150
        onCurrentIndexChanged: {
            addPaymentButton.text = currentIndex === 2?"Veresiye Ekle": "Ödeme Ekle";
        }
    }

    TextField {
        id: paymentTextField
        anchors.left: typeButton.right
        anchors.top: custSelectButton.bottom
        anchors.leftMargin: 4
        anchors.topMargin: 4
        width: parent.width - 316
        height: 50
        font.family: Fonts.fontOrbitronRegular.name
        font.pixelSize: 20
        z:98
        placeholderText: "Ödenen Tutar"
        validator: DoubleValidator {bottom: 0; top: 100000}
        Keys.onReturnPressed: {
            paymentRequest.post("sales/add_payment/json",{payment_type: typeButton.currentText.replace(' ', '+'), amount_tendered: paymentTextField.text},
                              function(code, jsonStr) {
                                  updateData(JSON.parse(jsonStr));
                              });
        }

        Button {
            id:addPaymentButton
            anchors.right: parent.right
            anchors.top: parent.top
            text: "Ödeme Ekle"
            height: parent.height
            width: 120
            font.pixelSize: 20
            z:100
            Keys.onReturnPressed: {
                clicked();
            }
            onClicked: {
                paymentRequest.post("sales/add_payment/json",{payment_type: typeButton.currentText.replace(' ', '+'), amount_tendered: paymentTextField.text},
                                  function(code, jsonStr) {
                                      doPaymentSound.play();
                                      updateData(JSON.parse(jsonStr));
                                  });
            }
            borderColor:"salmon"
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
                paymentRequest.get("sales/remove_customer/json", function(code, jsonStr){customerUnselectedSound.play();updateData(JSON.parse(jsonStr))});
            }
        }
    }

    Button {
        id: suspendButton
        anchors.right: parent.right
        anchors.top: custSelectButton.bottom
        anchors.topMargin: 4
        anchors.rightMargin: 4
        text: "Beklet"
        height: 50
        width: 150
        font.pixelSize: 24
        onClicked: {
            paymentRequest.post("sales/suspend/json",{},
                              function(code, jsonStr){
                                  //updateData(JSON.parse(jsonStr));
                                  popData = "suspend";
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
            height: 1
            color: paymentListView.activeFocus?"dodgerblue":"slategray"
        }

        ListView {
            id: paymentListView
            width: parent.width;
            height: parent.height
            focus: true
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
                    Button {
                        id:deleteButton
                        width: 80
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                        anchors.leftMargin: 40
                        visible: false
                        text: "Sil"
                        font.pixelSize: 14
                        z:100
                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                paymentRequest.get("sales/delete_payment/" + encodeURIComponent(type.replace(' ', '+')) + "/json",
                                                 function(code, jsonStr){
                                                     removeFromPaymentSound.play();
                                                     updateData(JSON.parse(jsonStr));
                                                 });
                            }
                        }

                        borderColor:"indianred"
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
                    PropertyChanges { target: paymentContent; color: "#CCD1D9"; width: paymentContainer.width - 15; height:42; anchors.leftMargin: 10; anchors.rightMargin: 15;}
                    PropertyChanges { target: label1; font.pixelSize: 24; }
                    PropertyChanges { target: label3; font.pixelSize: 24; font.family: Fonts.fontIBMPlexMonoSemiBold.name}
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
            height: 1
            color: paymentListView.activeFocus?"dodgerblue":"slategray"
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: cancelButton.right
        width: parent.width - 316
        anchors.margins: 4
        height: 50

        Label {
            id: itemNum
            text: "Kalan Tutar:"
            anchors.topMargin: 3
            width: parent.width
            anchors.top: parent.top
            horizontalAlignment: "AlignHCenter"
            font.family: "Arial"
            font.pixelSize: 12
            color: "steelblue"
        }
        Label {
            id: remainCost
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
        id:cancelButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.leftMargin: 4
        text: "İptal Et"
        height: 50
        width: 150
        font.pixelSize: 24
        Keys.onReturnPressed: {
            clicked();
        }
        onClicked: {
            dialogPopup.confirmation("İptal Et", "İptal işlemini onayladığınızda bu satışa ait tüm bilgiler silinecek.", function(){
                paymentRequest.post("sales/cancel/json",{},
                              function(code, jsonStr) {
                                  popData = "cancel";
                                  paymentPage.parent.pop();
                              });
                });
        }
        borderColor:"indianred"
    }

    Button {
        id:finishButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        text: "Tamamla"
        height: 50
        width: 150
        font.pixelSize: 24
        Keys.onReturnPressed: {
            clicked();
        }

        onClicked: {
            paymentRequest.post("sales/complete/json",
                              function(code, jsonStr) {
                                  var data = JSON.parse(jsonStr);
                                  if (data.sale_id_num > 0){
                                      receiptPopup.getReceipt("sales", data.sale_id_num, printEnabledSign.visible);
                                      toast.showSuccess("İşlem Tamamlandı!", 3000);
                                  }
                                  else {
                                      toast.showError("İşlem tamamlanırken bir sorun meydana geldi!", 3000);
                                  }
                              });
        }
        borderColor:"mediumseagreen"
    }
    Button {
        id: printOption
        anchors.right: finishButton.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        width: 50
        height: 50
        font.family: Fonts.fontAwesomeSolid.name
        font.pixelSize: 30
        text: "\uF543"
        onClicked: {
            paymentRequest.post("sales/set_print_after_sale", {sales_print_after_sale: !printEnabledSign.visible},
                              function(code, jsonStr) {
                                  if (code === "200") {
                                      switchSound.play();
                                      printEnabledSign.visible = !printEnabledSign.visible;
                                      //toast.showSuccess("Yazdırma seçeneği değiştirildi!", 3000);
                                  } else
                                      toast.showError("Yazdırma seçeneği değiştirilemedi!", 3000);
                              });
        }

        Text {
            id: printEnabledSign
            z:100
            text: "\uF058"
            font.family: Fonts.fontAwesomeSolid.name
            font.pixelSize: 16
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 2
            anchors.rightMargin: 2
            color: "dodgerblue"
            visible: true
        }
    }
}
