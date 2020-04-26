import QtQuick 2.7
import QtQuick.Controls 2.0
import "../../fonts"

TextField {
    id: control
    font.pixelSize: 20
    activeFocusOnTab: true
    height: 40
    leftPadding: 6
    bottomPadding: -11
    font.family: Fonts.fontRubikRegular.name
    placeholderText: ""
    horizontalAlignment: "AlignLeft"
    property bool required: false
    property bool needValidate: false
    background: Rectangle {
        border.color: isInvalid()?"salmon":(control.activeFocus?"mediumturquoise":"lightslategray")
        border.width: 1
        color: control.activeFocus ?(isInvalid()?"salmon":"mediumturquoise"): "transparent"
    }

    function isInvalid() {
        if (needValidate && required && control.text.trim().length === 0 )
            return true;
        else
            return false;
    }

    Text {
        id: topPlaceholder
        anchors.left: control.left
        anchors.top: control.top
        anchors.leftMargin: 6
        anchors.topMargin: 2
        text: control.placeholderText
        visible: control.text.length > 0
        font.family: control.font.family
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
    color: activeFocus ? "white": "#545454"
}
