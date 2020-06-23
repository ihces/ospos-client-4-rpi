import QtQuick 2.7
import QtQuick.Controls 2.0
import "../../fonts"

ComboBox {
    id: control
    font.pixelSize: 22
    height: 40
    width: 200
    font.family: Fonts.fontBarlowRegular.name
    displayText: currentIndex === -1 ? placeholderText : currentText
    property string placeholderText
    property bool required: false
    property bool needValidate: false
    function isInvalid() {
        if (needValidate && required && control.displayText.trim().length === 0 )
            return true;
        else
            return false;
    }
    textRole: "name"
    delegate: ItemDelegate {
        width: control.width
        contentItem: Text {
            text: name
            color: "#545454"
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        highlighted: control.highlightedIndex === index
    }
    Text {
        anchors.left: control.left
        anchors.top: control.top
        anchors.leftMargin: 6
        anchors.topMargin: 2
        text: placeholderText
        visible: control.displayText != text
        font.family: Fonts.fontRubikRegular.name
        color: "#79545454"
        font.pixelSize: 11
    }
    Text {
        anchors.right: control.right
        anchors.top: control.top
        anchors.rightMargin: 6
        anchors.topMargin: 2
        text: "Gerekli"
        visible: control.required
        font.family: Fonts.fontNunitoItalic.name
        color: control.activeFocus && isInvalid()?"#79ffffff":"#79ff4500"
        font.pixelSize: 11
    }
    onEnabledChanged: canvas.requestPaint()
    indicator: Canvas {
            id: canvas
            x: control.width - width - control.rightPadding
            y: control.topPadding + (control.availableHeight - height) / 2
            width: 12
            height: 8
            contextType: "2d"

            Connections {
                target: control
                onActiveFocusChanged: canvas.requestPaint()
            }

            onPaint: {
                context.reset();
                context.moveTo(0, 0);
                context.lineTo(width, 0);
                context.lineTo(width / 2, height);
                context.closePath();
                context.fillStyle = !control.enabled?"#c4d5e6":(control.activeFocus?"white":"lightslategray");
                context.fill();
            }
        }
    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: listview2.contentHeight
        padding: 1
        contentItem: ListView {
            id: listview2
            clip: true
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }
        background: Rectangle {
            border.color: isInvalid()?"salmon":"mediumturquoise"
            radius: 2
        }
    }
    contentItem: Text {
        leftPadding: 6
        bottomPadding: -11
        rightPadding: control.indicator.width + control.spacing
        text: control.displayText
        font: control.font
        color: control.displayText === placeholderText ?
                   "#79545454": (control.activeFocus ? "white" : "#545454")
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: "AlignLeft"
    }
    background: Rectangle {
        border.color: !control.enabled?"#c4d5e6":(isInvalid()?"salmon":(control.activeFocus?"mediumturquoise":"lightslategray"))
        border.width: 1
        color: !control.enabled?"white":(control.activeFocus ?(isInvalid()?"salmon":"mediumturquoise"): "#f7f8f9")
    }
}
