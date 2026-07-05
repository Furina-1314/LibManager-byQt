import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import LibManager

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
                                    // 调用底层桥接接口，0 对应 ErrorCode::SUCCESS
                                    let status = SystemBridge.loginReader(readerUsername.text, readerPassword.text)
                                    if (status === 0) {
                                        console.log("读者登录成功")
                                        debugLoader.active = true // 挂载 Dashboard
                                    } else {
                                        // TODO: 此处可扩充弹窗提示，目前使用后台输出
                                        console.log("登录受阻: 错误码 " + status)
                                    }        
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
                                        loginStack.currentIndex = 3 // 🚀 跳转至注册视图
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
                                    // 调用底层桥接接口
                                    let status = SystemBridge.loginAdmin(adminUsername.text, adminPassword.text)
                                    if (status === 0) {
                                        console.log("管理员登录成功")
                                        debugLoader.active = true // 挂载 Dashboard
                                    } else {
                                        console.log("登录受阻: 错误码 " + status)
                                    }                               
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
                    // 视图 3: 读者注册
                    Item {
                        ColumnLayout {
                            anchors.centerIn: parent
                            width: 360
                            spacing: 20 // 容纳4个输入框，略微缩减行距

                            TextField {
                                id: regReaderId
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55
                                font.pixelSize: 18
                                placeholderText: qsTr("设置读者账号 (8位数字)")
                                color: window.lightMode ? window.dark : window.light
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.dark : window.light
                                }
                            }

                            TextField {
                                id: regReaderName
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55
                                font.pixelSize: 18
                                placeholderText: qsTr("设置用户名")
                                color: window.lightMode ? window.dark : window.light
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.dark : window.light
                                }
                            }

                            TextField {
                                id: regReaderPassword
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55
                                font.pixelSize: 18
                                placeholderText: qsTr("设置密码 (至少8位)")
                                echoMode: TextInput.Password
                                color: window.lightMode ? window.dark : window.light
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.dark : window.light
                                }
                            }

                            TextField {
                                id: regReaderConfirmPassword
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55
                                font.pixelSize: 18
                                placeholderText: qsTr("确认密码")
                                echoMode: TextInput.Password
                                color: window.lightMode ? window.dark : window.light
                                background: Rectangle {
                                    radius: 5
                                    color: window.lightMode ? window.reallyLight : window.reallyDark
                                    border.color: window.lightMode ? window.dark : window.light
                                }
                            }

                            Button {
                                id: regSubmitBtn
                                Layout.fillWidth: true
                                Layout.preferredHeight: 55
                                text: qsTr("立即注册")
                                contentItem: Text {
                                    text: regSubmitBtn.text
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
                                    // 前置非空拦截
                                    if (regReaderId.text === "" || regReaderName.text === "" || regReaderPassword.text === "" || regReaderConfirmPassword.text === "") {
                                        messageDialog.messageText = "请完整填写所有注册信息";
                                        messageDialog.open();
                                        return;
                                    }

                                    // 调用桥接层
                                    let status = SystemBridge.registerReader(regReaderId.text, regReaderName.text, regReaderPassword.text, regReaderConfirmPassword.text)
                                    
                                    // ErrorCode::SUCCESS 对应 0
                                    if (status === 0) {
                                        messageDialog.messageText = "注册成功，请返回登录";
                                        messageDialog.open();
                                        
                                        // 清空表单数据
                                        regReaderId.text = "";
                                        regReaderName.text = "";
                                        regReaderPassword.text = "";
                                        regReaderConfirmPassword.text = "";
                                        
                                        // 跳转回读者登录视图
                                        loginStack.currentIndex = 1;
                                    }
                                }
                            }

                            Label {
                                text: qsTr("< 返回读者登录")
                                color: window.lightMode ? window.dark : window.light
                                font.pixelSize: 16
                                font.underline: true
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: loginStack.currentIndex = 1 // 🚀 返回读者登录视图
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
    Loader {
    id: debugLoader
    anchors.fill: parent
    source: "Dashboard.qml"
    active: false // 默认为 false，必须通过安全检验后激活
    z: 999       // 提高 Z 轴层级，确保覆盖底层的登录逻辑视图
    }
    // ==========================================
    // 🪧 全局消息弹窗
    // ==========================================
    Dialog {
        id: messageDialog
        anchors.centerIn: parent
        modal: true
        width: 320
        margins: 20
        // 移除默认的背景和标题栏，进行完全自定义
        background: Rectangle {
            color: window.lightMode ? window.reallyLight : window.reallyDark
            border.color: window.lightMode ? window.dark : window.light
            border.width: 1
            radius: 5
        }

        property string messageText: ""

        contentItem: ColumnLayout {
            spacing: 25

            Label {
                text: messageDialog.messageText
                color: window.lightMode ? window.dark : window.light
                font.pixelSize: 18
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: qsTr("确认")
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 45

                contentItem: Text {
                    text: parent.text
                    color: window.lightMode ? window.reallyLight : window.reallyDark
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 5
                    color: window.lightMode ? window.dark : window.light
                }
                onClicked: messageDialog.close()
            }
        }
    }
    // ==========================================
    // 📡 后端信号监听器
    // ==========================================
    Connections {
        target: SystemBridge
        
        // 监听 C++ 抛出的 loginError 信号
        function onLoginError(errorMsg) {
            messageDialog.messageText = errorMsg;
            messageDialog.open();
        }
    }
}