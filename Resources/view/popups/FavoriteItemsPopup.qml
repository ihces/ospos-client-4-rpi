import QtQuick 2.7
import QtQuick.Controls 2.0
import posapp.restrequest 1.0
import QtMultimedia 5.9
import "../../fonts"
import "../controls"

Popup{
    id: control
    width: 600 //parent.width * 0.75
    height: 350 //parent.height * 0.75
    x: parent.width * 0.125
    y: parent.height * 0.125
    z: 200
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    property int busyIndicatorCnt: 0
    property string closeReason
    property int numOfRequest
    property var groupedFavoriteItems
    property var categories
    SoundEffect {
        id: popupSound
        source: "../../sounds/popup.wav"
    }
    RestRequest {
        id:favoriteItemsRequest

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
        numOfRequest = 0;
        getFavoriteItems();
        getAllCategories();
    }

    function getFavoriteItems() {
        favoriteItemsRequest.get("items/get_favorite_items",
                                 function(code, jsonStr) {
                                     var favoriteItems = JSON.parse(jsonStr);
                                     groupedFavoriteItems = {};
                                     for (var i=0; i < favoriteItems.length; ++i) {
                                         if (groupedFavoriteItems[favoriteItems[i].group_name] === undefined)
                                             groupedFavoriteItems[favoriteItems[i].group_name] = [];
                                         groupedFavoriteItems[favoriteItems[i].group_name].push(favoriteItems[i]);
                                     }
                                     fillCategoryList();
                                 });
    }

    function getAllCategories() {
        favoriteItemsRequest.get("items/suggest_category",
                                 function(code, jsonStr) {
                                     categories = JSON.parse(jsonStr);
                                     fillCategoryList();
                                 });
    }

    function fillCategoryList() {
        if (++numOfRequest != 2)
            return;

        categoryListModel.clear();
        var favoriteGroups = Object.keys(groupedFavoriteItems);
        for (var i=0; i < favoriteGroups.length; ++i)
            categoryListModel.append({type: "fav", name: favoriteGroups[i]});
        for (i=0; i < categories.length; ++i)
            categoryListModel.append({type: "cat", name: categories[i].label});
        categoryListView.currentIndex = 0;
    }

    function fillItemList(items) {
        itemsListModel.clear();

        for (var i=0; i < items.length; ++i)
            itemsListModel.append({id:items[i].item_id, "name": items[i].name, picture: items[i].image_path.replace('https', 'http')});
    }

    function getItemsByCategory(category) {
        favoriteItemsRequest.get("items/get_items_by_category/"+encodeURIComponent(category),
                                 function(code, jsonStr){
                                     fillItemList(JSON.parse(jsonStr));
                                 });
    }

    function isItemFocused(id) {
        return itemsGridView.currentIndex >= 0 && itemsListModel.get(itemsGridView.currentIndex).id === id;
    }

    Rectangle{
        id: favoriteItemsTitle
        width: parent.width
        height: 40
        Text {
            text: "Ürünler"
            color: "hotpink"
            font.pixelSize: 24
            font.family: Fonts.fontRubikRegular.name
            anchors.centerIn: parent
        }
    }
    FocusScope {
        id: categoryList
        anchors.left: parent.Left
        width: parent.width / 4
        anchors.top: favoriteItemsTitle.bottom
        anchors.topMargin: 4
        height: parent.height - favoriteItemsTitle.height - 4
        activeFocusOnTab: true
        z: 1000
        clip: true
        Rectangle {
            width: parent.width
            height: parent.height
            color: "transparent"
            border.color: "hotpink"
            border.width: 1
        }
        ListView {
            id: categoryListView
            width: parent.width; height: parent.height
            focus: true
            model: ListModel {
                id: categoryListModel
            }
            onCurrentIndexChanged: {
                var groupOrCategory = categoryListModel.get(currentIndex);
                if (groupOrCategory.type === "fav")
                    fillItemList(groupedFavoriteItems[groupOrCategory.name]);
                else
                    getItemsByCategory(groupOrCategory.name);
            }

            cacheBuffer: 200
            delegate: Item {
                id: container
                width: categoryListView.width; height: 35; anchors.leftMargin: 4; anchors.rightMargin: 4
                Rectangle {
                    id: categoryContent
                    anchors.centerIn: parent; width: container.width - 20; height: container.height
                    antialiasing: true
                    color: type === "fav"?"mistyrose":"transparent"
                    ListViewColumnLabel{
                        text: type === "fav"?"Favori": "Kategori"
                        labelOf: categoryName
                    }
                    Text {
                        id: categoryName
                        text: name
                        color: "#545454"
                        font.pixelSize: type === "fav"?20:16
                        font.family: Fonts.fontRubikRegular.name
                        width: parent.width
                        anchors.left: parent.left
                        verticalAlignment: Text.AlignVCenter
                        height: parent.height
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        container.forceActiveFocus()
                        categoryListView.currentIndex = index;
                    }

                    onDoubleClicked: {
                        container.forceActiveFocus();
                        categoryListView.currentIndex = index;
                    }
                }

                states: State {
                    name: "active"; when: container.activeFocus
                    PropertyChanges { target: container; height: 45; anchors.leftMargin: -5}
                    PropertyChanges { target: categoryContent; color: "#CCD1D9"; height: 45; width: container.width - 15;}
                    PropertyChanges { target: categoryName; font.pixelSize: type === "fav"?22:18; font.bold: true}
                }
            }
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Behavior on y {
                NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
            }
        }
    }
    FocusScope {
        id: itemsList
        width: parent.width * 0.75 -12
        anchors.top: favoriteItemsTitle.bottom
        anchors.margins: 4
        anchors.right: parent.right
        height: parent.height - favoriteItemsTitle.height - 4
        activeFocusOnTab: true
        z: 1000
        clip: true
        Rectangle {
            width: parent.width
            height: parent.height
            color: "transparent"
            border.color: "hotpink"
            border.width: 1
        }
        GridView {
            id:itemsGridView
            anchors.fill: parent
            cellWidth: 100; cellHeight: 110
            focus: true
            model: ListModel {
                id: itemsListModel
            }
            highlight: Rectangle { width: 80; height: 90; color: "#CCD1D9" }
            delegate: Item {
                width: 100; height: 110
                Image {
                    id: itemPicture
                    y: 10; anchors.horizontalCenter: parent.horizontalCenter
                    source: picture
                    width: 80
                    height: 80
                    antialiasing: true
                }

                Rectangle{
                    anchors { bottom: parent.bottom;}
                    width: parent.width
                    height: itemNameText.height
                    color: isItemFocused(id)?"#7f545454":"#7fffffff"
                    Text {
                        id: itemNameText
                        anchors.margins: 5
                        anchors.centerIn: parent
                        text: name
                        color: isItemFocused(id)?"white":"#545454"
                        font.pixelSize: 14
                        font.bold: isItemFocused(id)
                        font.family: Fonts.fontRubikRegular.name
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        width: parent.width
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        itemsGridView.currentIndex = index
                    }
                    onDoubleClicked: {
                        itemsGridView.currentIndex = index;
                        closeReason = itemsListModel.get(itemsGridView.currentIndex).id;
                        close();
                    }
                }
            }
        }
    }
}
