import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import posapp.restrequest 1.0
import "../../fonts"
import "../controls"

Page {
    id: itemsPage
    width:  800
    height:  440
    font.family: "Courier"

    title: qsTr("Ürünler")

    property bool categoryListUpdating: false
    property int busyIndicatorCnt: 0
    property int selectedItemId: -1;
    property variant stockIds: []
    RestRequest {
        id:itemsRequest

        onSessionTimeout: {
            itemsPage.parent.pop();
        }

        onStart: {busyIndicatorCnt++; busyIndicator.running = true}
        onEnd: {if (--busyIndicatorCnt == 0)busyIndicator.running = false}
    }

    ToastManager {
        id: toast
    }

    MessageDialog {
        id: deleteDialog
        title: "Ürün Silme"
        text: "Seçili ürünü silmek istediğinizden emin misiniz?"
        icon: StandardIcon.Question
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: {
            editDelete.visible = false;
            deleteItem();
        }
        onNo: deleteDialog.visible = false
    }

    function getItems() {
        var searchObj = {"search": searchTextField.text, order:"asc", limit: 25, start_date: new Date(2010, 1, 1).toISOString(), end_date: new Date().toISOString(), filters: []};
        saveButton.text = "Kaydet";
        deleteButton.visible = true;
        switch (selectFilter.currentIndex) {
        case 1:
            searchObj["filters"].push("empty_upc");
            break;
        case 2:
            searchObj["filters"].push("low_inventory");
            break;
        case 3:
            searchObj["filters"].push("is_deleted");
            saveButton.text = "Geri Al";
            deleteButton.visible = false;
            break;
        default:
            break;
        }

        itemsRequest.get("items/search", searchObj, function(code, jsonStr){updateData(JSON.parse(jsonStr))});
    }

    function updateData(data) {
        itemListViewModel.clear();
        for (var cnt = 0; cnt < data.rows.length; ++cnt) {
            var item = data.rows[cnt];
            var itemId =parseInt(item["items.item_id"]);
            itemListViewModel.append({id: itemId, num: item.item_number, name: item.name, unitPrice: parseFloat(item.unit_price.replace(/[₺|.]/g, '').replace(',', '.')).toFixed(2) + "₺"});
            if (itemId === selectedItemId) {
                list1.currentIndex = cnt;
                list1.forceActiveFocus();
            }
        }
    }

    function openEditDelete(itemId) {
        if (selectedItemId === itemId)
            return;
        selectedItemId = typeof itemId !== 'undefined' ? itemId : -1;
        updateEditDeleteFields(selectedItemId);
        updateCategoryList();
        editDelete.visible = true;
    }

    function updateCategoryList() {
        categoryListUpdating = true;
        itemsRequest.get("items/suggest_category", function(code, jsonStr){updateCategoryListResponse(JSON.parse(jsonStr))});
    }

    function updateCategoryListResponse(categories) {
        categoryComboBox.modelUpdating = true;
        var editableText = categoryComboBox.editText;
        categoryComboBoxListModel.clear();
        for (var cnt = 0; cnt < categories.length; ++cnt) {
           categoryComboBoxListModel.append(categories[cnt]);
        }

        categoryComboBox.editText = editableText;
        categoryComboBox.modelUpdating = false;
        categoryListUpdating = false;
    }

    function updateEditDeleteFields(itemId) {
        itemsRequest.get("items/view/"+itemId+"/json", function(code, jsonStr){updateEditDeleteFieldsResponse(JSON.parse(jsonStr))});
    }

    function updateEditDeleteFieldsResponse(data) {
        clearRequiredFieldsValidation();
        itemNumberTextField.text = data.item_info.item_number;
        nameTextField.text = data.item_info.name;
        categoryComboBox.editText = data.item_info.category;
        unitPriceTextField.text = data.item_info.unit_price.replace('.', ',');
        costPriceTextField.text = data.item_info.cost_price.replace('.', ',');
        stockIds = Object.keys(data.stock_locations);
        if (data.item_tax_info.length > 0) {
            tax1NameTextField.text = data.item_tax_info[0].name;
            tax1ValueTextField.text = parseInt(data.item_tax_info[0].percent);

            if (data.item_tax_info.length > 1) {
                tax2NameTextField.text = data.item_tax_info[1].name;
                tax2ValueTextField.text = parseInt(data.item_tax_info[1].percent);
            }
            else {
                tax2NameTextField.text = "";
                tax2ValueTextField.text = "";
            }
        }
        else {
            tax1NameTextField.text = data.default_tax_1_name;
            tax2NameTextField.text = data.default_tax_2_name;
            tax1ValueTextField.text = data.default_tax_1_rate.length > 0 ? parseInt(data.default_tax_1_rate): "";
            tax2ValueTextField.text = data.default_tax_2_rate.length > 0 ? parseInt(data.default_tax_2_rate): "";
        }
        descriptionTextField.text = data.item_info.description;

        var supplier_ids = Object.keys(data.suppliers);
        supplierComboBoxListModel.clear();
        for (var cnt = 0; cnt < supplier_ids.length; ++cnt) {
            if (supplier_ids[cnt].length > 0)
                supplierComboBoxListModel.append({id: supplier_ids[cnt], name: data.suppliers[supplier_ids[cnt]]});

            if (data.suppliers[supplier_ids[cnt]] === data.item_info.company_name)
                supplierComboBox.currentIndex = cnt;
        }
    }

    function clearRequiredFieldsValidation() {
        nameTextField.needValidate = false;
        categoryComboBox.needValidate = false;
        unitPriceTextField.needValidate = false;
        costPriceTextField.needValidate = false;
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

    function saveItem() {
        var item = {
            item_number: itemNumberTextField.text.trim(),
            name: nameTextField.text.trim(),
            description: descriptionTextField.text.trim(),
            category: categoryComboBox.editText.trim(),
            supplier_id: supplierComboBox.currentIndex < 0 ? '': supplierComboBoxListModel.get(supplierComboBox.currentIndex).id,
            cost_price:costPriceTextField.text.replace('.', ''),
            unit_price:unitPriceTextField.text.replace('.', ''),
            tax_names: [tax1NameTextField.text.trim(), tax2NameTextField.text.trim()],
            tax_percents: [tax1ValueTextField.text, tax2ValueTextField.text],
            receiving_quantity: 1, reorder_level: 1, item_image:""};

        for (var i=0; i < stockIds.length; ++i)
            item["quantity_" + stockIds[i]] = 0;

        itemsRequest.post('items/save/' + selectedItemId, item, function(code, jsonStr){
            var response = JSON.parse(jsonStr);
            if (response.success) {
                selectedItemId = parseInt(response.id);
                selectFilter.currentIndex = 0;
                getItems();
                editDelete.visible = false;
                toast.showSuccess(response.message, 3000);
            }
            else
                toast.showError(response.message, 3000);
        });
    }

    function deleteItem() {
        itemsRequest.post('items/delete', {ids:[selectedItemId]}, function(code, jsonStr){
            var response = JSON.parse(jsonStr);
            if (response.success) {
                selectedItemId = -1;
                getItems();
                toast.showSuccess(response.message, 3000);
            }
            else
                toast.showError(response.message, 3000);
        });
    }

    ComboBox {
        id: selectFilter
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.leftMargin: 4
        model: ListModel{
            ListElement{name:"Tüm"}
            ListElement{name:"Barkodsuz"}
            ListElement{name:"Tükenmiş"}
            ListElement{name:"Silinmiş"}
        }
        spacing: 5
        height: 50
        font.pixelSize: 24
        font.family: Fonts.fontBarlowRegular.name
        width: 150
        placeholderText: "Ürün Listesi"
        onCurrentIndexChanged: {
            getItems();
        }
    }

    TextField {
        id: searchTextField
        font.pixelSize: 20
        anchors.left: selectFilter.right
        anchors.right: newItemButton.left
        anchors.top: parent.top
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 4
        height: 50
        font.family: Fonts.fontOrbitronRegular.name
        placeholderText: "Ürün Adı veya Barkod"
        onTextChanged: {
            getItems();
        }
    }

    Button {
        id: newItemButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.rightMargin: 4
        text: "Yeni Ürün"
        height: 50
        width: 150
        font.pixelSize: 24
        onClicked: {
            saveButton.text ="Kaydet";
            deleteButton.visible = true;
            openEditDelete();
        }
    }

    FocusScope {
        id: listMenu
        width: parent.width
        anchors.top: searchTextField.bottom
        anchors.bottom: editDelete.visible? editDelete.top:parent.bottom
        anchors.topMargin: 4
        activeFocusOnTab: true

        clip: true

        Rectangle {
            width: parent.width
            anchors.top: parent.top
            height: 1
            color: list1.activeFocus?"dodgerblue":"lightslategray"
        }

        ListView {
            id: list1
            width: parent.width; height: parent.height
            focus: true
            model: ListModel{id: itemListViewModel}
            cacheBuffer: 200
            onActiveFocusChanged: {
                if (!activeFocus && !anyDescendantHasActiveFocus(editDelete))
                    editDelete.visible = false;
            }
            onCurrentIndexChanged: {
                if (activeFocus)
                    openEditDelete(itemListViewModel.get(currentIndex).id);
            }

            delegate: Item {
                id: container
                width: ListView.view.width; height: 50; anchors.leftMargin: 4; anchors.rightMargin: 4
                Rectangle {
                    id: content
                    anchors.centerIn: parent; width: container.width - 20; height: container.height - 10
                    color: "transparent"
                    antialiasing: true
                    radius: 4
                        ListViewColumnLabel{
                            text: "Barkod"
                            labelOf: itemNumText
                        }
                        Text {
                            id: itemNumText
                            text: num
                            color: "#545454"
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width * (3/8)
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "Ürün Adı"
                            labelOf: nameText
                        }
                        Text {
                            id: nameText
                            text: name
                            color: "#545454"
                            font.pixelSize: 18
                            font.family: Fonts.fontRubikRegular.name
                            width: parent.width *(3/8)
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            anchors.left: itemNumText.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                        }
                        ListViewColumnLabel{
                            text: "Satış Fiyatı"
                            labelOf: unitPriceText
                        }
                        Text {
                            id: unitPriceText
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            anchors.right : parent.right
                            text: unitPrice
                            color: "#545454"
                            font.pixelSize: 20
                            font.family: Fonts.fontIBMPlexMonoRegular.name
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
                        if (!activeFocus)
                            openEditDelete(itemListViewModel.get(index).id);

                        container.ListView.view.currentIndex = index
                        container.forceActiveFocus()
                    }
                    onDoubleClicked: {
                        if (selectFilter.currentIndex != 3)
                            itemsPage.parent.push('Item.qml', {item_id: itemListViewModel.get(index).id})
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: content; color: "#CCD1D9"; width: container.width - 15; height:50; anchors.leftMargin: 10; anchors.rightMargin: 15;}
                    PropertyChanges { target: itemNumText; font.pixelSize: 22; }
                    PropertyChanges { target: nameText; font.pixelSize: 22; }
                    PropertyChanges { target: unitPriceText; font.pixelSize: 24; font.family: Fonts.fontIBMPlexMonoSemiBold.name }
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
            color: list1.activeFocus?"dodgerblue":"lightslategray"
        }
    }

    FocusScope {
        id: editDelete
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: parent.width
        height: 190
        visible: false

        Rectangle {
            anchors.fill: parent
            color: "#f7f8f9"
        }
        TextField {
            id: itemNumberTextField
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            maximumLength: 32
            validator: RegExpValidator { regExp: /[0-9A-F]+/ }
            placeholderText: "Barkod No"
        }

        TextField {
            id: nameTextField
            anchors.left: itemNumberTextField.right
            anchors.top: parent.top
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            maximumLength: 32
            required: true
            placeholderText: "Ürün Adı"
        }

        ComboBoxEditable {
            id: categoryComboBox
            activeFocusOnTab: true
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            model: ListModel {id:categoryComboBoxListModel}
            textRole: "label"
            required: true
            leftPadding: 10
            placeholderText: "Kategori"
        }

        ComboBox {
            id: supplierComboBox
            activeFocusOnTab: true
            focus: true
            anchors.left: parent.left
            anchors.top: itemNumberTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            height: 40
            model: ListModel { id: supplierComboBoxListModel }
            placeholderText: "Sağlayıcı"
        }

        TextField {
            id: costPriceTextField
            anchors.left: supplierComboBox.right
            anchors.top: nameTextField.bottom
            validator: RegExpValidator{
                regExp: /^\s*-?((\d{1,3}(\.(\d){3})*)|\d*)(,\d{1,2})?\s?(\u20BA)?\s*$/
            }
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            required: true
            placeholderText: "Maliyet Fiyatı"
        }

        TextField {
            id: unitPriceTextField
            anchors.right: parent.right
            anchors.top: categoryComboBox.bottom
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            required: true
            validator: RegExpValidator{
                regExp: /^\s*-?((\d{1,3}(\.(\d){3})*)|\d*)(,\d{1,2})?\s?(\u20BA)?\s*$/
            }
            placeholderText: "Satış Fiyatı"
        }

        TextField {
            id: tax1NameTextField
            anchors.left: parent.left
            anchors.top: supplierComboBox.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 6 - 4.665
            maximumLength: 6
            placeholderText: "Vergi 1"
        }
        TextField {
            id: tax1ValueTextField
            anchors.left: tax1NameTextField.right
            anchors.top: supplierComboBox.bottom
            validator: DoubleValidator {
                bottom: 0
                top: 100
            }
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 6 - 4.665
            placeholderText: tax1NameTextField.text + " Oranı"
        }

        TextField {
            id: tax2NameTextField
            anchors.left: tax1ValueTextField.right
            anchors.top: unitPriceTextField.bottom
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 6 - 4.665
            maximumLength: 6
            placeholderText: "Vergi 2"
        }

        TextField {
            id: tax2ValueTextField
            anchors.left: tax2NameTextField.right
            anchors.top: unitPriceTextField.bottom
            validator: DoubleValidator {
                bottom: 0
                top: 100
            }
            anchors.leftMargin: 4
            anchors.topMargin: 4
            width: parent.width / 6 - 4.665
            placeholderText: tax2NameTextField.text + " Oranı"
        }
        TextField {
            id: descriptionTextField
            anchors.right: parent.right
            anchors.top: costPriceTextField.bottom
            anchors.rightMargin: 4
            anchors.topMargin: 4
            width: parent.width / 3 - 5.33
            maximumLength: 32
            placeholderText: "Açıklama"
        }

        Button {
            id: deleteButton
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            anchors.leftMargin: 4
            text: "Sil"
            height: 50
            width: 150
            borderColor: "indianred"
            font.pixelSize: 24
            font.family: Fonts.fontBarlowRegular.name
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
            borderColor: "mediumseagreen"
            onClicked: {
                nameTextField.needValidate = true;
                categoryComboBox.needValidate = true;
                unitPriceTextField.needValidate = true;
                costPriceTextField.needValidate = true;

                if(nameTextField.isInvalid() || categoryComboBox.isInvalid() || unitPriceTextField.isInvalid() || costPriceTextField.isInvalid())
                    toast.showError("Kırmızı Alanlar Boş Bırakılamaz!", 3000);
                else
                    saveItem();
            }
        }
    }
}
