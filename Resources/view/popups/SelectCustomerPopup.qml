import QtQuick 2.7
import QtQuick.Controls 2.0
import QtMultimedia 5.9
import posapp.restrequest 1.0
import "../../fonts"
import "../controls"

Popup{
    id: control
    width: parent.width * 0.75
    height: parent.height * 0.75
    x: parent.width * 0.125
    y: parent.height * 0.125
    z: 200
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    property int selectedCustomerId
    property string closeReason
    property int busyIndicatorCnt: 0
    SoundEffect {
        id: popupSound
        source: "../../sounds/popup.wav"
    }
    RestRequest {
        id:salesRequest

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
        getCustomerList();
    }

    function getCustomerList() {
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
                                                                  name: customerList[cnt]["first_name"],
                                                                  surname: customerList[cnt]["last_name"],
                                                                  company:customerList[cnt]["company_name"]
                                                              });
                                 if (selectedCustomerId === parseInt(customerList[cnt]["people.person_id"])){
                                     selectCustomerListView.currentIndex = cnt;
                                 }
                             }
                         });
    }

    Rectangle{
        id: selectCustomerTitle
        width: parent.width
        height: 40
        Text {
            text: "Müşteri Seç"
            color: "slategray"
            font.pixelSize: 24
            font.family: Fonts.fontRubikRegular.name
            anchors.left: parent.left
            width: parent.width/2
            anchors.verticalCenter: parent.verticalCenter
        }
        TextField {
            id: customerNameTextField
            font.pixelSize: 20
            activeFocusOnTab: true
            focus: true
            anchors.right: parent.right
            anchors.top: parent.top
            width: parent.width / 2
            height: parent.height
            font.family: Fonts.fontOrbitronRegular.name
            placeholderText: "İsim veya Soyisim"
            property bool customerNameTextCleared: false
            onTextChanged: {
                if (customerNameTextCleared)
                    customerNameTextCleared = false;
                else {
                    getCustomerList();
                }
            }
        }
    }
    FocusScope {
        id: selectCustomerList
        anchors.left: parent.Left
        width: parent.width
        anchors.top: selectCustomerTitle.bottom
        anchors.topMargin: 4
        height: parent.height - selectCustomerTitle.height - 4
        activeFocusOnTab: true
        z: 1000
        clip: true
        Rectangle {
            width: parent.width
            height: parent.height
            color: "transparent"
            border.color: "slategray"
            border.width: 1
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
                id: container
                width: selectCustomerListView.width; height: 35; anchors.leftMargin: 4; anchors.rightMargin: 4
                Rectangle {
                    id: selectCustomerItemContent
                    anchors.centerIn: parent; width: container.width - 20; height: container.height
                    antialiasing: true
                    color: "transparent"
                    ListViewColumnLabel{
                        text: "Kayıt Numarası"
                        labelOf: selectCustomerItemNum
                    }
                    Text {
                        id: selectCustomerItemNum
                        text: num
                        color: "#545454"
                        font.pixelSize: 16
                        font.family: Fonts.fontRubikRegular.name
                        width: 120
                        anchors.left: parent.left
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        height: parent.height
                    }
                    ListViewColumnLabel{
                        text: "Adı"
                        labelOf: selectCustomerItemName
                    }
                    Text {
                        id: selectCustomerItemName
                        text: name
                        color: "#545454"
                        font.pixelSize: 16
                        font.family: Fonts.fontPlayRegular.name
                        anchors.left: selectCustomerItemNum.right
                        horizontalAlignment: Text.AlignLeft
                        width: (parent.width - 120)/7 * 3
                        verticalAlignment: Text.AlignVCenter
                        height: parent.height
                    }
                    ListViewColumnLabel{
                        text: "Soyadı"
                        labelOf: selectCustomerItemSurname
                    }
                    Text {
                        id: selectCustomerItemSurname
                        text: surname
                        color: "#545454"
                        font.pixelSize: 16
                        font.family: Fonts.fontPlayRegular.name
                        anchors.left: selectCustomerItemName.right
                        horizontalAlignment: Text.AlignLeft
                        width: (parent.width - 120)/7 * 2
                        verticalAlignment: Text.AlignVCenter
                        height: parent.height
                    }
                    ListViewColumnLabel{
                        text: "Firma"
                        labelOf: selectCustomerCompany
                    }
                    Text {
                        id: selectCustomerCompany
                        text: company
                        color: "#545454"
                        font.pixelSize: 16
                        font.family: Fonts.fontPlayRegular.name
                        anchors.right: parent.right
                        width: (parent.width - 120)/7 * 2
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        height: parent.height
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        container.forceActiveFocus()
                        selectCustomerListView.currentIndex = index
                    }

                    onDoubleClicked: {
                        selectCustomerListView.currentIndex = index;
                        container.forceActiveFocus();
                        closeReason = customerListViewModel.get(index).num;
                        control.close();
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: container; height: 45}
                    PropertyChanges { target: selectCustomerItemContent; color: "#CCD1D9"; height: 45; width: container.width - 15; anchors.leftMargin: 10; anchors.rightMargin: 15}
                    PropertyChanges { target: selectCustomerItemNum; font.pixelSize: 20;}
                    PropertyChanges { target: selectCustomerItemName; font.pixelSize: 20;}
                    PropertyChanges { target: selectCustomerItemSurname; font.pixelSize: 20;}
                    PropertyChanges { target: selectCustomerCompany; font.pixelSize: 20;}
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
