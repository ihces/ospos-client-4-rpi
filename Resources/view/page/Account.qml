import QtQuick 2.7
import QtQuick.Controls 2.0
import QtMultimedia 5.9
import posapp.restrequest 1.0

import "../../fonts"
import "../controls"

Page {
    id: accountPage
    width:  800 //parent
    height:  440 //parent

    title: qsTr("Alacak Hesabı")

    property int person_id
    property string phone
    property string address
    property int busyIndicatorCnt: 0

    RestRequest {
        id:accountRequest

        onSessionTimeout: {
            accountsPage.parent.pop();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    ToastManager{
        id: toast
    }

    Component.onCompleted: {
        phoneAndAddress.text = "Tel: "+ phone + "\nAdres: " + address;
        selectLastTransactionsByDate.currentIndex = 6
        updateTotalDue();
    }

    ReceiptPopup {
        id: receiptPopup
    }

    function updateTotalDue() {
        accountRequest.get("customers/get_total_due/" +person_id,
                           function(code, jsonStr) {
                               var data = JSON.parse(jsonStr);
                               totalCost.text = parseFloat(data).toFixed(2) + "₺";
                           });
    }

    function doPayment(paymentType, paymentAmount) {
        accountRequest.get("sales/json",
                           function(code, jsonStr) {
                               var data = JSON.parse(jsonStr);
                               accountRequest.post("sales/change_mode/json",
                                                   {
                                                       mode: "sale",
                                                       stock_location: Object.keys(data.stock_locations)[0]
                                                   },
                                                   function(code, jsonStr) {
                                                       accountRequest.post("sales/select_customer/json",
                                                                           {customer: person_id},
                                                                           function(code, jsonStr) {
                                                                               accountRequest.post("sales/add/json", {item: "0000000000000"}, function(code, jsonStr){
                                                                                   accountRequest.post("sales/add_payment/json",
                                                                                                   {
                                                                                                       payment_type: paymentType,
                                                                                                       amount_tendered: paymentAmount
                                                                                                   },
                                                                                                   function(code, jsonStr) {
                                                                                                      accountRequest.post("sales/complete/json", {only_payment: true}, function(code, jsonStr) {
                                                                                                          var data = JSON.parse(jsonStr);

                                                                                                          if (parseInt(data.sale_status) === 0 ){
                                                                                                              selectLastTransactionsByDate.currentIndex = 6;
                                                                                                              updateTotalDue();
                                                                                                              doPaymentPopup.visible = false;
                                                                                                              toast.showSuccess("Ödeme başarıyla yapıldı.", 3000);
                                                                                                          }
                                                                                                          else
                                                                                                              toast.showError("Ödeme yapılırken bir hata meydana geldi.", 3000);
                                                                                                      });
                                                                                                   });
                                                                               });
                                                                           });
                                                   });
                           });
    }

    function getTransactions() {
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
        var searchObj = {start_date: startDateStr, end_date: endDateStr};

        accountRequest.get("sales/get_transactions/" + person_id, searchObj, function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        transactionListViewModel.clear();
        if (data.length > 0)
            accountName.text = data[0].customer_name;
        for (var cnt = 0; cnt < data.length; ++cnt) {
            var sale = data[cnt];

            var saleTypeStr="Satış";
            if (sale.sale_type === "4")
                saleTypeStr = "İade";

            var amountDue = parseFloat(sale.amount_due.replace(/[₺|.]/g, '').replace(',', '.'));

            var payments = sale.payment_type.split(',');

            var remainAmount = 0.0;
            var paymentAmount = 0.0;

            if (amountDue === 0.0) {
                saleTypeStr = "Ödeme";
                paymentAmount = -parseFloat(payments[0].split(' ')[1]);
            }
            else {
                for (var cnt1 =0; cnt1 < payments.length; ++ cnt1)
                    if (payments[cnt1].startsWith("Due")) {
                        remainAmount = parseFloat(payments[cnt1].split(' ')[1]);
                        break;
                    }
            }

            transactionListViewModel.append({id: sale["sale_id"], date: sale.sale_time, type: saleTypeStr, cost: amountDue.toFixed(2)+ "₺", payment: (saleTypeStr === "Ödeme" ? paymentAmount:(amountDue-remainAmount)).toFixed(2) + "₺", remain: remainAmount.toFixed(2)+ "₺"});
        }
    }

    Popup{
        id: doPaymentPopup
        width: parent.width * 0.5
        height: parent.height * 0.5
        x: parent.width * 0.25
        y: parent.height * 0.2
        z: Infinity
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        onVisibleChanged: {
            if (!visible) {
                paymentAmountField.needValidate = false;
                paymentAmountField.text = "";
            }
        }

        Rectangle{
            width: parent.width * 0.9
            height: parent.height * 0.9
            anchors.centerIn: parent
            Text {
                id: descriptionText
                text: "Ödeme Yap"
                color: "slategray"
                font.pixelSize: 24
                font.family: Fonts.fontRubikRegular.name
                anchors.top: parent.top
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            RadioButton {
                id: paymentTypeCash
                anchors.left: parent.left
                anchors.top: descriptionText.bottom
                anchors.topMargin: 20
                text: "Nakit"
                checked: true
                width: parent.width / 2
            }
            RadioButton {
                id: paymentTypeCreditCard
                anchors.right: parent.right
                anchors.top: descriptionText.bottom
                anchors.topMargin: 20
                text: "Kredi Kartı"
                width: parent.width / 2
            }
            TextField {
                id: paymentAmountField
                anchors.right: parent.right
                anchors.top: paymentTypeCash.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 5
                width: parent.width
                required: true
                validator: RegExpValidator{
                    regExp: /^\s*-?((\d{1,3}(\.(\d){3})*)|\d*)(,\d{1,2})?\s?(\u20BA)?\s*$/
                }
                placeholderText: "Ödeme Tutarı"
            }

            Button {
                id:cancelButton
                text: "İptal"
                height: 40
                width: 100
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                font.pixelSize: 20
                onClicked:{
                    doPaymentPopup.visible = false
                }
            }

            Button {
                id:updateButton
                text: "Ödeme Yap"
                height: 40
                width: 100
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                font.pixelSize: 20
                borderColor: "salmon"
                onClicked:{
                    paymentAmountField.needValidate = true;
                    if (paymentAmountField.isInvalid())
                        toast.showError("Ödeme tutarı giriniz!", 3000);
                    else
                        doPayment(paymentTypeCash.checked?"Cash": "Credit Card", paymentAmountField.text.replace('.', ''));
                }
            }
        }
    }

    SoundEffect {
        id: clickBasicSound
        source: "../../sounds/220197-click-basic.wav"
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

    Rectangle {
        id: accountTitleRight
        width: 150
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        antialiasing: true;
        color: "#f7f8fa"
        height: 50
        Text {
            id: phoneAndAddress
            wrapMode: Text.WordWrap
            color: "slategray"
            font.pixelSize: 11
            font.family: Fonts.fontRubikRegular.name
            anchors.right: parent.right
            width: parent.width
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            anchors.top: parent.top
            anchors.topMargin: 3
            rightPadding: 7
        }
    }

    Rectangle {
        id: accountTitle
        width: parent.width - 316
        anchors.left: selectLastTransactionsByDate.right
        anchors.top: parent.top
        anchors.margins: 4
        antialiasing: true;
        color: "#f7f8fa"
        height: 50
        Text {
            id: accountNum
            text: person_id
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
            id: accountName
            anchors.topMargin: -6
            color: "slategray"
            font.pixelSize: 24
            font.family: Fonts.fontTomorrowRegular.name
            anchors.left: parent.left
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            anchors.top: accountNum.bottom
        }
    }

    FocusScope {
        id: transactionList
        y: 58
        width: parent.width
        height: parent.height - 116
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 1
            color: transactionListView.activeFocus?"dodgerblue":"slategray"
        }

        ListView {
            id: transactionListView
            width: parent.width; height: parent.height
            focus: true
            model: ListModel{
                 id: transactionListViewModel
            }
            cacheBuffer: 200
            delegate: Item {
                id: container
                width: ListView.view.width; height: 50; anchors.leftMargin: 4; anchors.rightMargin: 4
                Rectangle {
                    id: content
                    anchors.centerIn: parent; width: container.width - 20; height: container.height - 10
                    color: "transparent"
                    border.color: "transparent"
                    border.width: 0
                    antialiasing: true
                    radius: 4
                        ListViewColumnLabel{
                            text: "İşlem Tarihi"
                            labelOf: transactionTime
                        }
                        Text {
                            id: transactionTime
                            text: date
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 16
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: parent.left
                            width: parent.width/3
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "İşlem Tipi"
                            labelOf: transactionType
                        }
                        Text {
                            id: transactionType
                            text: type
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width/6
                            anchors.left: transactionTime.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                        ListViewColumnLabel{
                            text: "İşlem Tutarı"
                            labelOf: transactionCost
                        }
                        Text {
                            id: transactionCost
                            anchors.rightMargin: 4
                            anchors.right : transactionPayment.left
                            text: cost
                            visible: type != "Ödeme"
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 20
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width/6
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        ListViewColumnLabel{
                            text: "Ödenen"
                            labelOf: transactionPayment
                        }
                        Text {
                            id: transactionPayment
                            anchors.rightMargin: 4
                            anchors.right : transactionRemain.left
                            text: payment
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 20
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width/6
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        ListViewColumnLabel{
                            text: "Kalan"
                            labelOf: transactionRemain
                        }
                        Text {
                            id: transactionRemain
                            anchors.rightMargin: 4
                            anchors.right : parent.right
                            text: remain
                            visible: type != "Ödeme"
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 24
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width/6
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        transactionListView.currentIndex = index
                        container.forceActiveFocus()
                        clickBasicSound.play()
                    }

                    Keys.onPressed: {
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            doubleClicked();
                        }
                    }

                    onDoubleClicked: {
                        if (transactionListView.currentIndex != index) {
                            transactionListView.currentIndex = index;
                            container.forceActiveFocus();
                            clickBasicSound.play();
                        }

                        if ("Ödeme" !== transactionListViewModel.get(transactionListView.currentIndex).type)
                            receiptPopup.getReceipt("sales", transactionListViewModel.get(transactionListView.currentIndex).id);
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color:"#CCD1D9"; height: 50; width: container.width - 15; anchors.leftMargin: 10; anchors.rightMargin: 15 }
                    PropertyChanges { target: transactionTime; font.pixelSize: 20; }
                    PropertyChanges { target: transactionType; font.pixelSize: 24; }
                    PropertyChanges { target: transactionCost; font.pixelSize: 24; }
                    PropertyChanges { target: transactionPayment; font.pixelSize: 24; }
                    PropertyChanges { target: transactionRemain; font.pixelSize: 24; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
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
            color: transactionListView.activeFocus?"dodgerblue":"slategray"
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: printButton.right
        anchors.margins: 4
        width: parent.width - 316
        height: 50

        Label {
            id: itemNum
            text: "Kalan Tutar:"
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 3
            horizontalAlignment: "AlignHCenter"
            font.family: "Arial"
            font.pixelSize: 12
            color: "indianred"
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
            color: "crimson"
        }
    }
    Button {
        id:printButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.leftMargin: 4
        text: "Özet Yazdır"
        height: 50
        width: 150
        font.pixelSize: 24
    }

    Button {
        id:paymentButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        text: "Ödeme Yap"
        height: 50
        width: 150
        font.pixelSize: 24
        borderColor: "salmon"
        Keys.onPressed: {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                clicked();
            }
        }
        onClicked: {
            doPaymentPopup.visible = true;
        }
    }
}
