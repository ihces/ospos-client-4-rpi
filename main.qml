import QtQuick 2.7
import QtQuick.Controls 2.0

ApplicationWindow {
    id: window
    visible: true
    visibility: ApplicationWindow.FullScreen
    title: qsTr("PosApp")
    header: ToolBar {
        background: Rectangle{
            anchors.fill: parent
            color: "slategray"
        }
        contentHeight: 40

        ToolButton {
            id: toolButton
            text: stackView.depth > 1 ? "\u25C0" : "\u2630"
            font.pixelSize: 24
            activeFocusOnTab: true
            height: parent.height
            anchors.left: parent.left
            KeyNavigation.left: toolButton2
            padding: 10
            background: Rectangle{
                anchors.fill: parent
                color: toolButton.checked?"steelblue": (toolButton.activeFocus?"navy":"slategray")
            }
            onClicked: {
                if (stackView.depth > 1) {
                    stackView.pop()
                } else {
                    drawer.open()
                }
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    if (stackView.depth > 1) {
                        stackView.pop()
                    } else {
                        drawer.open()
                    }
                }
            }
        }

        ToolButton {
            id: toolButton2
            activeFocusOnTab: true
            text: "ibrahim hakkı"
            font.pixelSize: 14
            height: parent.height
            anchors.right: parent.right
            padding: 10
            KeyNavigation.left: toolButton
            KeyNavigation.down: stackView
            background: Rectangle{
                anchors.fill:parent
                color: toolButton2.checked?"steelblue": (toolButton2.activeFocus?"navy":"slategray")
            }
            onClicked: {
                console.log("profile clicked")
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    if (stackView.depth > 1) {
                        stackView.pop()
                    } else {
                        drawer.open()
                    }
                }
            }
        }

        Label {
            text: stackView.currentItem.title
            anchors.centerIn: parent
            color: "white"
            font.pointSize: 24
        }
    }

    Drawer {
        id: drawer
        width: 320
        height: window.height

        KeyNavigation.right: stackView
        onActiveFocusChanged: {
            if(!activeFocus)
                drawer.close()
            else
                page1Link.forceActiveFocus()
        }

        Rectangle {
            anchors.left: parent.Left
            anchors.top : parent.top
            width: parent.width
            height: 100

            Image {
                id: successIcon
                source: "view/images/success.png"
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 50
                anchors.topMargin: 10
                height: 64
                width: 64
            }
            Text {
                id: brand
                text: qsTr("ZeyreK")
                anchors.left: successIcon.right
                topPadding: 18
                leftPadding: 15
                font.family: "Arial"
                font.pointSize: 24
                width: 100
                color: "mediumspringgreen"
            }
            Text {
                text: qsTr("yazılım")
                anchors.left: successIcon.right
                anchors.top: brand.bottom
                font.family: "Arial"
                leftPadding: 15
                font.pointSize: 12
                width: 100
                color: "slategray"
            }
        }

        Column {
            y: 100
            width: parent.width
            height: parent.height - 100
            ItemDelegate {
                id: page1Link
                width: parent.width
                height: 60
                activeFocusOnTab: true
                KeyNavigation.up: page6Link
                KeyNavigation.right: stackView
                KeyNavigation.down: page2Link
                Image {
                    id: saleIcon
                    source: "view/images/basket.png"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin:5
                    anchors.leftMargin: 5
                    height: 50
                    width: 50
                }
                Text {
                    text: qsTr("Satış")
                    anchors.left: saleIcon.right
                    padding: 15
                    font.family: "Arial"
                    font.pointSize: 18
                    color: parent.activeFocus? "white": "slategray"
                    font.bold: parent.activeFocus?true: false
                }
                background: Rectangle{
                    anchors.fill: parent
                    color: parent.activeFocus? "mediumspringgreen":"transparent"
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        stackView.push("view/page/Sale.qml")
                        drawer.close()
                    }
                }
                onClicked: {
                    stackView.push("view/page/Sale.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                id: page2Link
                width: parent.width
                height: 60
                activeFocusOnTab: true
                KeyNavigation.up: page1Link
                KeyNavigation.right: stackView
                KeyNavigation.down: page3Link
                Image {
                    id: supplyIcon
                    source: "view/images/trolley.png"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin:5
                    anchors.leftMargin: 5
                    height: 50
                    width: 50
                }
                Text {
                    text: qsTr("Alım")
                    anchors.left: supplyIcon.right
                    padding: 15
                    font.family: "Arial"
                    font.pointSize: 18
                    color: parent.activeFocus? "white": "slategray"
                    font.bold: parent.activeFocus?true: false
                }
                background: Rectangle{
                    anchors.fill: parent
                    color: parent.activeFocus? "mediumspringgreen":"transparent"
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        stackView.push("view/page/Accounts.qml")
                        drawer.close()
                    }
                }
                onClicked: {
                    stackView.push("view/page/Accounts.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                width: parent.width
                height: 60
                activeFocusOnTab: true
                id: page3Link
                KeyNavigation.up: page2Link
                KeyNavigation.right: stackView
                KeyNavigation.down: page4Link
                Image {
                    id: itemsIcon
                    source: "view/images/tag.png"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin:5
                    anchors.leftMargin: 5
                    height: 50
                    width: 50
                }
                Text {
                    text: qsTr("Ürünler")
                    anchors.left: itemsIcon.right
                    padding: 15
                    font.pointSize: 18
                    font.family: "Arial"
                    color: parent.activeFocus? "white": "slategray"
                    font.bold: parent.activeFocus?true: false
                }
                background: Rectangle{
                    anchors.fill: parent
                    color: parent.activeFocus? "mediumspringgreen":"transparent"
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        stackView.push("view/page/Items.qml")
                        drawer.close()
                    }
                }
                onClicked: {
                    stackView.push("view/page/Items.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                id: page4Link
                width: parent.width
                height: 60
                activeFocusOnTab: true
                KeyNavigation.up: page3Link
                KeyNavigation.right: stackView
                KeyNavigation.down: page5Link
                Image {
                    id:customersIcon
                    source: "view/images/cashbook.png"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin:5
                    anchors.leftMargin: 5
                    height: 50
                    width: 50
                }
                Text {
                    text: qsTr("Hesaplar")
                    anchors.left: customersIcon.right
                    padding: 15
                    font.family: "Arial"
                    font.pointSize: 18
                    color: parent.activeFocus? "white": "slategray"
                    font.bold: parent.activeFocus?true: false
                }
                background: Rectangle{
                    anchors.fill: parent
                    color: parent.activeFocus? "mediumspringgreen":"transparent"
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        stackView.push("view/page/Accounts.qml")
                        drawer.close()
                    }
                }
                onClicked: {
                    stackView.push("view/page/Accounts.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                id: page5Link
                width: parent.width
                height: 60
                activeFocusOnTab: true
                KeyNavigation.up: page4Link
                KeyNavigation.right: stackView
                KeyNavigation.down: page6Link
                Image {
                    id: reportsIcon
                    source: "view/images/graph.png"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin:5
                    anchors.leftMargin: 5
                    height: 50
                    width: 50
                }
                Text {
                    text: qsTr("Raporlar")
                    anchors.left: reportsIcon.right
                    padding: 15
                    font.family: "Arial"
                    font.pointSize: 18
                    color: parent.activeFocus? "white": "slategray"
                    font.bold: parent.activeFocus?true: false
                }
                background: Rectangle{
                    anchors.fill: parent
                    color: parent.activeFocus? "mediumspringgreen":"transparent"
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        stackView.push("view/page/Accounts.qml")
                        drawer.close()
                    }
                }
                onClicked: {
                    stackView.push("view/page/Accounts.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                id: page6Link
                width: parent.width
                height: 60
                activeFocusOnTab: true
                KeyNavigation.up: page5Link

                KeyNavigation.down: page1Link
                Image {
                    id: settingsIcon
                    source: "view/images/settings.png"
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin:5
                    anchors.leftMargin: 5
                    height: 50
                    width: 50
                }
                Text {
                    text: qsTr("Ayarlar")
                    anchors.left: settingsIcon.right
                    padding: 15
                    font.family: "Arial"
                    font.pointSize: 18
                    color: parent.activeFocus? "white": "slategray"
                    font.bold: parent.activeFocus?true: false
                }
                background: Rectangle{
                    anchors.fill: parent
                    color: parent.activeFocus? "mediumspringgreen":"transparent"
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        stackView.push("view/page/Accounts.qml")
                        drawer.close()
                    }
                }
                onClicked: {
                    stackView.push("view/page/Accounts.qml")
                    drawer.close()
                }
            }
        }
        Text {
            text: qsTr("")
        }
    }

    StackView {
        id: stackView
        initialItem: "view/page/Sale.qml"
        anchors.fill: parent
    }
}
