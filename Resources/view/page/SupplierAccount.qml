import QtQuick 2.7
import QtQuick.Controls 2.0
import QtMultimedia 5.9
import posapp.restrequest 1.0

import "../../fonts"
import "../controls"
import "../popups"

Page {
    id: accountPage
    width:  800 //parent
    height:  430 //parent

    title: qsTr("Alımlar")

    property int person_id
    property string name
    property string phone
    property string address
    property int busyIndicatorCnt: 0

    RestRequest {
        id:accountRequest

        onSessionTimeout: {
            accountPage.parent.pop();
        }

        onRequestTimeout: {
            accountPage.parent.pop();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    ToastManager{
        id: toast
    }

    Component.onCompleted: {
        phoneAndAddress.text = "Tel: "+ phone + "\nAdres: " + address;
        selectLastTransactionsByDate.currentIndex = 4
    }

    ReceiptPopup {
        id: receiptPopup
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

        accountRequest.get("receivings/get_transactions/" + person_id, searchObj, function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        transactionListViewModel.clear();

        for (var cnt = 0; cnt < data.length; ++cnt) {
            var receiving = data[cnt];
            var total = parseFloat(receiving.total.replace(/[₺|.]/g, '').replace(',', '.'));
            transactionListViewModel.append({id: receiving.receiving_id, date: receiving.receiving_time, type: (total < 0 ? "İade": "Alım"), cost: total.toFixed(2)+ "₺", payment: receiving.payment_type});
        }
    }

    SoundEffect {
        id: clickBasicSound
        source: "../../sounds/click.wav"
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
            text: name
            anchors.topMargin: 0
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
        width: parent.width
        anchors.topMargin: 4
        anchors.top: accountTitle.bottom
        anchors.bottom: parent.bottom
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
                            color: type == "Alım" ? "#545454": "crimson"
                            font.pixelSize: 16
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: parent.left
                            width: parent.width/2.5
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
                            color: type == "Alım" ? "#545454": "crimson"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width/5
                            anchors.left: transactionTime.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                        ListViewColumnLabel{
                            text: "Ödeme Şekli"
                            labelOf: transactionPayment
                        }
                        Text {
                            id: transactionPayment
                            anchors.rightMargin: 4
                            anchors.left : transactionType.right
                            text: payment
                            color: type == "Alım" ? "#545454": "crimson"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width/5
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
                            anchors.right : parent.right
                            text: cost
                            color: type == "Alım" ? "#545454": "crimson"
                            font.pixelSize: 20
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width/5
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

                        receiptPopup.getReceipt("receivings", transactionListViewModel.get(transactionListView.currentIndex).id);
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color:"#CCD1D9"; height: 50; width: container.width - 15; anchors.leftMargin: 10; anchors.rightMargin: 15 }
                    PropertyChanges { target: transactionTime; font.pixelSize: 20; }
                    PropertyChanges { target: transactionType; font.pixelSize: 22; }
                    PropertyChanges { target: transactionPayment; font.pixelSize: 22; }
                    PropertyChanges { target: transactionCost; font.pixelSize: 24; font.family: Fonts.fontIBMPlexMonoSemiBold.name  }
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
