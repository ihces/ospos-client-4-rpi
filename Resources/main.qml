import QtQuick 2.7
import QtQuick.Controls 2.0
import posapp.restrequest 1.0
import posapp.updateservice 1.0
import posapp.osservice 1.0

import "./fonts"
import "./view/controls"
import "./view/popups"
import "./view/helpers/helper.js" as Helper

ApplicationWindow {
    id: window
    visible: true
    property ApplicationWindow appWindow : window
    property BusyIndicator busyIndicator: busyIndication
    property StackView stack: stackView
    property string popData
    width: 800
    height: 480
    title: qsTr("PosApp")

    function checkConnectivity() {
        connectivity.state = "CHECKING";
        checkServerConnection(function(){
            connectivity.state = "CONNECTED";
            if (updateButton.state == "CHECKING_UPDATES")
                updateService.checkUpdate();
        }, function() {
            if (connectivity.state != "NOTCONNECTED")
                toast.showError("Sunucuya bağlanılamadı! Lütfen bağlantı ayarlarınızı kontrol ediniz.", 3000);
            connectivity.state = "NOTCONNECTED";
        });
    }

    function postRequest(path, data, timeoutMs, errorFunc) {
        var xhr = new XMLHttpRequest();
        var url = "http://localhost:8080/" + path;
        xhr.open("POST", url, true);

        var timer = Qt.createQmlObject("import QtQuick 2.7; Timer {interval: 1000; repeat: true; running: false;}",window,"Timer4Timeout2");

        var startTime = new Date();
        timer.triggered.connect(function(){
            if ((new Date() - startTime) > timeoutMs) {
                timer.running = false;
                xhr.abort();
                errorFunc();
            }
        });

        xhr.setRequestHeader("Content-type", "application/json");
        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4) {
                if (xhr.status === 200)
                    timer.running = false;
                else if (xhr.status !== 0) {
                    timer.running = false;
                    if (errorFunc !== undefined)
                        errorFunc();
                }
            }
        }

        xhr.send(JSON.stringify(data));
        timer.running = true;
    }

    function checkServerConnection(connected_handler, disconnected_handler) {
        var xhr = new XMLHttpRequest();
        var url = "http://3.123.73.136/live";
        xhr.open("GET", url, true);

        var timer = Qt.createQmlObject("import QtQuick 2.7; Timer {interval: 1000; repeat: true; running: false;}",window,"Timer4Timeout");

        var startTime = new Date();
        timer.triggered.connect(function(){
            if ((new Date() - startTime) > 5000) {
                timer.running = false;
                xhr.abort();
                disconnected_handler();
            }
        });

        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4 && xhr.status === 200) {
                connected_handler();
                timer.running = false;
            }
        }

        xhr.send();
        timer.restart();
    }

    BusyIndicator {
        id: busyIndication
        anchors.centerIn: parent
        running: false
        z: Infinity
    }

    ToastManager{
        id: toast
    }

    DialogPopup {
        id: dialogPopup
    }

    UpdateService {
        id: updateService
        onCheckUpdateFinished: {
            updateButton.state = upgradablePackFound?"UPGRADABLE_PACKS_FOUND":"UPTODATE";
        }
        onUpdateFinished: {
            updateButton.state = "UPTODATE";
            osService.restart();
        }
    }

    OsService {
        id: osService
    }

    RestRequest{
        id: restRequest
        onLoginCompleted: {
            if (succeed){
                loginPopup.close();
                userText.text = userNameField.text
                toast.showSuccess("Giriş Başarılı", 3000);
                passwordField.text = "";
            }
            else {
                toast.showError("Kullanıcı Adı veya Parola Hatalı", 3000);
            }
        }
        onRequestTimeout: {
            toast.showError("Oturum açma talebi süre aşımına uğradı!", 3000);
        }
        onStart: {busyIndicator.running = true}
        onEnd: {busyIndicator.running = false}
    }

    Popup{
        id: loginPopup
        width: parent.width * 0.5
        height: parent.height * 0.7
        x: parent.width * 0.25
        y: parent.height * 0.2
        z: 98
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: {
            userNameField.forceActiveFocus();
        }

        Rectangle{
            width: parent.width * 0.9
            height: parent.height * 0.9
            anchors.centerIn: parent
            Text {
                id: userLoginIcon
                text: "\uF502"
                color: "slategray"
                font.pixelSize: 42
                font.family: Fonts.fontAwesomeSolid.name
                anchors.top: parent.top
                width: parent.width
                horizontalAlignment: "AlignHCenter"
            }
            TextField {
                id: userNameField
                required: true
                anchors.right: parent.right
                anchors.top: userLoginIcon.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 35
                width: parent.width
                font.family: Fonts.fontProductRegular.name
                placeholderText: "Kullanıcı"
            }
            TextField {
                id: passwordField
                required: true
                echoMode: TextInput.Password
                anchors.right: parent.right
                anchors.top: userNameField.bottom
                horizontalAlignment: "AlignHCenter"
                anchors.topMargin: 5
                width: parent.width
                font.family: Fonts.fontProductRegular.name
                placeholderText: "Şifre"
            }

            Button {
                id:loginButton
                text: "Giriş"
                height: 40
                width: parent.width
                anchors.bottom: parent.bottom
                enabled: !busyIndicator.running
                onClicked: {
                    userNameField.needValidate = true;
                    passwordField.needValidate = true;

                    if (userNameField.isInvalid() || passwordField.isInvalid())
                        toast.showError("Gerekli Alanlar Boş Bırakılamaz!", 3000);
                    else
                        restRequest.login(userNameField.text, passwordField.text)
                }
                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        clicked();
                    }
                }
            }
        }
    }

    header: ToolBar {
        background: Rectangle{
            anchors.fill: parent
            color: "slategray"
        }
        contentHeight: 50
        z: 97

        ToolButton {
            id: toolButton
            text: stackView.depth > 1 ? "\u25C0" : ""
            font.pixelSize: 24
            activeFocusOnTab: true
            height: parent.height
            anchors.left: parent.left
            padding: 10
            width: 50
            background: Rectangle{
                anchors.fill: parent
                color: stackView.depth > 1 ? (toolButton.activeFocus?"mediumturquoise":"lightslategray"): "slategray"
            }
            onClicked: {
                if (stackView.depth > 1) {
                    stackView.pop()
                }
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    if (stackView.depth > 1) {
                        stackView.pop()
                    }
                }
            }
        }

        ToolButton {
            Text {
                id: userText
                color: "white"
                text: "Oturum Aç"
                anchors.right: userIcon.left
                verticalAlignment: Text.AlignVCenter
                anchors.rightMargin: 5
                height: parent.height
            }
            Text {
                id: userIcon
                color: "white"
                text: "\uF007"
                font.pixelSize: 18
                anchors.right: parent.right
                anchors.rightMargin: 5
                font.family: Fonts.fontAwesomeSolid.name
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }

            id: toolButton2
            activeFocusOnTab: true
            font.pixelSize: 14
            width: userIcon.width + userText.width + 15
            height: parent.height
            anchors.right: parent.right
            padding: 10
            enabled: connectivity.state == "CONNECTED"
            opacity: enabled?1:0.4
            background: Rectangle{
                anchors.fill:parent
                color: toolButton2.activeFocus?"mediumturquoise":"slategray"
            }
            onClicked: {
                loginPopup.open()
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
            font.pixelSize: 24
            font.family: Fonts.fontBlackOpsOneRegular.name
        }
    }

    footer: ToolBar {
        Rectangle {
            width: parent.width
            height: 1
            color: "#c4d5e6"
            z: 98
        }

        background: Rectangle {
            anchors.fill: parent
            color: "#f7f8fa"
        }

        contentHeight: 50
        z: 97

        Rectangle {
            width: parent.width - 80
            height: parent.height
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: "transparent"
            Image {
                id: productLogo
                anchors.right: logo.left
                anchors.rightMargin: 8
                source: "./images/product-logo.png"
                antialiasing: true
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -8
            }
            Rectangle {
                width: 1
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                height: 34
                anchors.right: logo.left
                anchors.rightMargin: 4
                color: "#c4d5e6"
            }
            Image {
                id: logo
                source: "./images/logo-small.png"
                antialiasing: true
                x: (parent.width - logo.width) /2
                anchors.top: parent.top
                anchors.topMargin: -6
            }

            Text{
                id: versionText
                text: "Sürüm 1.0-3 2020-06-19 (βeta)"
                font.pixelSize: 12
                font.italic: true
                anchors.topMargin: -1
                anchors.top: logo.bottom
                anchors.left: logo.left
                anchors.leftMargin: 3
                color: "#999"
            }
        }

        ToolButton {
            id: connectivity
            anchors.left: parent.left
            height: parent.height
            width: height
            state: "CHECKING"
            background: Rectangle{
                anchors.fill:parent
                color: "transparent"
            }
            Text {
                id: connectivityText
                SequentialAnimation on opacity{
                    running: connectivity.state == "CHECKING" || connectivityText.opacity <= 0.99
                    loops: Animation.Infinite;
                    PropertyAnimation  { from: 1; to: 0.4; duration: 2000 }
                    PropertyAnimation  { from: 0.4; to: 1; duration: 2000 }
                }
                color: connectivity.state == "NOTCONNECTED"?(connectivity.activeFocus?"crimson":"indianred"):"dodgerblue"
                text: "\uF7A2"
                font.pixelSize: 18
                font.family: Fonts.fontAwesomeSolid.name
                anchors.centerIn: parent
            }

            onClicked: {if (connectivity.state == "NOTCONNECTED") checkConnectivity();}
        }

        ToolButton {
            id: updateButton
            visible: connectivity.state == "CONNECTED"
            Text {
                id: updateIcon
                color: updateButton.state == "UPGRADABLE_PACKS_FOUND"? "dodgerblue": (updateButton.state == "UPTODATE" ? "seagreen": "#f4a460")
                SequentialAnimation on opacity{
                    running: updateButton.state == "CHECKING_UPDATES" || updateIcon.opacity <= 0.99
                    loops: Animation.Infinite;
                    PropertyAnimation  { from: 1; to: 0.4; duration: 2000 }
                    PropertyAnimation  { from: 0.4; to: 1; duration: 2000 }
                }
                text: updateButton.state == "UPGRADABLE_PACKS_FOUND"? "\uF005": (updateButton.state == "UPTODATE" ? "\uF058": "\uF021")
                font.pixelSize: 18
                anchors.left: parent.left
                font.family: Fonts.fontAwesomeSolid.name
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }
            Text {
                id: updateText
                color: updateIcon.color
                SequentialAnimation on opacity{
                    running: updateButton.state == "CHECKING_UPDATES" || updateText.opacity <= 0.99
                    loops: Animation.Infinite;
                    PropertyAnimation  { from: 1; to: 0.4; duration: 2000 }
                    PropertyAnimation  { from: 0.4; to: 1; duration: 2000 }
                }
                anchors.leftMargin: 5
                text: updateButton.state == "UPGRADABLE_PACKS_FOUND"? "Yeni Sürüme Geç": (updateButton.state == "UPTODATE" ? "Güncel": (updateButton.state == "UPGRADING"? "Güncelleniyor...":"Güncellemeler Denetleniyor..."))
                anchors.left: updateIcon.right
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }
            height: parent.height
            width: updateIcon.width + updateText.width + 15
            anchors.left: connectivity.right
            padding: 10
            background: Rectangle{
                anchors.fill:parent
                color: "transparent"
            }
            onClicked: {
                if (updateButton.state == "UPGRADABLE_PACKS_FOUND") {
                    dialogPopup.confirmation("Güncelleme Uyarısı", "Güncelleme yapıldıktan sonra sistem yeniden başlatılacaktır. Güncelleme yapılsın mı?", function() {
                        updateButton.state = "UPGRADING";
                        updateService.update();
                    });
                }
            }

            state: "CHECKING_UPDATES"

        }

        ToolButton {
            id: powerOffButton
            Text {
                color: "white"
                text: "\uF011"
                font.pixelSize: 18
                font.family: Fonts.fontAwesomeSolid.name
                anchors.centerIn: parent
            }

            activeFocusOnTab: true
            width: height
            height: parent.height
            anchors.right: parent.right
            padding: 10
            background: Rectangle{
                anchors.fill:parent
                color: powerOffButton.activeFocus?"crimson":"indianred"
            }
            onClicked: {
                dialogPopup.confirmation("Cihazı Kapat", "Cihazı kapatmak istediğinizden emin misiniz?", function() {
                    osService.shutdown();
                });
            }
        }
    }

    StackView {
        id: stackView
        initialItem: "view/page/Home.qml"
        anchors.fill: parent
        z: 96
        enabled: connectivity.state == "CONNECTED"
        opacity: enabled?1:0.4
        onCurrentItemChanged: {
            if (currentItem.title === "Giriş") {
                checkConnectivity();

                footer.visible = true;

                if (restRequest.isSessionTimeout)
                    loginPopup.open();
            }
            else
                footer.visible = false;
        }
    }
}
