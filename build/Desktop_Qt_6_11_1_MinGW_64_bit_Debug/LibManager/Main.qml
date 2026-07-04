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
    visibility: Window.FullScreen
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

            // ======== 核心区域：使用 StackLayout 管理登录视图状态 ========
            Item {
                id: loginContainer
                anchors.fill: parent // 变更为填充父级区域，提供更宽广的居中计算空间

                StackLayout {
                    id: loginStack
                    anchors.fill: parent
                    currentIndex: 0 // 0: 按钮选择层, 1: 读者登录层, 2: 管理员登录层

                    // 视图 0: 初始按钮选择
                    Item { // 增加代理 Item 以实现内部 Layout 居中
                        ColumnLayout {
                            anchors.centerIn: parent // 严格保证垂直与水平居中
                            spacing: 30 // 增加行距

                            Button {
                                id: readerLoginBtn
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 260 // 增大尺寸
                                Layout.preferredHeight: 55
                                text: qsTr("读者登录")
                                contentItem: Text {
                                    text: readerLoginBtn.text
                                    color: window.lightMode ? window.reallyDark : window.reallyLight
                                    font.pixelSize: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.reallyDark : window.reallyLight
                                }
                                onClicked: loginStack.currentIndex = 1
                            }

                            Button {
                                id: adminLoginBtn
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 260 // 增大尺寸
                                Layout.preferredHeight: 55
                                text: qsTr("管理员登录")
                                contentItem: Text {
                                    text: adminLoginBtn.text
                                    color: window.lightMode ? window.reallyDark : window.reallyLight
                                    font.pixelSize: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.reallyDark : window.reallyLight
                                }
                                onClicked: loginStack.currentIndex = 2
                            }
                        }
                    }

                    // 视图 1: 读者登录
                    Item {
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: 360 // 为输入框提供宽敞的水平空间
                            spacing: 30 // 增加行距

                            TextField {
                                id: readerUsername
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55 // 增大尺寸
                                font.pixelSize: 18
                                placeholderText: qsTr("请输入读者账号")
                                color: window.lightMode ? window.dark : window.light
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.dark : window.light
                                }
                            }

                            TextField {
                                id: readerPassword
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55 // 增大尺寸
                                font.pixelSize: 18
                                placeholderText: qsTr("请输入密码")
                                echoMode: TextInput.Password // 核心属性：保证密码不可见
                                color: window.lightMode ? window.dark : window.light
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.dark : window.light
                                }
                            }

                            Button {
                                id: readerSubmitBtn
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55 // 增大尺寸
                                text: qsTr("登录")
                                contentItem: Text {
                                    text: readerSubmitBtn.text
                                    color: window.lightMode ? window.light : window.dark
                                    font.pixelSize: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.dark : window.light
                                }
                                onClicked: {
                                    // TODO: [接口预留] 在此处获取 readerUsername.text 与 readerPassword.text，调用后端读者登录验证逻辑
                                    console.log("执行读者登录逻辑")
                                }
                            }

                            // 返回选择与注册的区域
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: qsTr("< 返回")
                                    color: window.lightMode ? window.dark : window.light
                                    font.pixelSize: 16
                                    font.underline: true
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: loginStack.currentIndex = 0
                                    }
                                }
                                
                                Item { Layout.fillWidth: true } // 弹性占位符，将"注册"推向右下角

                                Label {
                                    text: qsTr("注册账号")
                                    color: window.lightMode ? window.dark : window.light
                                    font.pixelSize: 16
                                    font.underline: true
                                    Layout.alignment: Qt.AlignRight
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            // TODO: [接口预留] 在此处调用注册窗口的弹出或页面跳转逻辑
                                            console.log("执行注册逻辑")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 视图 2: 管理员登录 (无注册选项)
                    Item {
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: 360 // 为输入框提供宽敞的水平空间
                            spacing: 30 // 增加行距

                            TextField {
                                id: adminUsername
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55 // 增大尺寸
                                font.pixelSize: 18
                                placeholderText: qsTr("请输入管理员账号")
                                color: window.lightMode ? window.dark : window.light
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.dark : window.light
                                }
                            }

                            TextField {
                                id: adminPassword
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55 // 增大尺寸
                                font.pixelSize: 18
                                placeholderText: qsTr("请输入密码")
                                echoMode: TextInput.Password // 核心属性：保证密码不可见
                                color: window.lightMode ? window.dark : window.light
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.dark : window.light
                                }
                            }

                            Button {
                                id: adminSubmitBtn
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55 // 增大尺寸
                                text: qsTr("登录")
                                contentItem: Text {
                                    text: adminSubmitBtn.text
                                    color: window.lightMode ? window.light : window.dark
                                    font.pixelSize: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.dark : window.light
                                }
                                onClicked: {
                                    // TODO: [接口预留] 在此处获取 adminUsername.text 与 adminPassword.text，调用后端管理员登录验证逻辑
                                    console.log("执行管理员登录逻辑")
                                }
                            }
                            
                            Label {
                                text: qsTr("< 返回")
                                color: window.lightMode ? window.dark : window.light
                                font.pixelSize: 16
                                font.underline: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: loginStack.currentIndex = 0
                                }
                            }
                        }
                    }
                }
            }
            // ======== 核心区域结束 ========

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
                        radius: 5
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
                        radius: 5
                        color: window.lightMode ? window.dark : window.light
                    }
                    onClicked: Qt.exit(0)
                }
            }
        }
    }
}