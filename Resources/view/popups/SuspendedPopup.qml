import QtQuick 2.7
import QtQuick.Controls 2.0
import posapp.restrequest 1.0
import QtMultimedia 5.9
import "../../fonts"
import "../controls"

Popup{
    id: control
    width: parent.width * 0.75
    height: parent.height * 0.75
    x: parent.width * 0.125
    y: parent.height * 0.125
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    property string closeReason
    property int busyIndicatorCnt: 0
    SoundEffect {
        id: popupSound
        source: "../../sounds/popup.wav"
    }
    RestRequest {
        id:suspendedRequest

        onSessionTimeout: {
            closeReason = "session_timeout";
            close();
        }

        onRequestTimeout: {
            closeReason = "session_timeout";
            close();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    onOpened: {
        popupSound.play();
        closeReason = "ordinary";
        getSuspendedList();
    }

    function getSuspendedList() {
        suspendedRequest.get("sales/suspended/json", function(code, jsonStr){
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
    }

    Rectangle{
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        Text {
            id: suspendTitle
            text: "Bekleyen İşlemler"
            color: "slategray"
            font.pixelSize: 24
            font.family: Fonts.fontRubikRegular.name
            anchors.top: parent.top
            width: parent.width
            horizontalAlignment: "AlignHCenter"
        }
        FocusScope {
            id: suspendList
            anchors.left: parent.Left
            width: parent.width
            anchors.top: suspendTitle.bottom
            anchors.topMargin: 4
            height: parent.height - suspendTitle.height -4
            activeFocusOnTab: true
            clip: true
            Rectangle {
                width: parent.width
                height: parent.height
                color: "transparent"
                border.color: "slategray"
                border.width: 1
            }
            ListView {
                id: suspendedListView
                width: parent.width; height: parent.height
                focus: true
                model: ListModel{
                    id: suspendedListViewModel
                }
                cacheBuffer: 200
                delegate: Item {
                    id: container
                    width: suspendedListView.width; height: 35; anchors.leftMargin: 4; anchors.rightMargin: 4
                    Rectangle {
                        id: suspendedItemContent
                        anchors.centerIn: parent; width: container.width - 20; height: container.heightL
                        antialiasing: true
                        color: "transparent"
                        ListViewColumnLabel{
                            text: "İşlem Numarası"
                            labelOf: suspendedItemId
                        }
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
                            horizontalAlignment: Text.AlignLeft
                        }
                        ListViewColumnLabel{
                            text: "İşlem Tarihi"
                            labelOf: suspendedItemDate
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
                            horizontalAlignment: Text.AlignHCenter
                        }
                        ListViewColumnLabel{
                            text: "Müşteri"
                            labelOf: suspendedItemCustomer
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

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            container.forceActiveFocus()
                            suspendedListView.currentIndex = index
                        }

                        onDoubleClicked: {
                            suspendedListView.currentIndex = index;
                            container.forceActiveFocus();
                            closeReason = suspendedListViewModel.get(index).sale_id;
                            control.close();
                        }
                    }

                    states: State {
                        name: "active"; when: container.activeFocus
                        PropertyChanges { target: container; height: 45}
                        PropertyChanges { target: suspendedItemContent; color: "#CCD1D9"; height: 45; width: container.width - 15; anchors.leftMargin: 10; anchors.rightMargin: 15}
                        PropertyChanges { target: suspendedItemId; font.pixelSize: 20;}
                        PropertyChanges { target: suspendedItemDate; font.pixelSize: 20;}
                        PropertyChanges { target: suspendedItemCustomer; font.pixelSize: 20;}
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
}
