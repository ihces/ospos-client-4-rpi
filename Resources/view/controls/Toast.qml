import QtQuick 2.7
import "../../fonts"

/**
 * adapted from StackOverflow:
 * http://stackoverflow.com/questions/26879266/make-toast-in-android-by-qml
 */

/**
  * @brief An Android-like timed message text in a box that self-destroys when finished if desired
  */
Rectangle {

    /**
      * Public
      */

    /**
      * @brief Shows this Toast
      *
      * @param {string} text Text to show
      * @param {real} duration Duration to show in milliseconds, defaults to 3000
      * @param {string} toasttype
      */
    function show(text, duration, toasttype) {
        message.text = text;
        root.type = toasttype;
        if (typeof duration !== "undefined") { // checks if parameter was passed
            time = Math.max(duration, 2 * fadeTime);
        }
        else {
            time = defaultTime;
        }
        animation.start();

    }

    property bool selfDestroying: false  // whether this Toast will self-destroy when it is finished

    /**
      * Private
      */

    id: root

    readonly property real defaultTime: 3000
    property real time: defaultTime
    readonly property real fadeTime: 300
    property string type

    property real margin: 10

    anchors {
        left: parent.left
        right: parent.right
        leftMargin: parent.width/4
        rightMargin: parent.width/4
        topMargin: margin
        bottomMargin: margin
    }

    height: message.height + margin
    radius: margin/4
    color: type == "success"?"#2e8b57":(type == "error"?"#fa8072": (type == "warning"?"#f4a460":"#4682b4"));
    opacity: 0

    Text {
        id: message
        color: "white"
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: margin / 2
        }
        font.family: Fonts.fontProductRegular.name
        font.pixelSize: 18
    }

    SequentialAnimation on opacity {
        id: animation
        running: false


        NumberAnimation {
            to: .9
            duration: fadeTime
        }

        PauseAnimation {
            duration: time - 2 * fadeTime
        }

        NumberAnimation {
            to: 0
            duration: fadeTime
        }

        onRunningChanged: {
            if (!running && selfDestroying) {
                root.destroy();
            }
        }
    }
}
