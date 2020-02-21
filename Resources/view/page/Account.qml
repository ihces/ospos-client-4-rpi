import QtQuick 2.7
import QtQuick.Controls 2.0
import QtMultimedia 5.9
import posapp.restrequest 1.0

import "../../fonts"

Page {
    id: paymentPage
    width:  800 //parent
    height:  440 //parent

    title: qsTr("Alacak Hesabı")

    property int cust_id

    RestRequest {
        id:accountRequest

        onSessionTimeout: {
            accountsPage.parent.pop();
        }
    }

    Component.onCompleted: {
        getTransactions();
    }

    function getTransactions() {
        var searchObj = {start_date: new Date(2010, 1, 1).toISOString(), end_date: new Date().toISOString()};

        accountRequest.get("sales/get_transactions/" + cust_id, searchObj, function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        transactionListViewModel.clear();
        if (data.length > 0)
            accountName.text = data[0].customer_name;
        var totalDue = 0.0;
        for (var cnt = 0; cnt < data.length; ++cnt) {
            var sale = data[cnt];

            var saleTypeStr="Satış";
            if (sale.sale_type === "4")
                saleTypeStr = "İade";

            var amountDue = parseFloat(sale.amount_due.replace(/[₺|.]/g, '').replace(',', '.'));

            var payments = sale.payment_type.split(',');
            var remainAmount = 0.0;
            for (var cnt1 =0; cnt1 < payments.length; ++ cnt1)
                if (payments[cnt1].startsWith("Due")) {
                    remainAmount = parseFloat(payments[cnt1].split(' ')[1]);
                    break;
                }
            totalDue += remainAmount;
            transactionListViewModel.append({id: sale["sale_id"], date: sale.sale_time, type: saleTypeStr, cost: amountDue.toFixed(2)+ "₺", payment: (amountDue-remainAmount).toFixed(2) + "₺", remain: remainAmount.toFixed(2)+ "₺"});
        }

        totalCost.text = totalDue.toFixed(2) + "₺";
    }

    SoundEffect {
        id: clickBasicSound
        source: "../../sounds/220197-click-basic.wav"
    }

    Rectangle {
        id: accountTitleLeft
        width: 170
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 0
        antialiasing: true;
        color: "#d6e6f6"
        height: 50
        Text {
            id: accountStartDate
            y: 3
            text: "İlk İşlem: 01/01/2018\nSon İşlem: 12/01/2018"
            color: "#545454"
            font.pixelSize: 14
            font.family: Fonts.fontRubikRegular.name
            anchors.left: parent.left
            width: parent.width
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            anchors.top: parent.top
            anchors.topMargin: 3
            leftPadding: 7
        }
    }

    Rectangle {
        id: accountTitleRight
        width: 170
        anchors.right: parent.right
        anchors.top: parent.top
        antialiasing: true;
        color: "#d6e6f6"
        height: 50
        Text {
            id: accountStartAddress
            text: "T 0531 456 7854\nSaltuklu Mah. Erva Sok. No: 1 Aziziye/Erzurum"
            wrapMode: Text.WordWrap
            color: "#545454"
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
        width: parent.width - 340
        anchors.left: accountTitleLeft.right
        anchors.top: parent.top
        antialiasing: true;
        color: "#d6e6f6"
        height: 50
        Text {
            id: accountNum
            text: cust_id
            color: "#545454"
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
            text: "İbrahim Hakkı ÇEŞME"
            anchors.topMargin: -6
            color: "#545454"
            font.pixelSize: 32
            font.family: Fonts.fontTomorrowRegular.name
            anchors.left: parent.left
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            anchors.top: accountNum.bottom
        }
    }

    FocusScope {
        id: transactionList
        y: 50
        width: parent.width
        height: parent.height - 110
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 2
            color: transactionListView.activeFocus?"dodgerblue":"slategray"
        }

        ListView {
            id: transactionListView
            width: parent.width; height: parent.height
            focus: true
            KeyNavigation.down: paymentButton
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
                    antialiasing: true
                    radius: 4

                    Rectangle {
                        anchors.fill: parent;
                        anchors.margins: 3;
                        antialiasing: true;
                        color: "transparent"
                        Text {
                            id: label1
                            text: date
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 16
                            font.family: Fonts.fontRubikRegular.name
                            anchors.left: parent.left
                            width: parent.width/3
                            horizontalAlignment: Text.AlignHCenter
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }
                        Text {
                            id: label2
                            text: type
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width/6
                            anchors.left: label1.right
                            anchors.leftMargin: 20
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }
                        Text {
                            id: label3
                            horizontalAlignment: Text.AlignRight
                            anchors.rightMargin: 4
                            anchors.right : label4.left
                            text: cost
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 20
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width/6
                            anchors.top: parent.top
                            anchors.topMargin: 4
                        }

                        Text {
                            id: label4
                            horizontalAlignment: Text.AlignRight
                            anchors.rightMargin: 4
                            anchors.right : label5.left
                            text: payment
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 20
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width/6
                            anchors.top: parent.top
                            anchors.topMargin: 4
                        }

                        Text {
                            id: label5
                            horizontalAlignment: Text.AlignRight
                            anchors.rightMargin: 4
                            anchors.right : parent.right
                            text: remain
                            color: type == "Satış" ? "#545454": "crimson"
                            font.pixelSize: 24
                            font.family: Fonts.fontIBMPlexMonoRegular.name
                            width: parent.width/6
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
                        clickBasicSound.play()
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color: "dodgerblue"; height: 50; width: container.width - 10; anchors.leftMargin: 10; anchors.rightMargin: 10 }
                    PropertyChanges { target: label1; font.pixelSize: 20; font.bold: true; color: "white" }
                    PropertyChanges { target: label2; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label3; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label4; font.pixelSize: 24; font.bold: true; color: "white" }
                    PropertyChanges { target: label5; font.pixelSize: 28; color: "white"; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
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
            color: transactionListView.activeFocus?"dodgerblue":"slategray"
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: printButton.right
        width: parent.width - 316
        height: 50

        Label {
            id: itemNum
            text: "Kalan Tutar:"
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: -11
            horizontalAlignment: "AlignHCenter"
            font.family: "Arial"
            font.pointSize: 12
            color: "crimson"
        }
        Label {
            id: totalCost
            anchors.top: itemNum.bottom
            anchors.topMargin: -14
            horizontalAlignment: "AlignHCenter"
            width: parent.width
            text: "0,00₺"
            font.family: Fonts.fontIBMPlexMonoRegular.name
            font.pointSize: 32
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
        spacing: 5
        autoExclusive: false
        height: 50
        width: 160
        padding: 10
        checkable: true
        font.family: Fonts.fontBarlowRegular.name
        font.pointSize: 20
        background: Rectangle{
            anchors.fill:parent
            color: parent.checked?"steelblue": (parent.activeFocus?"dodgerblue":"slategray")
        }
    }

    Button {
        id:paymentButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.rightMargin: 4
        text: "Ödeme Yap"
        spacing: 5
        autoExclusive: false
        height: 50
        width: 160
        padding: 10
        checkable: true
        font.family: Fonts.fontBarlowRegular.name
        font.pointSize: 24
        Keys.onPressed: {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                checked = true
                console.log("odeme enter")
                paymentPage.parent.pop()
            }
        }

        background: Rectangle{
            anchors.fill:parent
            color: parent.checked?"steelblue": (parent.activeFocus?"crimson":"indianred")
        }

        Keys.onReleased: {
            checked = false
        }
    }
}
