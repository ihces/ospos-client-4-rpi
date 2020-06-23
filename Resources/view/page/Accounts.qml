import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import posapp.restrequest 1.0

import "../../fonts"
import "../controls"
import "../popups"
import "../helpers/helper.js" as Helper

Page {
    id: accountsPage
    width:  800 //parent
    height:  430 //parent

    title: qsTr("Hesaplar")

    property int selectedPersonId: -2
    property int busyIndicatorCnt: 0

    property var person_info

    ToastManager{
        id: toast
    }

    RestRequest {
        id:accountsRequest

        onSessionTimeout: {
            accountsPage.parent.pop();
        }

        onRequestTimeout: {
            accountsPage.parent.pop();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    function savePerson() {
        person_info.first_name = nameTextField.text.trim();
        person_info.last_name= surnameTextField.text.trim();
        person_info.company_name= companyTextField.text.trim();
        person_info.phone_number= phoneTextField.text.trim();
        person_info.email= mailTextField.text.trim();
        person_info.address_1= addressTextField.text.trim();
        person_info.comments= commentTextField.text.trim();

        //if (getAccountTypeDir() === "suppliers")
        //    person_info.acency_name = "";
        accountsRequest.post(getAccountTypeDir() + '/save/' + selectedPersonId, person_info, function(code, jsonStr){
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

        searchTextField.forceActiveFocus();
    }

    function openEditDelete(personId) {
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
        if (isAccountTypeCustomer())
            data.person_info.date = data.person_info.date.replace('\/', '/');
        person_info = data.person_info;
    }

    function clearRequiredFieldsValidation() {
        companyTextField.needValidate = false;
        nameTextField.needValidate = false;
        surnameTextField.needValidate = false;
        phoneTextField.needValidate = false;
        mailTextField.needValidate = false;
    }

    function deletePersonConfirmation() {
        dialogPopup.confirmation((isAccountTypeCustomer()?"Müşteri":"Tedarikçi") + " Silme", "Seçili " + (isAccountTypeCustomer()?"müşteriyi":"satıcıyı") + " silmek istediğinizden emin misiniz?", function(){
            editDelete.visible = false;
            deletePerson();
        });
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
            ListElement{name:"Tedarikçi"}
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

    DialogPopup {
        id: dialogPopup
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
        placeholderText: (isAccountTypeCustomer()?"Müşteri":"Tedarikçi") + " Ara"
        onTextChanged: {
            getPeople();
        }
    }

    Button {
        id: newPersonButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.rightMargin: 4
        text: "Yeni " + (isAccountTypeCustomer()?"Müşteri":"Tedarikçi");
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
                if (!activeFocus && !Helper.anyDescendantHasActiveFocus(editDelete))
                    editDelete.visible = false;
            }
            onCurrentIndexChanged: {
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
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: Fonts.fontRubikRegular.name
                            width: 150
                            anchors.left: parent.left
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
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: (parent.width - 150)/7 * 3
                            anchors.left: idText.right
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
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: (parent.width - 150)/7 * 2
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
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: (parent.width - 150)/7 * 2
                            anchors.right: parent.right
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        if (peopleListView.currentIndex == index && !editDelete.visible)
                            openEditDelete(peopleListViewModel.get(index).id);
                        container.forceActiveFocus();
                        peopleListView.currentIndex = index;
                        listMenu.height = 160
                    }
                    onDoubleClicked: {
                        if (peopleListView.currentIndex !== index)
                            peopleListView.currentIndex = index;
                        accountsPage.parent.push(isAccountTypeCustomer()?'Account.qml': 'SupplierAccount.qml',
                                                 {
                                                     person_id:  peopleListViewModel.get(index).id,
                                                     name:  isAccountTypeCustomer()?(peopleListViewModel.get(index).name + " " +
                                                            peopleListViewModel.get(index).surname):
                                                            peopleListViewModel.get(index).companyName,
                                                     phone: peopleListViewModel.get(index).phone,
                                                     address:  peopleListViewModel.get(index).address
                                                 })
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color:"#CCD1D9"; width: container.width - 15; height:50; anchors.leftMargin: 10; anchors.rightMargin: 15;}
                    PropertyChanges { target: idText; font.pixelSize: 22; }
                    PropertyChanges { target: companyText; font.pixelSize: 22; }
                    PropertyChanges { target: nameText; font.pixelSize: 22; }
                    PropertyChanges { target: surnameText; font.pixelSize: 22; }
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
            maximumLength: 32
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
            maximumLength: 32
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
            maximumLength: 32
        }

        TextField {
            id: phoneTextField
            anchors.left: parent.left
            anchors.top: nameTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.665
            placeholderText: "Telefon"
            maximumLength: 32
            validator: RegExpValidator{
                regExp: /\(?([0-9]{3})\)?([ .-]?)([0-9]{3})\2([0-9]{4})/
            }
        }

        TextField {
            id: mailTextField
            anchors.left: phoneTextField.right
            anchors.top: surnameTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.665
            placeholderText: "E-Posta"
            maximumLength: 64
            validator: RegExpValidator{
                regExp: /^\S+@\S+\.\S+$/
            }
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
                if (getAccountTypeDir() === "customers") {
                    accountsRequest.get("customers/get_total_due/" +selectedPersonId,
                                   function(code, jsonStr) {
                                       var due = parseFloat(JSON.parse(jsonStr));
                                       if (due < -0.0001 || due > 0.0001)
                                           toast.showError("Müşteri hesabı aktif olduğunda silme işlemi yapılamıyor.", 3000);
                                       else
                                           deletePersonConfirmation();
                                   });
                }
                else
                    deletePersonConfirmation();
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
                phoneTextField.needValidate = true;
                mailTextField.needValidate = true;

                if(nameTextField.isInvalid() || surnameTextField.isInvalid() ||
                        (!isAccountTypeCustomer() && companyTextField.isInvalid()) ||
                        phoneTextField.isInvalid() || mailTextField.isInvalid())
                    toast.showError("Kırmızı Alanlar Hatalı!", 3000);
                else
                    savePerson();
            }
            borderColor: "mediumseagreen"
        }
    }
}
