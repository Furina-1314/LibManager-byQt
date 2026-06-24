import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic


ApplicationWindow {
    id: window
    width: 1280
    height: 960
    minimumWidth: 200
    minimumHeight: 250
    visible: true
    visibility:Window.FullScreen
    title: qsTr("LibManager")
    property bool lightMode: Application.styleHints.colorScheme === Qt.Light
    property color reallyDark: "#1f1f1f"
    property color dark: "#262626"
    property color reallyLight: "#e7e7e7"
    property color light: "#e0e0e0"

    GridLayout {
        id: grid
        columns: width < 400 ? 1 : 2
        rowSpacing: 0
        columnSpacing: 0
        anchors.fill: parent

        Rectangle {
            id: rectangle1
            color: window.lightMode ? window.reallyLight : window.reallyDark
            Layout.fillHeight: true
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

                Label {
                    id: text1
                    color: window.lightMode ? window.dark : window.light
                    font.pixelSize: 80
                    fontSizeMode: Text.Fit
                    text: qsTr("欢迎使用\n图书管理系统")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Rectangle {
            id: rectangle2
            color: window.lightMode ? window.light : window.dark
            Layout.fillHeight: true
            Layout.fillWidth: true

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 20
                spacing: 12  // 两个按钮之间的间距

             Button {
                id: button1
                text: window.lightMode ? qsTr("夜间模式") : qsTr("日间模式")

                contentItem: Text {
                text: button1.text
                color: window.lightMode ? window.light : window.dark
                font: button1.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
             }

                background: Rectangle {
                   implicitWidth: 140
                    implicitHeight: 40
                    radius: 8
                    color: window.lightMode ? window.dark : window.light
                   }

                onClicked: window.lightMode = !window.lightMode
             }

             Button {
                id: button2
                text: qsTr("退出")

                contentItem: Text {
                  text: button2.text
                  color: window.lightMode ? window.light : window.dark
                  font: button2.font
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: 140
                    implicitHeight: 40
                    radius: 8
                    color: window.lightMode ? window.dark : window.light
                }
                    onClicked: Qt.exit(0)
             }
        }
    }
    }

}
