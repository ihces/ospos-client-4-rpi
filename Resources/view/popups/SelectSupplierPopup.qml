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
    property int selectedSupplierId
    property string closeReason
    property int busyIndicatorCnt: 0
    SoundEffect {
        id: popupSound
        source: "../../sounds/popup.wav"
    }
    RestRequest {
        id:selectSupplierRequest

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
        getSupplierList();
    }

    function getSupplierList() {
        supplierNameTextField.supplierNameTextCleared = true;
        supplierNameTextField.text = supplierNameTextField.text.trim();
        selectSupplierRequest.get("suppliers/search?search="+encodeURIComponent(supplierNameTextField.text)+
                         "&order=asc&offset=0&limit=25", function(code, jsonStr){
                             var supplierList = JSON.parse(jsonStr)["rows"];
                             supplierListViewModel.clear();
                             for (var cnt=0; cnt < supplierList.length; ++cnt){
                                 var suspended = supplierList[cnt];
                                 supplierListViewModel.append({
                                                                  num: supplierList[cnt]["people.person_id"],
                                                                  company:supplierList[cnt]["company_name"],
                                                                  name: supplierList[cnt]["first_name"],
                                                                  surname: supplierList[cnt]["last_name"]
                                                              });
                                 if (selectedSupplierId === parseInt(supplierList[cnt]["people.person_id"])){
                                     selectSupplierListView.currentIndex = cnt;
                                 }
                             }
                         });
    }

    Rectangle{
        id: selectSupplierTitle
        width: parent.width
        height: 40
        Text {
            text: "Tedarikçi Seç"
            color: "slategray"
            font.pixelSize: 24
            font.family: Fonts.fontRubikRegular.name
            anchors.left: parent.left
            width: parent.width/2
            anchors.verticalCenter: parent.verticalCenter
        }
        TextField {
            id: supplierNameTextField
            font.pixelSize: 20
            activeFocusOnTab: true
            focus: true
            anchors.right: parent.right
            anchors.top: parent.top
            width: parent.width / 2
            height: parent.height
            font.family: Fonts.fontOrbitronRegular.name
            placeholderText: "İsim veya Soyisim"
            property bool supplierNameTextCleared: false
            onTextChanged: {
                if (supplierNameTextCleared)
                    supplierNameTextCleared = false;
                else {
                    getSupplierList();
                }
            }
        }
    }
    FocusScope {
        id: selectSupplierList
        anchors.left: parent.Left
        width: parent.width
        anchors.top: selectSupplierTitle.bottom
        anchors.topMargin: 4
        height: parent.height - selectSupplierTitle.height - 4
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
            id: selectSupplierListView
            width: parent.width; height: parent.height
            focus: true
            model: ListModel{
                id: supplierListViewModel
            }
            cacheBuffer: 200
            delegate: Item {
                id: container
                width: selectSupplierListView.width; height: 35; anchors.leftMargin: 4; anchors.rightMargin: 4
                Rectangle {
                    id: selectSupplierItemContent
                    anchors.centerIn: parent; width: container.width - 20; height: container.height
                    antialiasing: true
                    color: "transparent"
                    ListViewColumnLabel{
                        text: "Kayıt Numarası"
                        labelOf: selectSupplierItemNum
                    }
                    Text {
                        id: selectSupplierItemNum
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
                        labelOf: selectSupplierItemName
                    }
                    Text {
                        id: selectSupplierItemName
                        text: name
                        color: "#545454"
                        font.pixelSize: 16
                        font.family: Fonts.fontPlayRegular.name
                        anchors.left: selectSupplierItemNum.right
                        horizontalAlignment: Text.AlignLeft
                        width: (parent.width - 120)/7 * 3
                        verticalAlignment: Text.AlignVCenter
                        height: parent.height
                    }
                    ListViewColumnLabel{
                        text: "Soyadı"
                        labelOf: selectSupplierItemSurname
                    }
                    Text {
                        id: selectSupplierItemSurname
                        text: surname
                        color: "#545454"
                        font.pixelSize: 16
                        font.family: Fonts.fontPlayRegular.name
                        anchors.left: selectSupplierItemName.right
                        horizontalAlignment: Text.AlignLeft
                        width: (parent.width - 120)/7 * 2
                        verticalAlignment: Text.AlignVCenter
                        height: parent.height
                    }
                    ListViewColumnLabel{
                        text: "Firma"
                        labelOf: selectSupplierCompany
                    }
                    Text {
                        id: selectSupplierCompany
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
                        selectSupplierListView.currentIndex = index
                    }

                    onDoubleClicked: {
                        selectSupplierListView.currentIndex = index;
                        container.forceActiveFocus();
                        closeReason = supplierListViewModel.get(index).num;
                        control.close();
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: container; height: 45}
                    PropertyChanges { target: selectSupplierItemContent; color: "#CCD1D9"; height: 45; width: container.width - 15; anchors.leftMargin: 10; anchors.rightMargin: 15}
                    PropertyChanges { target: selectSupplierItemNum; font.pixelSize: 20;}
                    PropertyChanges { target: selectSupplierCompany; font.pixelSize: 20;}
                    PropertyChanges { target: selectSupplierItemName; font.pixelSize: 20; }
                    PropertyChanges { target: selectSupplierItemSurname; font.pixelSize: 20; }
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
