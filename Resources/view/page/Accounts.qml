import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import posapp.restrequest 1.0

import "../../fonts"
import "../controls"

Page {
    id: accountsPage
    width:  800 //parent
    height:  440 //parent

    title: qsTr("Hesaplar")

    property int selectedPersonId: -2
    property int busyIndicatorCnt: 0

    ToastManager{
        id: toast
    }

    RestRequest {
        id:accountsRequest

        onSessionTimeout: {
            accountsPage.parent.pop();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    function savePerson() {
        var person = {
            first_name: nameTextField.text.trim(),
            last_name: surnameTextField.text.trim(),
            company_name: companyTextField.text.trim(),
            phone_number: phoneTextField.text.trim(),
            email: mailTextField.text.trim(),
            address_1: addressTextField.text.trim(),
            comments: commentTextField.text.trim(),
            employee_id: 1
        };

        accountsRequest.post(getAccountTypeDir() + '/save/' + selectedPersonId, person, function(code, jsonStr){
            var response = JSON.parse(jsonStr);
            if (response.success) {
                selectedPersonId = parseInt(response.id);
                getPeople();
                editDelete.visible = false;
                toast.showSuccess(response.message, 3000);
            }
            else
                toast.showError(response.message, 3000);
        });
    }

    function anyDescendantHasActiveFocus(ancestor) {
        let item = appWindow.activeFocusItem;
        while (item) {
            if (item === ancestor)
                return true;
            item = item.parent;
        }
        return false;
    }

    function getPeople() {
        var searchObj = {"search": searchTextField.text, order:"asc", offset: 0, limit: 25};

        accountsRequest.get(getAccountTypeDir() + "/search", searchObj, function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        peopleListViewModel.clear();
        for (var cnt = 0; cnt < data.rows.length; ++cnt) {
            var person = data.rows[cnt];
            var personId = parseInt(person["people.person_id"]);
            peopleListViewModel.append({id: personId, companyName:person.company_name, name: person.first_name, surname: person.last_name, phone: person.phone_number, address: person.address_1});
            if (personId === selectedPersonId) {
                peopleListView.currentIndex = cnt;
                peopleListView.forceActiveFocus();
            }
        }
    }

    function openEditDelete(personId) {
        console.log(personId + ' ' + selectedPersonId);
        if (selectedPersonId === personId && editDelete.visible)
            return;
        selectedPersonId = typeof personId !== 'undefined' ? personId : -1;
        updateEditDeleteFields(selectedPersonId);
        editDelete.visible = true;
    }

    function getAccountTypeDir() {
        return isAccountTypeCustomer() ?"customers":"suppliers";
    }

    function isAccountTypeCustomer() {
        return typeButton.currentIndex == 0;
    }

    function updateEditDeleteFields(personId) {

        accountsRequest.get(getAccountTypeDir() + "/view/"+personId+"/json", function(code, jsonStr){updateEditDeleteFieldsResponse(JSON.parse(jsonStr))});
    }

    function updateEditDeleteFieldsResponse(data) {
        clearRequiredFieldsValidation();
        companyTextField.text = data.person_info.company_name;
        nameTextField.text = data.person_info.first_name;
        surnameTextField.text = data.person_info.last_name;
        phoneTextField.text = data.person_info.phone_number;
        mailTextField.text = data.person_info.email;
        addressTextField.text = data.person_info.address_1;
        commentTextField.text = data.person_info.comments;
    }

    function clearRequiredFieldsValidation() {
        companyTextField.needValidate = false;
        nameTextField.needValidate = false;
        surnameTextField.needValidate = false;
    }

    function deletePerson() {
        accountsRequest.post(getAccountTypeDir() + '/delete', {ids:[selectedPersonId]}, function(code, jsonStr){
            var response = JSON.parse(jsonStr);
            if (response.success) {
                selectedPersonId = -2;
                peopleListView.currentIndex = -2;
                getPeople();
                toast.showSuccess(response.message, 3000);
            }
            else
                toast.showError(response.message, 3000);
        });
    }

    ComboBox {
        id: typeButton
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.leftMargin: 4
        model:ListModel{
            ListElement{name:"Müşteri"}
            ListElement{name:"Satıcı"}
        }
        placeholderText: "Hesap Türü"
        height: 50
        font.pixelSize: 24
        font.family: Fonts.fontBarlowRegular.name
        width: 150

        onCurrentIndexChanged: {
            editDelete.visible = false;
            selectedPersonId = -2;
            peopleListView.currentIndex = -2;
            getPeople();
        }
    }

    MessageDialog {
        id: deleteDialog
        title: (isAccountTypeCustomer()?"Müşteri":"Satıcı") + " Silme"
        text: "Seçili " + (isAccountTypeCustomer()?"müşteriyi":"satıcıyı") + " silmek istediğinizden emin misiniz?"
        icon: StandardIcon.Question
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: {
            editDelete.visible = false;
            deletePerson();
        }
        onNo: deleteDialog.visible = false
    }

    TextField {
        id: searchTextField
        font.pixelSize: 20
        anchors.left: typeButton.right
        anchors.top: parent.top
        anchors.leftMargin: 4
        anchors.topMargin: 4
        width: parent.width - 316
        height: 50
        font.family: Fonts.fontOrbitronRegular.name
        placeholderText: (isAccountTypeCustomer()?"Müşteri":"Satıcı") + " Ara"
    }

    Button {
        id: newPersonButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.rightMargin: 4
        text: "Yeni " + (isAccountTypeCustomer()?"Müşteri":"Satıcı");
        height: 50
        width: 150
        font.pixelSize: 24
        Keys.onPressed: {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                clicked();
            }
        }

        onClicked: {
            openEditDelete(-1);
        }
    }

    FocusScope {
        id: listMenu
        y: 70
        width: parent.width
        anchors.top: newPersonButton.bottom
        anchors.bottom: editDelete.visible? editDelete.top:parent.bottom
        anchors.topMargin: 4
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 1
            color: peopleListView.activeFocus?"dodgerblue":"lightslategray"
        }

        ListView {
            id: peopleListView
            width: parent.width; height: parent.height
            focus: true
            model: ListModel{
                id: peopleListViewModel
            }
            cacheBuffer: 200
            onActiveFocusChanged: {
                if (!activeFocus && !anyDescendantHasActiveFocus(editDelete))
                    editDelete.visible = false;
            }
            onCurrentIndexChanged: {console.log(currentIndex);
                if (activeFocus)
                    openEditDelete(peopleListViewModel.get(currentIndex).id);
            }
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
                            text: "Kayıt Numarası"
                            labelOf: idText
                        }
                        Text {
                            id: idText
                            text: id
                            color: "#545454"
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width/4
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "Firma"
                            labelOf: companyText
                        }
                        Text {
                            id: companyText
                            text: companyName
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width/4
                            anchors.left: idText.right
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "İsim"
                            labelOf: nameText
                        }
                        Text {
                            id: nameText
                            text: name
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width/4
                            anchors.left: companyText.right
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "Soyisim"
                            labelOf: surnameText
                        }
                        Text {
                            id: surnameText
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            anchors.left : nameText.right
                            text: surname
                            color: "#545454"
                            font.pixelSize: 24
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width / 4
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        console.log(peopleListView.currentIndex +" " +index);
                        if (peopleListView.currentIndex == index && !editDelete.visible)
                            openEditDelete(peopleListViewModel.get(index).id);
                        peopleListView.currentIndex = index;
                        container.forceActiveFocus();
                        editDelete.visible = true;
                        listMenu.height = 160
                    }
                    onDoubleClicked: {
                        if (peopleListView.currentIndex !== index)
                            peopleListView.currentIndex = index;
                        accountsPage.parent.push('Account.qml',
                                                 {
                                                     cust_id:  peopleListViewModel.get(index).id,
                                                     phone: peopleListViewModel.get(index).phone,
                                                     address:  peopleListViewModel.get(index).address
                                                 })
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color:"#CCD1D9"; width: container.width - 15; height:50; anchors.leftMargin: 10; anchors.rightMargin: 15;}
                    PropertyChanges { target: idText; font.pixelSize: 24; }
                    PropertyChanges { target: companyText; font.pixelSize: 24; }
                    PropertyChanges { target: nameText; font.pixelSize: 24; }
                    PropertyChanges { target: surnameText; font.pixelSize: 24; }
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
            color: peopleListView.activeFocus?"dodgerblue":"lightslategray"
        }
    }

    Rectangle {
        id: editDelete
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width
        height: 190
        visible: false
        color: "#f7f8f9"

        TextField {
            id: companyTextField
            required: !isAccountTypeCustomer()
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.665
            placeholderText: "Firma"
        }

        TextField {
            id: nameTextField
            required: true
            anchors.left: companyTextField.right
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.665
            placeholderText: "Adı"
        }

        TextField {
            id: surnameTextField
            required: true
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.665
            placeholderText: "Soyadı"
        }

        TextField {
            id: phoneTextField
            anchors.left: parent.left
            anchors.top: nameTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.665
            placeholderText: "Telefon"
        }

        TextField {
            id: mailTextField
            anchors.left: phoneTextField.right
            anchors.top: surnameTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.665
            placeholderText: "E-Posta"
        }

        TextField {
            id: addressTextField
            anchors.right: parent.right
            anchors.top: companyTextField.bottom
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.665
            placeholderText: "Adres"
            maximumLength: 64
        }

        TextField {
            id: commentTextField
            anchors.left: parent.left
            anchors.top: mailTextField.bottom
            anchors.rightMargin: 4
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width
            placeholderText: "Yorum"
            maximumLength: 128
        }

        Button {
            id: deleteButton
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            anchors.leftMargin: 4
            text: "Sil"
            borderColor: "indianred"
            height: 50
            width: 150
            font.pixelSize: 24
            onClicked: {
                deleteDialog.visible=true;
            }
        }

        Button {
            id: saveButton
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            anchors.rightMargin: 4
            text: "Kaydet"
            height: 50
            width: 150
            font.pixelSize: 24
            onClicked: {
                if (!isAccountTypeCustomer())
                    companyTextField.needValidate = true;
                nameTextField.needValidate = true;
                surnameTextField.needValidate = true;

                if(nameTextField.isInvalid() || surnameTextField.isInvalid() || (!isAccountTypeCustomer() && companyTextField.isInvalid()))
                    toast.showError("Kırmızı Alanlar Boş Bırakılamaz!", 3000);
                else
                    savePerson();
            }
            borderColor: "mediumseagreen"
        }
    }
}
