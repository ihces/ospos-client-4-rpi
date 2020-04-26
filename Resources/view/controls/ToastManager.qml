import QtQuick 2.7

/**
  * adapted from StackOverflow:
  * http://stackoverflow.com/questions/26879266/make-toast-in-android-by-qml
  * @brief Manager that creates Toasts dynamically
  */
ListView {
    /**
      * Public
      */

    /**
      * @brief Shows a Toast
      *
      * @param {string} text Text to show
      * @param {real} duration Duration to show in milliseconds, defaults to 3000
      * @param {string} toasttype toasttype
      */
    function show(text, duration, toasttype) {
        if (typeof toasttype === "undefined")
            toasttype = "info";
        model.insert(0, {text: text, duration: duration, toasttype: toasttype});
    }

    function showWarning(text, duration) {
        show(text, duration, "warning");
    }

    function showError(text, duration) {
        show(text, duration, "error");
    }

    function showSuccess(text, duration) {
        show(text, duration, "success");
    }

    /**
      * Private
      */

    id: root

    z: Infinity
    spacing: 5
    anchors.fill: parent
    anchors.bottomMargin: 10
    verticalLayoutDirection: ListView.BottomToTop

    interactive: false

    displaced: Transition {
        NumberAnimation {
            properties: "y"
            easing.type: Easing.InOutQuad
        }
    }

    delegate: Toast {
        Component.onCompleted: {
            show(text, duration, toasttype);
        }
    }

    model: ListModel {id: model}
}
