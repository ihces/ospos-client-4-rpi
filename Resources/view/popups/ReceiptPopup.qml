import QtQuick 2.7
import QtQuick.Controls 2.2
import posapp.restrequest 1.0
import "../../fonts"
import "../helpers/helper.js" as Helper

Popup{
    id: control
    width: 300
    x: 250
    y: (parent.height-control.height)/2.0
    z: 100

    RestRequest {
        id: receiptRequest

        onSessionTimeout: {
            stack.pop();
        }
        onRequestTimeout: {
            stack.pop();
        }
    }

    function getReceiptHeight() {
        return 290 + cart.height + payments.height;
    }

    function isOverflow() {
        return getReceiptHeight() > 440;
    }

    function getReceipt(transactionTypeDir, receiptId, print) {
        receiptRequest.get(transactionTypeDir + "/receipt/" + receiptId + "/json", function(code, jsonStr) {
            var data = JSON.parse(jsonStr);

            transactionTime.text = data.transaction_time;
            companyName.text = data.company_name;
            companyAddress.text = data.company_address;
            companyPhone.text = data.company_phone;
            returnPolicy.text = data.return_policy;
            employeeName.text = "Kasiyer: " + data.employee;
            //barcode.source = "data:image/png;base64," + data.barcode;
            if (transactionTypeDir === "sales") {
                customerOrSupplierName.text = data.customer?"Müşteri: " + data.customer:"";
                transactionIdWithLabel.text = "İşlem No :" + data.sale_id;
                modeLabel.text = data.mode_label;
            }
            else {
                customerOrSupplierName.text = data.supplier?"Satıcı: " + data.supplier: "";
                transactionIdWithLabel.text = "İşlem No :" + data.receiving_id;
                modeLabel.text = data.mode = data.mode === "receive"?"Alım Fişi": "İade Fişi";
            }
            cartListViewModel.clear();
            var keys = Object.keys(data.cart);
            for (var cnt = 0; cnt < keys.length; ++cnt) {
                var item = data.cart[keys[cnt]];
                cartListViewModel.append({name: item.name, quantityNunitPrice: parseInt(item.quantity) + " x " + parseFloat(item.price).toFixed(2), price: parseFloat(item.total).toFixed(2)});
            }
            cart.height = 40 * keys.length;
            paymentListViewModel.clear();
            paymentListViewModel.append({type: "Toplam", amount: parseFloat(data.total).toFixed(2)});
            if (transactionTypeDir === "sales") {
                var payment_keys = Object.keys(data.payments);
                for (cnt=0; cnt < payment_keys.length; cnt++) {
                    var payment = data["payments"][payment_keys[cnt]];
                    paymentListViewModel.append({type: payment.payment_type, amount: parseFloat(payment.payment_amount).toFixed(2)});
                }
                paymentListViewModel.append({type: "Para Üstü", amount: parseFloat(data.amount_change).toFixed(2)});
            }
            else
                paymentListViewModel.append({type: "Ödeme Şekli", amount: data.payment_type});
            payments.height = 20 * paymentListViewModel.count;

            if (print !== undefined && print) {
                postRequest("print_receipt", data, cartListViewModel.count * 1000 + 6000, function() {
                    toast.showError("Fiş yazdırılamadı!", 3000);
                });
            }

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
                id: transactionIdWithLabel
                anchors.top: transactionTime.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.leftMargin: 5
                width: parent.width-4
                horizontalAlignment: Text.AlignLeft
            }
            Text {
                id: customerOrSupplierName
                anchors.top: transactionIdWithLabel.bottom
                anchors.left: parent.left
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.leftMargin: 5
                width: parent.width-4
                visible: text.length > 0
                horizontalAlignment: Text.AlignLeft
            }
            Text {
                id: employeeName
                anchors.top: customerOrSupplierName.visible?customerOrSupplierName.bottom:transactionIdWithLabel.bottom
                anchors.left: parent.left
                color: "darkslategray"
                font.pixelSize: 14
                font.family: Fonts.fontRubikRegular.name
                anchors.leftMargin: 5
                width: parent.width-4
                horizontalAlignment: Text.AlignLeft
            }

            ListView {
                id: cart
                anchors.top: employeeName.bottom
                anchors.topMargin: 14
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
                                id: quantityNunitPriceText
                                text: quantityNunitPrice
                                color: "#545454"
                                font.pixelSize: 14
                                font.family: Fonts.fontRubikRegular.name
                                anchors.top: nameText.bottom
                                anchors.left: parent.left
                                width: parent.width/2.0
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
                                width: parent.width/2.0
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
                anchors.topMargin: 14
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            /*Image {
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
            }*/
        }
    }
}
