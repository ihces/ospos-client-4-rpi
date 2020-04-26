import QtQuick 2.7
import QtQuick.Controls 2.2
import posapp.restrequest 1.0
import "../../fonts"

Popup{
    id: control
    width: 300
    x: 250
    y: (parent.height-control.height)/2.0
    z: Infinity

    RestRequest {
        id: receiptRequest

        onSessionTimeout: {
            stack.pop();
        }
    }

    function getReceiptHeight() {
        return 290 + cart.height + payments.height;
    }

    function isOverflow() {
        return getReceiptHeight() > 440;
    }



    function getReceipt(transactionTypeDir, receiptId) {
        receiptRequest.get(transactionTypeDir + "/receipt/" + receiptId + "/json", function(code, jsonStr) {
            var data = JSON.parse(jsonStr);
            transactionTime.text = data.transaction_time;
            console.log(transactionTime.text);
            companyName.text = data.company_name;
            companyAddress.text = data.company_address;
            companyPhone.text = data.company_phone;
            returnPolicy.text = data.return_policy;
            employeeName.text = "Kasiyer: " + data.employee;
            barcode.source = "data:image/png;base64," + data.barcode;
            if (transactionTypeDir === "sales") {
                customerOrSupplierName.text = "Müşteri: " + data.customer;
                transactionId.text = data.sale_id;
                modeLabel.text = data.mode_label;
            }
            else {
                customerOrSupplierName.text = "Satıcı: " + data.supplier;
                transactionId.text = data.receiving_id;
                modeLabel.text = data.mode;
            }
            console.log(employeeName.text);
            cartListViewModel.clear();
            var keys = Object.keys(data.cart);
            for (var cnt = 0; cnt < keys.length; ++cnt) {
                var item = data.cart[keys[cnt]];
                cartListViewModel.append({name: item.name, quantity: parseInt(item.quantity), price: parseFloat(item.total).toFixed(2) + "₺"});
            }
            cart.height = 40 * keys.length;
            paymentListViewModel.clear();
            paymentListViewModel.append({type: "Toplam", amount: parseFloat(data.total).toFixed(2) + "₺"});
            console.log("allllo");
            if (transactionTypeDir === "sales") {
                var payment_keys = Object.keys(data.payments);
                for (cnt=0; cnt < payment_keys.length; cnt++) {
                    var payment = data["payments"][payment_keys[cnt]];
                    paymentListViewModel.append({type: payment.payment_type, amount: parseFloat(payment.payment_amount).toFixed(2) + "₺"});
                }
                paymentListViewModel.append({type: "Para Üstü", amount: parseFloat(data.amount_change).toFixed(2) + "₺"});
            }
            else
                paymentListViewModel.append({type: "Ödeme Şekli", amount: data.payment_type});
            payments.height = 20 * paymentListViewModel.count;

            control.visible = true;
        });
    }

    height: isOverflow()?parent.height:getReceiptHeight()
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    ScrollView{
        id: rectangle
        anchors.fill: parent
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        Flickable {
            contentHeight: getReceiptHeight()
            width: parent.width
            Text {
                id: companyName
                color: "darkslategray"
                font.pixelSize: 20
                font.family: Fonts.fontRubikRegular.name
                anchors.top: parent.top
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            Text {
                id: companyAddress
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.top: companyName.bottom
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            Text {
                id: companyPhone
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.top: companyAddress.bottom
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            Text {
                id: modeLabel
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.top: companyPhone.bottom
                anchors.topMargin: 10
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            Text {
                id: transactionTime
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.top: modeLabel.bottom
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            Text {
                id: customerOrSupplierName
                anchors.top: transactionTime.bottom
                anchors.left: parent.left
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.leftMargin: 5
                anchors.topMargin: 10
                width: parent.width-4
                horizontalAlignment: Text.AlignLeft
            }
            Text {
                id: transactionIdWithLabel
                text: "İşlem No: " + transactionId.text
                anchors.top: customerOrSupplierName.bottom
                anchors.left: parent.left
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.leftMargin: 5
                width: parent.width-4
                horizontalAlignment: Text.AlignLeft
            }
            Text {
                id: employeeName
                anchors.top: transactionIdWithLabel.bottom
                anchors.left: parent.left
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.leftMargin: 5
                width: parent.width-4
                horizontalAlignment: Text.AlignLeft
            }

            Rectangle {
                id: topLine
                color: "darkslategray"
                width: parent.width
                height: 1
                anchors.top: employeeName.bottom
                anchors.topMargin: 5
            }

            ListView {
                id: cart
                anchors.top: topLine.bottom
                width: parent.width
                model: ListModel {
                    id: cartListViewModel
                }
                delegate: Item {
                    width: cart.width
                    height: 40
                    Rectangle {
                            anchors.fill: parent;
                            anchors.margins: 3;
                            antialiasing: true;
                            color: "transparent"
                            Text {
                                id: nameText
                                text: name
                                color: "#545454"
                                font.pixelSize: 14
                                font.family: Fonts.fontRubikRegular.name
                                anchors.left: parent.left
                                width: parent.width
                                horizontalAlignment: Text.AlignLeft
                                anchors.top: parent.top
                            }
                            Text {
                                id: quantityText
                                text: quantity
                                color: "#545454"
                                font.pixelSize: 14
                                font.family: Fonts.fontRubikRegular.name
                                anchors.top: nameText.bottom
                                anchors.right: priceText.left
                                width: parent.width/3.0
                                horizontalAlignment: Text.AlignLeft
                            }
                            Text {
                                id: priceText
                                horizontalAlignment: Text.AlignRight
                                anchors.right : parent.right
                                anchors.rightMargin: 8
                                anchors.top: nameText.bottom
                                text: price
                                color: "#545454"
                                font.pixelSize: 14
                                font.family: Fonts.fontRubikRegular.name
                                width: parent.width/3.0
                            }
                    }
                }
            }
            Rectangle {
                id: bottomLine
                color: "darkslategray"
                width: parent.width
                height: 1
                anchors.top: cart.bottom
                anchors.topMargin: 5
            }
            ListView {
                id: payments
                anchors.top: bottomLine.bottom
                width: parent.width
                model: ListModel {
                    id: paymentListViewModel
                }
                delegate: Item {
                    width: cart.width
                    height: 20
                    Rectangle {
                            anchors.fill: parent;
                            anchors.margins: 3;
                            antialiasing: true;
                            color: "transparent"
                            Text {
                                id: paymentTypeText
                                text: type
                                color: "#545454"
                                font.pixelSize: 14
                                font.family: Fonts.fontRubikRegular.name
                                anchors.top: parent.top
                                anchors.right: amountText.left
                                width: parent.width/3.0
                                horizontalAlignment: Text.AlignLeft
                            }
                            Text {
                                id: amountText
                                horizontalAlignment: Text.AlignRight
                                anchors.right : parent.right
                                anchors.rightMargin: 8
                                anchors.top: parent.top
                                text: amount
                                color: "#545454"
                                font.pixelSize: 14
                                font.family: Fonts.fontRubikRegular.name
                                width: parent.width/3.0
                            }
                    }
                }
            }
            Text {
                id: returnPolicy
                text: "Test"
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.top: payments.bottom
                anchors.topMargin: 10
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            Image {
                id: barcode
                anchors.top: returnPolicy.bottom
                width: parent.width
            }
            Text {
                id: transactionId
                anchors.bottom: parent.bottom
                anchors.top: barcode.bottom
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
