pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import LibManager

Item {
    id: root
    
    // 提供静态几何尺寸以支持独立预览环境下的渲染
    width: 1280
    height: 960

    // ==========================================
    // 主题配色系统 (严格执行黑白二元色域)
    // ==========================================
    property bool lightMode: true
    
    property color bgPrimary: root.lightMode ? "#e7e7e7" : "#1f1f1f"
    property color bgSecondary: root.lightMode ? "#e0e0e0" : "#262626"
    property color textPrimary: root.lightMode ? "#1f1f1f" : "#e7e7e7"
    property color textSecondary: root.lightMode ? "#262626" : "#e0e0e0"

    // ==========================================
    // 🗃️ 视图状态与动态路由
    // ==========================================
    property string userName: SystemBridge.currentUserName 
    property bool isAdmin: SystemBridge.isAdmin
    property int currentTopMenu: 0    
    property int currentSubMenu: 0

    // 顶级菜单动态映射 (Admin 新增 流水管理)
    property var topMenuConfig: root.isAdmin ? 
        [ {title: qsTr("主页"), idx: 0}, {title: qsTr("图书业务"), idx: 1}, {title: qsTr("流水管理"), idx: 2}, {title: qsTr("个人信息"), idx: 3}, {title: qsTr("系统设置"), idx: 4} ] :
        [ {title: qsTr("主页"), idx: 0}, {title: qsTr("图书业务"), idx: 1}, {title: qsTr("个人信息"), idx: 3}, {title: qsTr("系统设置"), idx: 4} ]


    // ==========================================
    // 📊 数据模型与分页引擎
    // ==========================================
    property var historyListModel: []
    property int currentPage: 1
    // 表格单行基础高度设为75以支持文本折行
    property int rowHeight: 75
    // 强制执行5的整数倍分页装载
    property int tableCapacity: 5 

    property var paginatedData: {
        let p = currentPage;
        let limit = tableCapacity;
        return historyListModel.slice((p-1)*limit, p*limit);
    }

    property int totalPages: Math.max(1, Math.ceil(historyListModel.length / tableCapacity))


    Connections {
        target: root
        function onCurrentTopMenuChanged() { loadData() }
        function onCurrentSubMenuChanged() { loadData() }
    }

    function loadData() {
        if (root.currentTopMenu === 3 && root.currentSubMenu === 2 && !root.isAdmin) {
            root.historyListModel = SystemBridge.getBorrowingHistory();
            root.currentPage = 1;
        } else if (root.currentTopMenu === 2 && root.currentSubMenu === 0 && root.isAdmin) {
            root.historyListModel = SystemBridge.getAllLoanRecords();
            root.currentPage = 1;
        }
    }
    Rectangle {
        anchors.fill: parent
        color: root.bgPrimary

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // --------------------------------------
            // 顶部区域：欢迎语与一级导航
            // --------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 15

                Label {
                    text: qsTr("欢迎您，%1%2！").arg(root.isAdmin?"管理员 ":"").arg(root.userName)
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: root.textPrimary
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 30

                    Repeater {
                        model: root.topMenuConfig
                        
                        Button {
                            id: topMenuBtn
                            required property var modelData

                            text: topMenuBtn.modelData.title
                            font.pixelSize: 18
                            
                            contentItem: Text {
                                text: topMenuBtn.text
                                color: root.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: topMenuBtn.font.pixelSize
                                font.bold: root.currentTopMenu === topMenuBtn.modelData.idx
                                font.underline: root.currentTopMenu === topMenuBtn.modelData.idx
                            }
                            background: Item {} 
                            onClicked: {
                                root.currentSubMenu = 0; 
                                root.currentTopMenu = topMenuBtn.modelData.idx;
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.textPrimary
            }

            // --------------------------------------
            // 主体工作区
            // --------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // 左侧子菜单栏
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 200
                    color: root.bgPrimary
                    visible: root.currentTopMenu !== 0 

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        Layout.alignment: Qt.AlignTop

                        Repeater {
                            model: root.getSubMenuModel(root.currentTopMenu)
                            
                            Button {
                                id: sideMenuBtn
                                
                                required property int index
                                required property string modelData

                                Layout.fillWidth: true
                                text: sideMenuBtn.modelData
                                font.pixelSize: 16
                                
                                contentItem: Text {
                                    text: sideMenuBtn.text
                                    color: root.currentSubMenu === sideMenuBtn.index ? root.bgPrimary : root.textPrimary
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                    font.pixelSize: sideMenuBtn.font.pixelSize
                                }
                                background: Rectangle {
                                    color: root.currentSubMenu === sideMenuBtn.index ? root.textPrimary : "transparent"
                                    radius: 2
                                }
                                onClicked: root.currentSubMenu = sideMenuBtn.index
                            }
                        }
                        Item { Layout.fillHeight: true } 
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 1
                        height: parent.height
                        color: root.textPrimary
                    }
                }

                // 右侧视图渲染栈
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.bgPrimary

                    StackLayout {
                        anchors.fill: parent
                        anchors.margins: 30
                        currentIndex: root.currentTopMenu

                        // Page 0: 欢迎主页 (文字式扁平导航)
                        Item {
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 40

                                Label {
                                    text: qsTr("欢迎使用图书管理系统")
                                    font.pixelSize: 48
                                    font.weight: Font.Light
                                    color: root.textPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                ColumnLayout {
                                    spacing: 20
                                    Layout.alignment: Qt.AlignHCenter

                                    Repeater {
                                        model: [
                                            { title: qsTr("图书业务 >"), idx: 1 },
                                            { title: qsTr("个人信息 >"), idx: 2 },
                                            { title: qsTr("系统设置 >"), idx: 3 }
                                        ]

                                        Button {
                                            id: navBtn
                                            required property var modelData
                    
                                            Layout.preferredWidth: 300
                                            Layout.preferredHeight: 60
                    
                                            contentItem: Text {
                                                text: navBtn.modelData.title
                                                font.pixelSize: 24
                                                font.weight: Font.Normal
                                                color: root.textPrimary
                                                horizontalAlignment: Text.AlignLeft
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: 10
                                            }
                    
                                            background: Rectangle {
                                                color: "transparent" 
                                                border.color: navBtn.hovered ? root.textPrimary : "transparent"
                                                border.width: 1
                                            }
                    
                                            onClicked: {
                                                root.currentSubMenu = 0;
                                                root.currentTopMenu = navBtn.modelData.idx;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        // Page 1: 图书业务
                        Item {
                            Label {
                                text: root.getSafeSubMenuName(1, root.currentSubMenu) + qsTr(" 详情界面接入点")
                                font.pixelSize: 20
                                color: root.textSecondary
                                anchors.centerIn: parent
                            }
                        }

                        // --------------------------------------
                        // Page 2: 流水管理 (Admin)
                        // --------------------------------------
                        Item {
                            StackLayout {
                                anchors.fill: parent
                                currentIndex: root.currentSubMenu

                                // 2.0 流水查询
                                Item {
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 20
                                        spacing: 15

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Label { text: qsTr("流水查询"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary; Layout.fillWidth: true }
                                            Button {
                                                text: qsTr("高级检索")
                                                Layout.preferredWidth: 120; Layout.preferredHeight: 40
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: root.textPrimary; radius: 3 }
                                                onClicked: root.currentSubMenu = 1
                                            }
                                        }

                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

                                        // 表格容器与计算域
                                        Item {
                                            id: adminTableContainer
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            
                                            onHeightChanged: {
                                                let rawItems = Math.floor((height - 50) / root.rowHeight);
                                                root.tableCapacity = Math.max(5, rawItems - (rawItems % 5));
                                                root.currentPage = 1;
                                            }

                                            ColumnLayout {
                                                anchors.fill: parent
                                                spacing: 0

                                                // 表头
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 50
                                                    color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                        Label { text: qsTr("序号"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 40 }
                                                        Label { text: qsTr("借阅者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100 }
                                                        Label { text: qsTr("题名"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true; Layout.minimumWidth: 150 }
                                                        Label { text: qsTr("作者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100 }
                                                        Label { text: qsTr("单册状态"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80 }
                                                        Label { text: qsTr("借阅日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                        Label { text: qsTr("到期日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                    }
                                                }

                                                // 表格数据体
                                                ListView {
                                                    Layout.fillWidth: true; Layout.fillHeight: true
                                                    clip: true; interactive: false // 严禁出现滚动条
                                                    model: root.paginatedData
                                                    delegate: Rectangle {
                                                        width: ListView.view.width; height: root.rowHeight
                                                        color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a")
                                                        border.color: root.bgSecondary; border.width: 1
                                                        RowLayout {
                                                            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                            Label { text: (root.currentPage - 1) * root.tableCapacity + index + 1; color: root.textSecondary; Layout.preferredWidth: 40 }
                                                            Label { text: modelData.borrowerId; color: root.textSecondary; Layout.preferredWidth: 100 }
                                                            Label { text: modelData.title; color: root.textPrimary; font.weight: Font.Bold; Layout.fillWidth: true; Layout.minimumWidth: 150; wrapMode: Text.Wrap; elide: Text.ElideRight; maximumLineCount: 2 }
                                                            Label { text: modelData.author; color: root.textSecondary; Layout.preferredWidth: 100; elide: Text.ElideRight }
                                                            Label { text: modelData.status; color: modelData.status === "已逾期" ? "#b91c1c" : (modelData.status === "未归还" ? "#ca8a04" : "#16a34a"); font.weight: Font.Bold; Layout.preferredWidth: 80 }
                                                            Label { text: modelData.borrowDate; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                            Label { text: modelData.dueDate; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // 底部分页控制器
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20
                                            Button { text: "< 上一页"; enabled: root.currentPage > 1; onClicked: root.currentPage--; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPage).arg(root.totalPages); font.pixelSize: 16; color: root.textPrimary }
                                            Button { text: "下一页 >"; enabled: root.currentPage < root.totalPages; onClicked: root.currentPage++; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("跳转至:"); color: root.textSecondary }
                                            TextField { id: adminJump; Layout.preferredWidth: 50; validator: IntValidator { bottom: 1; top: root.totalPages } }
                                            Button { text: "Go"; onClicked: { let p = parseInt(adminJump.text); if(p >= 1 && p <= root.totalPages) root.currentPage = p; } }
                                        }
                                    }
                                }

                                // 2.1 高级检索
                                Item {
                                    Label { text: qsTr("高级条件检索业务装载点"); font.pixelSize: 20; color: root.textSecondary; anchors.centerIn: parent }
                                }
                            }
                        }

                        // --------------------------------------
                        // Page 3: 个人信息
                        // --------------------------------------
                        Item {
                            StackLayout {
                                anchors.fill: parent
                                currentIndex: root.currentSubMenu

                                // 3.0 账户资料
                                Item {
                                    ColumnLayout {
                                        anchors.margins: 40; spacing: 25
                                        Label { text: qsTr("账户资料"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

                                        GridLayout {
                                            columns: 2; rowSpacing: 20; columnSpacing: 40
                                            Label { text: qsTr("统一身份识别码 (ID):"); font.pixelSize: 18; color: root.textSecondary }
                                            Label { text: SystemBridge.currentUserId; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                            Label { text: qsTr("当前用户名:"); font.pixelSize: 18; color: root.textSecondary }
                                            Label { text: SystemBridge.currentUserName; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                            Label { text: qsTr("权限分配状态:"); font.pixelSize: 18; color: root.textSecondary }
                                            Label { text: SystemBridge.currentAuthType; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                            Label { text: qsTr("最大在借量上限:"); font.pixelSize: 18; color: root.textSecondary; visible: !root.isAdmin }
                                            Label { text: SystemBridge.currentBorrowLimit + qsTr(" 册"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary; visible: !root.isAdmin }
                                        }
                                    }
                                }

                                // 3.1 修改信息 (由于 Admin 被隐藏，此页仅 Reader 触发)
                                Item { /* ... 此处保留上一轮给您的 修改信息(TextField) 代码即可 ... */ }

                                // 3.2 借阅历史 (Reader)
                                Item {
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 20; spacing: 15

                                        Label { text: qsTr("借阅历史"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        
                                        // 扁平化指标看板
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 100; color: "transparent"
                                            RowLayout {
                                                anchors.fill: parent; spacing: 50 
                                                ColumnLayout {
                                                    spacing: 5
                                                    RowLayout {
                                                        spacing: 8
                                                        Label { text: SystemBridge.currentBorrowedCount; font.pixelSize: 42; font.weight: Font.Bold; color: root.textPrimary }
                                                        Label { text: qsTr("册"); font.pixelSize: 16; color: root.textSecondary; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 6 }
                                                    }
                                                    Label { text: qsTr("当前在借图书"); font.pixelSize: 22; font.weight: Font.Bold; color: root.textPrimary }
                                                }
                                                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 50; color: root.textSecondary }
                                                ColumnLayout {
                                                    spacing: 5
                                                    RowLayout {
                                                        spacing: 8
                                                        Label { text: SystemBridge.currentOverdueCount; font.pixelSize: 42; font.weight: Font.Bold; color: root.textPrimary }
                                                        Label { text: qsTr("册"); font.pixelSize: 16; color: root.textSecondary; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 6 }
                                                    }
                                                    Label { text: qsTr("当前逾期图书"); font.pixelSize: 22; font.weight: Font.Bold; color: root.textPrimary }
                                                }
                                                Item { Layout.fillWidth: true } 
                                            }
                                        }

                                        Label {
                                            text: qsTr("提示：当前界面提供您的全周期图书借阅明细。请严格遵循各单册的“到期日期”按时归还，以避免超期违约金的产生。")
                                            font.pixelSize: 14; color: root.textSecondary; wrapMode: Text.Wrap; Layout.fillWidth: true
                                        }

                                        // 表格容器与分页计算
                                        Item {
                                            id: readerTableContainer
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            
                                            onHeightChanged: {
                                                let rawItems = Math.floor((height - 50) / root.rowHeight);
                                                root.tableCapacity = Math.max(5, rawItems - (rawItems % 5));
                                                root.currentPage = 1;
                                            }

                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 0

                                                Rectangle {
                                                    Layout.fillWidth: true; height: 50
                                                    color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                        Label { text: qsTr("序号"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 40 }
                                                        Label { text: qsTr("题名"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true; Layout.minimumWidth: 150 }
                                                        Label { text: qsTr("作者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100 }
                                                        Label { text: qsTr("单册状态"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80 }
                                                        Label { text: qsTr("借阅日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                        Label { text: qsTr("到期日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                    }
                                                }

                                                ListView {
                                                    Layout.fillWidth: true; Layout.fillHeight: true
                                                    clip: true; interactive: false
                                                    model: root.paginatedData
                                                    delegate: Rectangle {
                                                        width: ListView.view.width; height: root.rowHeight
                                                        color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a")
                                                        border.color: root.bgSecondary; border.width: 1
                                                        RowLayout {
                                                            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                            Label { text: (root.currentPage - 1) * root.tableCapacity + index + 1; color: root.textSecondary; Layout.preferredWidth: 40 }
                                                            Label { text: modelData.title; color: root.textPrimary; font.weight: Font.Bold; Layout.fillWidth: true; Layout.minimumWidth: 150; wrapMode: Text.Wrap; elide: Text.ElideRight; maximumLineCount: 2 }
                                                            Label { text: modelData.author; color: root.textSecondary; Layout.preferredWidth: 100; elide: Text.ElideRight }
                                                            Label { text: modelData.status; color: modelData.status === "已逾期" ? "#b91c1c" : (modelData.status === "未归还" ? "#ca8a04" : "#16a34a"); font.weight: Font.Bold; Layout.preferredWidth: 80 }
                                                            Label { text: modelData.borrowDate; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                            Label { text: modelData.dueDate; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // 底部分页控制器
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20
                                            Button { text: "< 上一页"; enabled: root.currentPage > 1; onClicked: root.currentPage--; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPage).arg(root.totalPages); font.pixelSize: 16; color: root.textPrimary }
                                            Button { text: "下一页 >"; enabled: root.currentPage < root.totalPages; onClicked: root.currentPage++; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("跳转至:"); color: root.textSecondary }
                                            TextField { id: readerJump; Layout.preferredWidth: 50; validator: IntValidator { bottom: 1; top: root.totalPages } }
                                            Button { text: "Go"; onClicked: { let p = parseInt(readerJump.text); if(p >= 1 && p <= root.totalPages) root.currentPage = p; } }
                                        }
                                    }
                                }
                            }
                        }
                        // Page 4: 系统设置
                        Item {
                            StackLayout {
                                anchors.fill: parent
                                currentIndex: root.currentSubMenu

                                // --------------------------------------
                                // 3.0 界面偏好 (保留原有逻辑)
                                // --------------------------------------
                                Item {
                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.margins: 40 
                                        spacing: 20

                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 6
                                            Label { text: qsTr("界面偏好"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                            Rectangle { Layout.preferredWidth: 500; height: 1; color: root.textPrimary }
                                        }

                                        RowLayout {
                                            spacing: 20; Layout.topMargin: 10
                                            Label { text: qsTr("界面主题"); font.pixelSize: 18; color: root.textPrimary }
                                            Button {
                                                text: root.lightMode ? qsTr("切换至黑暗模式") : qsTr("切换至明亮模式")
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: root.textPrimary; radius: 3; implicitWidth: 140; implicitHeight: 35 }
                                                onClicked: root.lightMode = !root.lightMode
                                            }
                                        }
                                        RowLayout {
                                            spacing: 20
                                            Label { text: qsTr("系统语言"); font.pixelSize: 18; color: root.textPrimary }
                                            Label { text: qsTr("简体中文"); font.pixelSize: 18; color: root.textSecondary }
                                        }

                                        Item { Layout.preferredHeight: 50; Layout.fillWidth: true } // 隔离层

                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 6
                                            Label { text: qsTr("关于"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                            Rectangle { Layout.preferredWidth: 500; height: 1; color: root.textPrimary }
                                        }
                                        RowLayout {
                                            spacing: 20; Layout.topMargin: 10
                                            Label { text: qsTr("系统版本"); font.pixelSize: 18; color: root.textPrimary }
                                            Label { text: qsTr("0.1.0 稳定版"); font.pixelSize: 18; color: root.textSecondary }
                                        }
                                    }
                                }

                                // --------------------------------------
                                // 3.1 数据库连接状态
                                // --------------------------------------
                                Item {
                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.margins: 40 
                                        spacing: 20

                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 6
                                            Label { text: qsTr("数据库连接状态"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                            Rectangle { Layout.preferredWidth: 600; height: 1; color: root.textPrimary }
                                        }

                                        GridLayout {
                                            Layout.topMargin: 15
                                            columns: 2; rowSpacing: 25; columnSpacing: 40
                                            
                                            Label { text: qsTr("底层驱动引擎:"); font.pixelSize: 18; color: root.textSecondary }
                                            Label { text: "QSQLITE"; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }

                                            Label { text: qsTr("活动连接句柄:"); font.pixelSize: 18; color: root.textSecondary }
                                            Label { text: "qt_sql_default_connection"; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }

                                            Label { text: qsTr("本地文件映射:"); font.pixelSize: 18; color: root.textSecondary }
                                            Label { text: "LibManager.db"; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }

                                            Label { text: qsTr("系统连接心跳:"); font.pixelSize: 18; color: root.textSecondary }
                                            RowLayout {
                                                spacing: 10
                                                Rectangle { width: 12; height: 12; radius: 6; color: "#16a34a" } // 运转绿
                                                Label { text: qsTr("Active (连接正常，读写授权)"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                            }
                                        }
                                    }
                                }

                                // --------------------------------------
                                // 3.2 退出系统 🚪
                                // --------------------------------------
                                Item {
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 35

                                        Label { text: "🚪"; font.pixelSize: 64; Layout.alignment: Qt.AlignHCenter }
                                        
                                        Label { 
                                            text: qsTr("您正准备注销当前安全会话\n即将清理并阻断本地内存中的凭证缓存。")
                                            font.pixelSize: 22; color: root.textPrimary; horizontalAlignment: Text.AlignHCenter
                                            Layout.alignment: Qt.AlignHCenter 
                                        }

                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter
                                            spacing: 40; Layout.topMargin: 20

                                            Button {
                                                text: qsTr("安全注销 (回主页)")
                                                Layout.preferredWidth: 200; Layout.preferredHeight: 50
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: root.textPrimary; radius: 5 }
                                                onClicked: {
                                                    SystemBridge.logout();
                                                    // 回退并销毁当前 Dashboard 实例
                                                    if (typeof debugLoader !== "undefined") {
                                                        debugLoader.active = false; 
                                                    }
                                                }
                                            }

                                            Button {
                                                text: qsTr("终止程序进程")
                                                Layout.preferredWidth: 200; Layout.preferredHeight: 50
                                                contentItem: Text { text: parent.text; color: root.textPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: "transparent"; border.color: root.textPrimary; border.width: 1; radius: 5 }
                                                onClicked: {
                                                    SystemBridge.logout();
                                                    Qt.exit(0);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 业务逻辑与安全断言函数
    // ==========================================
    function getSubMenuModel(topMenuIdx) {
        switch(topMenuIdx) {
            case 1: return [qsTr("图书检索"), qsTr("在借馆藏"), qsTr("借阅历史")];
            case 2: return [qsTr("流水查询"), qsTr("高级检索")]; // 仅 Admin 可见
            case 3: return root.isAdmin ? [qsTr("账户资料")] : [qsTr("账户资料"), qsTr("修改信息"), qsTr("借阅历史")]; // 权限隔离
            case 4: return [qsTr("界面偏好"), qsTr("数据库连接状态"), qsTr("退出系统")];
            default: return [];
        }
    }
    function getSafeSubMenuName(topIdx, subIdx) {
        let arr = root.getSubMenuModel(topIdx);
        if (subIdx >= 0 && subIdx < arr.length) {
            return arr[subIdx];
        }
        return qsTr("正在解析节点状态...");
    }
}