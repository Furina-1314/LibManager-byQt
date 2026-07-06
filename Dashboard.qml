pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import LibManager

Item {
    id: root
    width: 1280
    height: 960

    property bool lightMode: true
    property color bgPrimary: root.lightMode ? "#e7e7e7" : "#1f1f1f"
    property color bgSecondary: root.lightMode ? "#e0e0e0" : "#262626"
    property color textPrimary: root.lightMode ? "#1f1f1f" : "#e7e7e7"
    property color textSecondary: root.lightMode ? "#262626" : "#e0e0e0"

    property string userName: SystemBridge.currentUserName 
    property bool isAdmin: SystemBridge.isAdmin
    property int currentTopMenu: 0    
    property int currentSubMenu: 0

    property var topMenuConfig: [
        {title: qsTr("主页"), idx: 0},
        {title: qsTr("图书业务"), idx: 1},
        {title: qsTr("借阅管理"), idx: 2},
        {title: qsTr("个人信息"), idx: 3},
        {title: qsTr("系统设置"), idx: 4}
    ]

    function getSubMenuModel(topMenuIdx) {
        switch(topMenuIdx) {
            case 1: return root.isAdmin ? [qsTr("图书检索"), qsTr("热门图书"), qsTr("图书管理")] : [qsTr("图书检索"), qsTr("热门图书")];
            case 2: return root.isAdmin ? [qsTr("流水查询"), qsTr("高级检索")] : [qsTr("借阅历史"), qsTr("高级检索"), qsTr("借阅统计")];
            case 3: return root.isAdmin ? [qsTr("账户资料")] : [qsTr("账户资料"), qsTr("修改信息")];
            case 4: return [qsTr("界面偏好"), qsTr("数据库连接状态"), qsTr("退出系统")];
            default: return [];
        }
    }

    // ==========================================
    // 📊 数据模型与多轨分页引擎
    // ==========================================
    property int rowHeight: 65
    property int tableCapacity: 5 

    property var listModelA: [] // 通用列表模型 (借阅历史/流水查询/图书检索)
    property int currentPageA: 1
    property var paginatedDataA: { let p = currentPageA; let limit = tableCapacity; return listModelA.slice((p-1)*limit, p*limit); }
    property int totalPagesA: Math.max(1, Math.ceil(listModelA.length / tableCapacity))

    property var listModelB: [] // 高级检索/图书详情内联单册模型
    property int currentPageB: 1
    property var paginatedDataB: { let p = currentPageB; let limit = tableCapacity; return listModelB.slice((p-1)*limit, p*limit); }
    property int totalPagesB: Math.max(1, Math.ceil(listModelB.length / tableCapacity))

    // 局部视图状态
    property int bookSearchViewIdx: 0 // 0:列表 1:详情
    property var currentBookDetails: ({})

    Connections {
        target: root
        function onCurrentTopMenuChanged() { loadData() }
        function onCurrentSubMenuChanged() { loadData() }
    }

    function loadData() {
        // 重置内部状态
        root.bookSearchViewIdx = 0;
        
        // 借阅管理 -> 流水/历史
        if (root.currentTopMenu === 2 && root.currentSubMenu === 0) {
            root.listModelA = root.isAdmin ? SystemBridge.getAllLoanRecords() : SystemBridge.getBorrowingHistory();
            root.currentPageA = 1;
        }
        // 图书业务 -> 热门图书
        else if (root.currentTopMenu === 1 && root.currentSubMenu === 1) {
            root.listModelA = SystemBridge.getPopularBooks();
            root.currentPageA = 1;
        }
        // 图书业务 -> 图书检索 (初始化为空)
        else if (root.currentTopMenu === 1 && root.currentSubMenu === 0) {
            root.listModelA = []; root.currentPageA = 1;
        }
    }

    Rectangle {
        anchors.fill: parent; color: root.bgPrimary

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // --------------------------------------
            // 顶部导航栏
            // --------------------------------------
            ColumnLayout {
                Layout.fillWidth: true; Layout.margins: 20; spacing: 15
                Label {
                    text: qsTr("欢迎您，%1%2").arg(root.isAdmin?"管理员 ":"").arg(root.userName)
                    font.pixelSize: 28; font.weight: Font.Bold; color: root.textPrimary
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 30
                    Repeater {
                        model: root.topMenuConfig
                        Button {
                            required property var modelData
                            text: modelData.title; font.pixelSize: 18
                            contentItem: Text { text: parent.text; color: root.textPrimary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 18; font.bold: root.currentTopMenu === modelData.idx; font.underline: root.currentTopMenu === modelData.idx }
                            background: Item {} 
                            onClicked: { root.currentSubMenu = 0; root.currentTopMenu = modelData.idx; }
                        }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

            // --------------------------------------
            // 主体区域
            // --------------------------------------
            RowLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

                // 左侧菜单
                Rectangle {
                    Layout.fillHeight: true; Layout.preferredWidth: 200; color: root.bgPrimary
                    visible: root.currentTopMenu !== 0 
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 15; spacing: 10; Layout.alignment: Qt.AlignTop
                        Repeater {
                            model: root.getSubMenuModel(root.currentTopMenu)
                            Button {
                                required property int index
                                required property string modelData
                                Layout.fillWidth: true; text: modelData; font.pixelSize: 16
                                contentItem: Text { text: parent.text; color: root.currentSubMenu === index ? root.bgPrimary : root.textPrimary; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; leftPadding: 10; font.pixelSize: 16 }
                                background: Rectangle { color: root.currentSubMenu === index ? root.textPrimary : "transparent"; radius: 2 }
                                onClicked: root.currentSubMenu = index
                            }
                        }
                        Item { Layout.fillHeight: true } 
                    }
                    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.textPrimary }
                }

                // 右侧视图栈
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; color: root.bgPrimary

                    StackLayout {
                        anchors.fill: parent; anchors.margins: 30
                        currentIndex: root.currentTopMenu

                        // ==========================================
                        // Page 0: 主页
                        // ==========================================
                        Item {
                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 40
                                Label { text: qsTr("欢迎使用图书管理系统"); font.pixelSize: 48; font.weight: Font.Light; color: root.textPrimary; Layout.alignment: Qt.AlignHCenter }
                                ColumnLayout {
                                    spacing: 20; Layout.alignment: Qt.AlignHCenter
                                    Repeater {
                                        model: root.topMenuConfig.slice(1) // 剔除主页本身
                                        Button {
                                            required property var modelData
                                            Layout.preferredWidth: 300; Layout.preferredHeight: 60
                                            contentItem: Text { text: modelData.title + " >"; font.pixelSize: 24; color: root.textPrimary; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
                                            background: Rectangle { color: "transparent"; border.color: parent.hovered ? root.textPrimary : "transparent"; border.width: 1 }
                                            onClicked: { root.currentSubMenu = 0; root.currentTopMenu = modelData.idx; }
                                        }
                                    }
                                }
                            }
                        }

                        // ==========================================
                        // Page 1: 图书业务
                        // ==========================================
                        Item {
                            StackLayout {
                                anchors.fill: parent
                                currentIndex: root.currentSubMenu

                                // 1.0 图书检索
                                Item {
                                    StackLayout {
                                        anchors.fill: parent
                                        currentIndex: root.bookSearchViewIdx

                                        // 子状态0：搜索与列表
                                        Item {
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 15
                                                Label { text: qsTr("图书检索"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 15
                                                    TextField { id: titleSearchInput; Layout.fillWidth: true; Layout.preferredHeight: 45; placeholderText: qsTr("输入图书标题或关键词"); font.pixelSize: 16; color: root.textPrimary; background: Rectangle { border.color: root.textPrimary; border.width: 1; color: "transparent" } }
                                                    Button {
                                                        text: qsTr("检索")
                                                        Layout.preferredWidth: 100; Layout.preferredHeight: 45
                                                        contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                        background: Rectangle { color: root.textPrimary; radius: 2 }
                                                        onClicked: { root.listModelA = SystemBridge.searchBooks(titleSearchInput.text); root.currentPageA = 1; }
                                                    }
                                                }
                                                Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                                
                                                // 图书结果列表 (方块排版)
                                                Item {
                                                    Layout.fillWidth: true; Layout.fillHeight: true
                                                    onHeightChanged: { let r = Math.floor(height / 100); root.tableCapacity = Math.max(5, r - (r%5)); root.currentPageA = 1; }
                                                    ListView {
                                                        anchors.fill: parent; clip: true; interactive: false; model: root.paginatedDataA; spacing: 10
                                                        delegate: Rectangle {
                                                            width: ListView.view.width; height: 90; color: "transparent"; border.color: root.textSecondary; border.width: 1
                                                            RowLayout {
                                                                anchors.fill: parent; anchors.margins: 15; spacing: 20
                                                                ColumnLayout {
                                                                    Layout.fillWidth: true; spacing: 5
                                                                    Label { text: modelData.title; font.pixelSize: 20; font.weight: Font.Bold; color: root.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                                                                    Label { text: qsTr("作者: %1 | 出版社: %2 | 出版年份: %3").arg(modelData.author).arg(modelData.press).arg(modelData.pubYear); font.pixelSize: 14; color: root.textSecondary; elide: Text.ElideRight; Layout.fillWidth: true }
                                                                }
                                                                Button {
                                                                    text: qsTr("查看详情")
                                                                    Layout.preferredWidth: 100; Layout.preferredHeight: 40; Layout.alignment: Qt.AlignVCenter
                                                                    contentItem: Text { text: parent.text; color: root.textPrimary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                    background: Rectangle { color: "transparent"; border.color: root.textPrimary; border.width: 1 }
                                                                    onClicked: {
                                                                        root.currentBookDetails = SystemBridge.getBookDetails(modelData.isbn);
                                                                        root.listModelB = root.currentBookDetails.volumes || [];
                                                                        root.currentPageB = 1;
                                                                        root.bookSearchViewIdx = 1;
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                // 底部分页
                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter; spacing: 20
                                                    Button { text: qsTr("上一页"); enabled: root.currentPageA > 1; onClicked: root.currentPageA--; background: Rectangle { color: "transparent" } }
                                                    Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageA).arg(root.totalPagesA); font.pixelSize: 16; color: root.textPrimary }
                                                    Button { text: qsTr("下一页"); enabled: root.currentPageA < root.totalPagesA; onClicked: root.currentPageA++; background: Rectangle { color: "transparent" } }
                                                    TextField { id: jumpA; Layout.preferredWidth: 50; validator: IntValidator { bottom: 1; top: root.totalPagesA } }
                                                    Button { text: "Go"; onClicked: { let p = parseInt(jumpA.text); if(p >= 1 && p <= root.totalPagesA) root.currentPageA = p; } }
                                                }
                                            }
                                        }

                                        // 子状态1：单本图书详情与单册列表
                                        Item {
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 15
                                                Label { text: qsTr("< 返回检索列表"); font.pixelSize: 16; font.underline: true; color: root.textSecondary; MouseArea { anchors.fill: parent; onClicked: root.bookSearchViewIdx = 0 } }
                                                Label { text: root.currentBookDetails.title || ""; font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary; wrapMode: Text.Wrap; Layout.fillWidth: true }
                                                Label { text: qsTr("作者: %1 | 出版社: %2 | 出版年份: %3 | ISBN: %4").arg(root.currentBookDetails.author || "").arg(root.currentBookDetails.press || "").arg(root.currentBookDetails.pubYear || "").arg(root.currentBookDetails.isbn || ""); font.pixelSize: 16; color: root.textSecondary; wrapMode: Text.Wrap; Layout.fillWidth: true }
                                                Label { text: root.currentBookDetails.intro || qsTr("暂无简介"); font.pixelSize: 14; color: root.textPrimary; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; Layout.fillWidth: true }
                                                Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

                                                // 单册表格渲染
                                                Item {
                                                    Layout.fillWidth: true; Layout.fillHeight: true
                                                    onHeightChanged: { let r = Math.floor((height - 50) / root.rowHeight); root.tableCapacity = Math.max(5, r - (r%5)); root.currentPageB = 1; }
                                                    ColumnLayout {
                                                        anchors.fill: parent; spacing: 0
                                                        Rectangle {
                                                            Layout.fillWidth: true; height: 50; color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                            RowLayout {
                                                                anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                                Label { text: qsTr("操作"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter }
                                                                Label { text: qsTr("单册条码"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 150 }
                                                                Label { text: qsTr("状态"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100 }
                                                                Label { text: qsTr("馆藏位置"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true }
                                                            }
                                                        }
                                                        ListView {
                                                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; interactive: false; model: root.paginatedDataB
                                                            delegate: Rectangle {
                                                                width: ListView.view.width; height: root.rowHeight; color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a"); border.color: root.bgSecondary; border.width: 1
                                                                RowLayout {
                                                                    anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                                    Button {
                                                                        text: qsTr("借阅")
                                                                        Layout.preferredWidth: 80; Layout.preferredHeight: 35; enabled: modelData.isAvailable && !root.isAdmin
                                                                        contentItem: Text { text: parent.text; color: parent.enabled ? root.bgPrimary : root.textSecondary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                        background: Rectangle { color: parent.enabled ? root.textPrimary : "transparent"; border.color: root.textPrimary; border.width: parent.enabled ? 0 : 1; radius: 2 }
                                                                        onClicked: {
                                                                            let st = SystemBridge.borrowVolume(root.currentBookDetails.isbn, modelData.volId);
                                                                            if(st === 0) {
                                                                                root.currentBookDetails = SystemBridge.getBookDetails(root.currentBookDetails.isbn);
                                                                                root.listModelB = root.currentBookDetails.volumes || [];
                                                                            }
                                                                        }
                                                                    }
                                                                    Label { text: modelData.volId; color: root.textPrimary; Layout.preferredWidth: 150; font.weight: Font.Bold }
                                                                    Label { text: modelData.status; color: modelData.isAvailable ? "#16a34a" : root.textSecondary; Layout.preferredWidth: 100 }
                                                                    Label { text: modelData.location; color: root.textSecondary; Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 2 }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter; spacing: 20
                                                    Button { text: qsTr("上一页"); enabled: root.currentPageB > 1; onClicked: root.currentPageB--; background: Rectangle { color: "transparent" } }
                                                    Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageB).arg(root.totalPagesB); font.pixelSize: 16; color: root.textPrimary }
                                                    Button { text: qsTr("下一页"); enabled: root.currentPageB < root.totalPagesB; onClicked: root.currentPageB++; background: Rectangle { color: "transparent" } }
                                                }
                                            }
                                        }
                                    }
                                }

                                // 1.1 热门图书
                                Item {
                                    ColumnLayout {
                                        anchors.fill: parent; spacing: 15
                                        Label { text: qsTr("热门图书"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                        Item {
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            onHeightChanged: { let r = Math.floor(height / 100); root.tableCapacity = Math.max(5, r - (r%5)); root.currentPageA = 1; }
                                            ListView {
                                                anchors.fill: parent; clip: true; interactive: false; model: root.paginatedDataA; spacing: 10
                                                delegate: Rectangle {
                                                    width: ListView.view.width; height: 90; color: "transparent"; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.margins: 15; spacing: 20
                                                        ColumnLayout {
                                                            Layout.fillWidth: true; spacing: 5
                                                            Label { text: modelData.title; font.pixelSize: 20; font.weight: Font.Bold; color: root.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                                                            Label { text: qsTr("作者: %1 | 累计借阅: %2 次").arg(modelData.author).arg(modelData.borrowCount); font.pixelSize: 14; color: root.textSecondary; Layout.fillWidth: true }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20
                                            Button { text: qsTr("上一页"); enabled: root.currentPageA > 1; onClicked: root.currentPageA--; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageA).arg(root.totalPagesA); font.pixelSize: 16; color: root.textPrimary }
                                            Button { text: qsTr("下一页"); enabled: root.currentPageA < root.totalPagesA; onClicked: root.currentPageA++; background: Rectangle { color: "transparent" } }
                                        }
                                    }
                                }

                                // 1.2 图书管理 (Admin)
                                Item {
                                    Label { text: qsTr("图书管理与录入维护操作界面装载点"); font.pixelSize: 20; color: root.textSecondary; anchors.centerIn: parent }
                                }
                            }
                        }

                        // ==========================================
                        // Page 2: 借阅管理
                        // ==========================================
                        Item {
                            StackLayout {
                                anchors.fill: parent
                                currentIndex: root.currentSubMenu

                                // 2.0 流水查询 (Admin) / 借阅历史 (Reader)
                                Item {
                                    ColumnLayout {
                                        anchors.fill: parent; spacing: 15
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Label { text: root.isAdmin ? qsTr("流水查询") : qsTr("借阅历史"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary; Layout.fillWidth: true }
                                            Button {
                                                text: qsTr("高级检索")
                                                Layout.preferredWidth: 120; Layout.preferredHeight: 40
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: root.textPrimary; radius: 3 }
                                                onClicked: root.currentSubMenu = 1
                                            }
                                        }
                                        // Reader 独有的指标看板
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 80; color: "transparent"
                                            visible: !root.isAdmin
                                            RowLayout {
                                                anchors.fill: parent; spacing: 50 
                                                ColumnLayout {
                                                    spacing: 5
                                                    RowLayout {
                                                        spacing: 8
                                                        Label { text: SystemBridge.currentBorrowedCount; font.pixelSize: 42; font.weight: Font.Bold; color: root.textPrimary }
                                                        Label { text: qsTr("册"); font.pixelSize: 16; color: root.textSecondary; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 6 }
                                                    }
                                                    Label { text: qsTr("当前在借图书"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                                }
                                                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 40; color: root.textSecondary }
                                                ColumnLayout {
                                                    spacing: 5
                                                    RowLayout {
                                                        spacing: 8
                                                        Label { text: SystemBridge.currentOverdueCount; font.pixelSize: 42; font.weight: Font.Bold; color: root.textPrimary }
                                                        Label { text: qsTr("册"); font.pixelSize: 16; color: root.textSecondary; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 6 }
                                                    }
                                                    Label { text: qsTr("当前逾期图书"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                                }
                                                Item { Layout.fillWidth: true } 
                                            }
                                        }

                                        Label { text: qsTr("提示：请严格遵循各单册的“到期日期”按时归还，以避免超期违约金的产生。"); font.pixelSize: 14; color: root.textSecondary; wrapMode: Text.Wrap; Layout.fillWidth: true }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

                                        // 表格容器与分页计算
                                        Item {
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            onHeightChanged: { let r = Math.floor((height - 50) / root.rowHeight); root.tableCapacity = Math.max(5, r - (r%5)); root.currentPageA = 1; }
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 0
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 50; color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                        Label { text: qsTr("序号"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                                                        Label { text: qsTr("借阅者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100; visible: root.isAdmin }
                                                        Label { text: qsTr("题名"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true; Layout.minimumWidth: 150 }
                                                        Label { text: qsTr("作者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100 }
                                                        Label { text: qsTr("单册状态"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80 }
                                                        Label { text: qsTr("借阅日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                        Label { text: qsTr("到期日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                    }
                                                }
                                                ListView {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; interactive: false; model: root.paginatedDataA
                                                    delegate: Rectangle {
                                                        width: ListView.view.width; height: root.rowHeight; color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a"); border.color: root.bgSecondary; border.width: 1
                                                        RowLayout {
                                                            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                            Label { text: (root.currentPageA - 1) * root.tableCapacity + index + 1; color: root.textSecondary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                                                            Label { text: modelData.borrowerId; color: root.textSecondary; Layout.preferredWidth: 100; visible: root.isAdmin }
                                                            Label { text: modelData.title; color: root.textPrimary; font.weight: Font.Bold; Layout.fillWidth: true; Layout.minimumWidth: 150; wrapMode: Text.Wrap; elide: Text.ElideRight; maximumLineCount: 2 }
                                                            Label { text: modelData.author; color: root.textSecondary; Layout.preferredWidth: 100; elide: Text.ElideRight }
                                                            Label { text: modelData.status; color: modelData.status === "已逾期" ? root.textPrimary : root.textSecondary; font.weight: modelData.status === "已逾期" ? Font.Bold : Font.Normal; Layout.preferredWidth: 80 }
                                                            Label { text: modelData.borrowDate; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                            Label { text: modelData.dueDate; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20
                                            Button { text: qsTr("上一页"); enabled: root.currentPageA > 1; onClicked: root.currentPageA--; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageA).arg(root.totalPagesA); font.pixelSize: 16; color: root.textPrimary }
                                            Button { text: qsTr("下一页"); enabled: root.currentPageA < root.totalPagesA; onClicked: root.currentPageA++; background: Rectangle { color: "transparent" } }
                                            TextField { id: jumpL; Layout.preferredWidth: 50; validator: IntValidator { bottom: 1; top: root.totalPagesA } }
                                            Button { text: "Go"; onClicked: { let p = parseInt(jumpL.text); if(p >= 1 && p <= root.totalPagesA) root.currentPageA = p; } }
                                        }
                                    }
                                }

                                // 2.1 高级检索
                                Item {
                                    ColumnLayout {
                                        anchors.fill: parent; spacing: 15
                                        Label { text: qsTr("高级检索"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

                                        GridLayout {
                                            columns: 4; rowSpacing: 15; columnSpacing: 20
                                            Label { text: qsTr("ISBN:"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sIsbn; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                            Label { text: qsTr("单册条码 (VolID):"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sVolId; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                            Label { text: qsTr("起始日期:"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sStart; placeholderText: "YYYY-MM-DD"; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                            Label { text: qsTr("截止日期:"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sEnd; placeholderText: "YYYY-MM-DD"; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                            Label { text: qsTr("单册状态:"); color: root.textPrimary; font.pixelSize: 16 }
                                            ComboBox { id: sStatus; model: [qsTr("全部"), qsTr("已归还"), qsTr("未归还"), qsTr("已逾期")]; Layout.preferredWidth: 200; font.pixelSize: 14 }
                                            Item { Layout.fillWidth: true; Layout.columnSpan: 2 }
                                            Button {
                                                text: qsTr("综合筛选")
                                                Layout.columnSpan: 4; Layout.alignment: Qt.AlignRight; Layout.preferredWidth: 120; Layout.preferredHeight: 40; Layout.topMargin: 10
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: root.textPrimary; radius: 3 }
                                                onClicked: { root.listModelB = SystemBridge.advancedSearch(sIsbn.text, sVolId.text, sStatus.currentIndex, sStart.text, sEnd.text); root.currentPageB = 1; }
                                            }
                                        }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary; Layout.topMargin: 10 }

                                        // 高级检索结果复用严格排版
                                        Item {
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            onHeightChanged: { let r = Math.floor((height - 50) / root.rowHeight); root.tableCapacity = Math.max(5, r - (r%5)); root.currentPageB = 1; }
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 0
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 50; color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                        Label { text: qsTr("序号"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                                                        Label { text: qsTr("借阅者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100; visible: root.isAdmin }
                                                        Label { text: qsTr("题名"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true; Layout.minimumWidth: 150 }
                                                        Label { text: qsTr("作者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100 }
                                                        Label { text: qsTr("单册状态"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80 }
                                                        Label { text: qsTr("借阅日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                        Label { text: qsTr("到期日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                    }
                                                }
                                                ListView {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; interactive: false; model: root.paginatedDataB
                                                    delegate: Rectangle {
                                                        width: ListView.view.width; height: root.rowHeight; color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a"); border.color: root.bgSecondary; border.width: 1
                                                        RowLayout {
                                                            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                            Label { text: (root.currentPageB - 1) * root.tableCapacity + index + 1; color: root.textSecondary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                                                            Label { text: modelData.borrowerId; color: root.textSecondary; Layout.preferredWidth: 100; visible: root.isAdmin }
                                                            Label { text: modelData.title; color: root.textPrimary; font.weight: Font.Bold; Layout.fillWidth: true; Layout.minimumWidth: 150; wrapMode: Text.Wrap; elide: Text.ElideRight; maximumLineCount: 2 }
                                                            Label { text: modelData.author; color: root.textSecondary; Layout.preferredWidth: 100; elide: Text.ElideRight }
                                                            Label { text: modelData.status; color: modelData.status === "已逾期" ? root.textPrimary : root.textSecondary; font.weight: modelData.status === "已逾期" ? Font.Bold : Font.Normal; Layout.preferredWidth: 80 }
                                                            Label { text: modelData.borrowDate; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                            Label { text: modelData.dueDate; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20; visible: root.listModelB.length > 0
                                            Button { text: qsTr("上一页"); enabled: root.currentPageB > 1; onClicked: root.currentPageB--; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageB).arg(root.totalPagesB); font.pixelSize: 16; color: root.textPrimary }
                                            Button { text: qsTr("下一页"); enabled: root.currentPageB < root.totalPagesB; onClicked: root.currentPageB++; background: Rectangle { color: "transparent" } }
                                            TextField { id: jumpB; Layout.preferredWidth: 50; validator: IntValidator { bottom: 1; top: root.totalPagesB } }
                                            Button { text: "Go"; onClicked: { let p = parseInt(jumpB.text); if(p >= 1 && p <= root.totalPagesB) root.currentPageB = p; } }
                                        }
                                    }
                                }

                                // 2.2 借阅统计 (Reader)
                                Item { Label { text: qsTr("借阅统计视图装载点"); font.pixelSize: 20; color: root.textSecondary; anchors.centerIn: parent } }
                            }
                        }

                        // ==========================================
                        // Page 3: 个人信息
                        // ==========================================
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
                                // 3.1 修改信息
                                Item {
                                    ColumnLayout {
                                        anchors.margins: 40; spacing: 20
                                        Label { text: qsTr("修改信息"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                        TextField { id: editCurrentPwd; Layout.preferredWidth: 350; Layout.preferredHeight: 50; placeholderText: qsTr("* 验证当前密码"); echoMode: TextInput.Password; font.pixelSize: 16; color: root.textPrimary }
                                        TextField { id: editNewName; Layout.preferredWidth: 350; Layout.preferredHeight: 50; placeholderText: qsTr("新用户名 (留空则保持现状)"); font.pixelSize: 16; color: root.textPrimary }
                                        TextField { id: editNewPwd; Layout.preferredWidth: 350; Layout.preferredHeight: 50; placeholderText: qsTr("新密码 (至少8位，留空则保持现状)"); echoMode: TextInput.Password; font.pixelSize: 16; color: root.textPrimary }
                                        TextField { id: editConfirmPwd; Layout.preferredWidth: 350; Layout.preferredHeight: 50; placeholderText: qsTr("确认新密码"); echoMode: TextInput.Password; font.pixelSize: 16; color: root.textPrimary }
                                        Button {
                                            text: qsTr("提交修改")
                                            Layout.preferredWidth: 150; Layout.preferredHeight: 45; Layout.topMargin: 15
                                            contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                            background: Rectangle { color: root.textPrimary; radius: 3 }
                                            onClicked: {
                                                if (editCurrentPwd.text === "") return;
                                                if (SystemBridge.updateUserInfo(editCurrentPwd.text, editNewName.text, editNewPwd.text, editConfirmPwd.text) === 0) {
                                                    editCurrentPwd.text = ""; editNewName.text = ""; editNewPwd.text = ""; editConfirmPwd.text = "";
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ==========================================
                        // Page 4: 系统设置
                        // ==========================================
                        Item {
                            StackLayout {
                                anchors.fill: parent
                                currentIndex: root.currentSubMenu
                                // 4.0 界面偏好
                                Item {
                                    ColumnLayout {
                                        anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 40; spacing: 20
                                        ColumnLayout { Layout.fillWidth: true; spacing: 6; Label { text: qsTr("界面偏好"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.preferredWidth: 500; height: 1; color: root.textPrimary } }
                                        RowLayout {
                                            spacing: 20; Layout.topMargin: 10
                                            Label { text: qsTr("界面主题"); font.pixelSize: 18; color: root.textPrimary }
                                            Button { text: root.lightMode ? qsTr("切换至黑暗模式") : qsTr("切换至明亮模式"); contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                            background: Rectangle { color: root.textPrimary; radius: 3; implicitWidth: 140; implicitHeight: 35 }
                                            onClicked: root.lightMode = !root.lightMode }
                                        }
                                    }
                                }
                                // 4.1 数据库连接状态
                                Item {
                                    ColumnLayout {
                                        anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 40; spacing: 20
                                        ColumnLayout { Layout.fillWidth: true; spacing: 6; Label { text: qsTr("数据库连接状态"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.preferredWidth: 600; height: 1; color: root.textPrimary } }
                                        GridLayout {
                                            Layout.topMargin: 15; columns: 2; rowSpacing: 25; columnSpacing: 40
                                            Label { text: qsTr("底层驱动引擎:"); font.pixelSize: 18; color: root.textSecondary }
                                            Label { text: "QSQLITE"; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                            Label { text: qsTr("活动连接句柄:"); font.pixelSize: 18; color: root.textSecondary }
                                            Label { text: "qt_sql_default_connection"; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                        }
                                    }
                                }
                                // 4.2 退出系统
                                Item {
                                    ColumnLayout {
                                        anchors.centerIn: parent; spacing: 35
                                        Label { text: qsTr("安全注销"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary; Layout.alignment: Qt.AlignHCenter }
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 40; Layout.topMargin: 20
                                            Button { text: qsTr("确认注销 (回主页)"); Layout.preferredWidth: 200; Layout.preferredHeight: 50; contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                            background: Rectangle { color: root.textPrimary; radius: 5 }
                                            onClicked: { SystemBridge.logout(); if (typeof debugLoader !== "undefined") { debugLoader.active = false; } } }
                                            Button { text: qsTr("终止程序进程"); Layout.preferredWidth: 200; Layout.preferredHeight: 50; contentItem: Text { text: parent.text; color: root.textPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                            background: Rectangle { color: "transparent"; border.color: root.textPrimary; border.width: 1; radius: 5 }
                                            onClicked: { SystemBridge.logout(); Qt.exit(0); } }
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