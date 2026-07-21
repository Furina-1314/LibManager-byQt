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
        {title: qsTr("读者业务"), idx: 3},
        {title: qsTr("系统设置"), idx: 4}
    ]

    function getSubMenuModel(topMenuIdx) {
        switch(topMenuIdx) {
            case 1: 
                return root.isAdmin ? 
                [qsTr("图书检索"), qsTr("高级检索"), qsTr("热门图书"), qsTr("单册管理")] : 
                [qsTr("图书检索"), qsTr("高级检索"), qsTr("热门图书")]
            case 2: 
                return root.isAdmin ? 
                [qsTr("流水查询"), qsTr("高级检索")] : 
                [qsTr("借阅历史"), qsTr("高级检索"), qsTr("借阅统计")]
            case 3: 
                return root.isAdmin ? 
                [qsTr("账户资料"), qsTr("读者管理")] : 
                [qsTr("账户资料"), qsTr("修改信息")]
            case 4: 
                return [qsTr("界面偏好"), qsTr("数据库连接状态"), qsTr("退出系统")]
            default: 
                return []
        }
    }

    // ==========================================
    // 📊 数据模型与多轨分页引擎
    // ==========================================
    property int rowHeight: 65
    
    // A轨：通用列表模型 (借阅历史/流水查询/图书检索/热门图书)
    property int tableCapacityA: 5 
    property var listModelA: [] 
    property int currentPageA: 1
    property var paginatedDataA: { 
        let p = currentPageA
        let limit = tableCapacityA
        return listModelA.slice((p - 1) * limit, p * limit)
    }
    property int totalPagesA: Math.max(1, Math.ceil(listModelA.length / tableCapacityA))

    // B轨：高级检索/图书详情内联单册模型
    property int tableCapacityB: 5
    property var listModelB: [] 
    property int currentPageB: 1
    property var paginatedDataB: { 
        let p = currentPageB
        let limit = tableCapacityB
        return listModelB.slice((p - 1) * limit, p * limit)
    }
    property int totalPagesB: Math.max(1, Math.ceil(listModelB.length / tableCapacityB))

    // C轨：读者管理检索列表沙箱
    property int tableCapacityC: 5
    property var listModelC: []
    property int currentPageC: 1
    property var paginatedDataC: {
        let p = currentPageC
        let limit = tableCapacityC
        return listModelC.slice((p - 1) * limit, p * limit)
    }
    property int totalPagesC: Math.max(1, Math.ceil(listModelC.length / tableCapacityC))

    // 局部视图状态
    property int bookSearchViewIdx: 0 
    property var currentBookDetails: ({})

    Connections {
        target: root
        function onCurrentTopMenuChanged() { loadData() }
        function onCurrentSubMenuChanged() { loadData() }
    }

    function loadData() {
        root.bookSearchViewIdx = 0
        
        if (root.currentTopMenu === 2 && root.currentSubMenu === 0) {
            root.listModelA = root.isAdmin ? SystemBridge.getAllLoanRecords() : SystemBridge.getBorrowingHistory()
            root.currentPageA = 1
        }
        else if (root.currentTopMenu === 1 && root.currentSubMenu === 2) {
            root.listModelA = SystemBridge.getPopularBooks()
            root.currentPageA = 1
        }
        else if (root.currentTopMenu === 1 && (root.currentSubMenu === 0 || root.currentSubMenu === 1)) {
            root.listModelA = []
            root.currentPageA = 1
        }
        else if (root.currentTopMenu === 2 && root.currentSubMenu === 1) {
            root.listModelB = []
            root.currentPageB = 1
        }
        else if (root.currentTopMenu === 3 && root.currentSubMenu === 1 && root.isAdmin) {
            root.listModelC = []
            root.currentPageC = 1
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.bgPrimary

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // --------------------------------------
            // 顶部导航栏
            // --------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 15
                
                Label {
                    text: qsTr("欢迎您，%1%2").arg(root.isAdmin ? "管理员 " : "").arg(root.userName)
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
                            required property var modelData
                            text: modelData.title
                            font.pixelSize: 18
                            
                            contentItem: Text { 
                                text: parent.text
                                color: root.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 18
                                font.bold: root.currentTopMenu === modelData.idx
                                font.underline: root.currentTopMenu === modelData.idx 
                            }
                            background: Item {} 
                            onClicked: { 
                                root.currentSubMenu = 0
                                root.currentTopMenu = modelData.idx 
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
            // 主体区域
            // --------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // 左侧菜单
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
                                required property int index
                                required property string modelData
                                Layout.fillWidth: true
                                text: modelData
                                font.pixelSize: 16
                                
                                contentItem: Text { 
                                    text: parent.text
                                    color: root.currentSubMenu === index ? root.bgPrimary : root.textPrimary
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                    font.pixelSize: 16 
                                }
                                background: Rectangle { 
                                    color: root.currentSubMenu === index ? root.textPrimary : "transparent"
                                    radius: 2 
                                }
                                onClicked: root.currentSubMenu = index
                            }
                        }
                        Item { Layout.fillHeight: true } 
                    }
                    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.textPrimary }
                }

                // 右侧视图栈
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.bgPrimary

                    StackLayout {
                        anchors.fill: parent
                        anchors.margins: 30
                        currentIndex: root.currentTopMenu

                        // ==========================================
                        // Page 0: 主页
                        // ==========================================
                        Item {
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 40
                                Label { text: qsTr("欢迎使用图书管理系统"); font.pixelSize: 48; font.weight: Font.Light; color: root.textPrimary; Layout.alignment: Qt.AlignHCenter }
                                ColumnLayout {
                                    spacing: 20; Layout.alignment: Qt.AlignHCenter
                                    Repeater {
                                        model: root.topMenuConfig.slice(1)
                                        Button {
                                            required property var modelData
                                            Layout.preferredWidth: 300; Layout.preferredHeight: 60
                                            contentItem: Text { text: modelData.title + " >"; font.pixelSize: 24; color: root.textPrimary; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
                                            background: Rectangle { color: "transparent"; border.color: parent.hovered ? root.textPrimary : "transparent"; border.width: 1 }
                                            onClicked: { root.currentSubMenu = 0; root.currentTopMenu = modelData.idx }
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
                                                anchors.fill: parent
                                                spacing: 15
                                                Label { text: qsTr("图书检索"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                                
                                                RowLayout {
                                                    Layout.fillWidth: true; spacing: 15
                                                    TextField {
                                                        id: titleSearchInput
                                                        Layout.fillWidth: true; Layout.preferredHeight: 45
                                                        placeholderText: qsTr("输入图书标题或关键词")
                                                        font.pixelSize: 16; color: root.textPrimary
                                                        background: Rectangle { border.color: root.textPrimary; border.width: 1; color: "transparent" }
                                                    }                                                    
                                                    ColumnLayout {
                                                        spacing: 5
                                                        Button {
                                                            text: qsTr("高级检索"); Layout.preferredWidth: 100; Layout.preferredHeight: 30
                                                            contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                            background: Rectangle { color: root.textPrimary; radius: 2 }
                                                            onClicked: root.currentSubMenu = 1
                                                        }
                                                        Button {
                                                            text: qsTr("检索"); Layout.preferredWidth: 100; Layout.preferredHeight: 45
                                                            contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                            background: Rectangle { color: root.textPrimary; radius: 2 }
                                                            onClicked: { root.listModelA = SystemBridge.searchBooks(titleSearchInput.text); root.currentPageA = 1 }
                                                        }
                                                    }
                                                }
                                                Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                                
                                                Item {
                                                    Layout.fillWidth: true; Layout.fillHeight: true
                                                    onHeightChanged: { 
                                                        let r = Math.floor(height / 120)
                                                        let newCapacity = Math.max(4, r - (r % 4))
                                                        if (root.tableCapacityA !== newCapacity) {
                                                            root.tableCapacityA = newCapacity
                                                            root.currentPageA = 1
                                                        }
                                                    }
                                                    ListView {
                                                        anchors.fill: parent; clip: true; interactive: false; model: root.paginatedDataA; spacing: 10
                                                        delegate: Rectangle {
                                                            required property var modelData; required property int index
                                                            width: ListView.view.width; height: 110; color: "transparent"; border.color: root.textSecondary; border.width: 1
                                                            
                                                            RowLayout {
                                                                anchors.fill: parent; anchors.margins: 15; spacing: 20
                                                                ColumnLayout {
                                                                    Layout.fillWidth: true; spacing: 5
                                                                    Label { text: modelData.title !== undefined ? modelData.title : "未知题名"; font.pixelSize: 20; font.weight: Font.Bold; color: root.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                                                                    Label { 
                                                                        text: {
                                                                            let a = modelData.author !== undefined ? modelData.author : "-"
                                                                            let p = modelData.press !== undefined ? modelData.press : "-"
                                                                            let y = modelData.pubYear !== undefined ? modelData.pubYear : "-"
                                                                            return "作者: " + a + " | 出版社: " + p + " | 出版年份: " + y
                                                                        }
                                                                        font.pixelSize: 14; color: root.textSecondary; elide: Text.ElideRight; Layout.fillWidth: true 
                                                                    }
                                                                    Label { 
                                                                        text: {
                                                                            let av = modelData.availabilityStr !== undefined ? modelData.availabilityStr : "未知状态(需更新后端)"
                                                                            let lc = modelData.locationStr !== undefined ? modelData.locationStr : "无馆藏位置记录"
                                                                            return "可用状态: " + av + " | 馆藏位置: " + lc
                                                                        }
                                                                        font.pixelSize: 14; color: (modelData.availabilityStr !== undefined && modelData.availabilityStr === "可外借") ? "#16a34a" : root.textSecondary; elide: Text.ElideRight; Layout.fillWidth: true 
                                                                    }
                                                                }
                                                                Button {
                                                                    text: qsTr("查看详情"); Layout.preferredWidth: 100; Layout.preferredHeight: 40; Layout.alignment: Qt.AlignVCenter
                                                                    contentItem: Text { text: parent.text; color: root.textPrimary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                    background: Rectangle { color: "transparent"; border.color: root.textPrimary; border.width: 1 }
                                                                    onClicked: {
                                                                        if (modelData.isbn !== undefined) {
                                                                            root.currentBookDetails = SystemBridge.getBookDetails(modelData.isbn)
                                                                            root.listModelB = root.currentBookDetails.volumes || []
                                                                            root.currentPageB = 1
                                                                            root.bookSearchViewIdx = 1
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } 
                                                }
                                                // 引入页面跳转
                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter; spacing: 20
                                                    visible: root.listModelA.length > 0
                                                    
                                                    Button { text: qsTr("上一页"); enabled: root.currentPageA > 1; onClicked: root.currentPageA--; background: Rectangle { color: "transparent" } }
                                                    Label { 
                                                        text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageA).arg(root.totalPagesA)
                                                        font.pixelSize: 16; color: root.textPrimary; Layout.preferredWidth: 150; horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    Button { text: qsTr("下一页"); enabled: root.currentPageA < root.totalPagesA; onClicked: root.currentPageA++; background: Rectangle { color: "transparent" } }
                                                    TextField { 
                                                        id: jumpSearchA
                                                        Layout.preferredWidth: 50
                                                        validator: IntValidator { bottom: 1; top: root.totalPagesA } 
                                                    }
                                                    Button { 
                                                        text: "Go"
                                                        onClicked: { 
                                                            let p = parseInt(jumpSearchA.text)
                                                            if (p >= 1 && p <= root.totalPagesA) { root.currentPageA = p }
                                                        } 
                                                    }
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

                                                Item {
                                                    Layout.fillWidth: true; Layout.fillHeight: true
                                                    onHeightChanged: { 
                                                        let r = Math.floor((height - 50) / root.rowHeight)
                                                        let newCapacity = Math.max(5, r - (r % 5))
                                                        if (root.tableCapacityB !== newCapacity) {
                                                            root.tableCapacityB = newCapacity
                                                            root.currentPageB = 1
                                                        }
                                                    }
                                                    ColumnLayout {
                                                        anchors.fill: parent; spacing: 0
                                                        Rectangle {
                                                            Layout.fillWidth: true; height: 50; color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                            RowLayout {
                                                                anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                                Label { text: qsTr("操作"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter }
                                                                Label { text: qsTr("单册条码"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 150 }
                                                                Label { text: qsTr("状态"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80 }
                                                                Label { text: qsTr("备注"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 150 }
                                                                Label { text: qsTr("馆藏位置"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true }
                                                            }
                                                        }
                                                        ListView {
                                                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; interactive: false; model: root.paginatedDataB
                                                            delegate: Rectangle {
                                                                required property var modelData; required property int index
                                                                width: ListView.view.width; height: root.rowHeight; color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a"); border.color: root.bgSecondary; border.width: 1
                                                                RowLayout {
                                                                    anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                                    Button {
                                                                        text: (modelData.isAvailable && !root.isAdmin) ? qsTr("借阅") : qsTr("不可借")
                                                                        Layout.preferredWidth: 80; Layout.preferredHeight: 35; enabled: !!modelData.isAvailable && !root.isAdmin
                                                                        contentItem: Text { text: parent.text; color: parent.enabled ? root.bgPrimary : root.textSecondary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                        background: Rectangle { color: parent.enabled ? root.textPrimary : "transparent"; border.color: root.textPrimary; border.width: parent.enabled ? 0 : 1; radius: 2 }
                                                                        onClicked: {
                                                                            let st = SystemBridge.borrowVolume(root.currentBookDetails.isbn, modelData.volId)
                                                                            if(st === 0) {
                                                                                root.currentBookDetails = SystemBridge.getBookDetails(root.currentBookDetails.isbn)
                                                                                root.listModelB = root.currentBookDetails.volumes || []
                                                                            }
                                                                        }
                                                                    }
                                                                    Label { text: modelData.volId !== undefined ? modelData.volId : "-"; color: root.textPrimary; Layout.preferredWidth: 150; font.weight: Font.Bold }
                                                                    Label { text: modelData.status !== undefined ? modelData.status : "-"; color: (modelData.isAvailable !== undefined && modelData.isAvailable) ? "#16a34a" : root.textSecondary; Layout.preferredWidth: 80; wrapMode: Text.Wrap; font.pixelSize: text.indexOf("\n") !== -1 ? 12 : 14; verticalAlignment: Text.AlignVCenter }
                                                                    Label { text: modelData.note !== undefined && modelData.note !== "" ? modelData.note : "-"; color: root.textSecondary; Layout.preferredWidth: 150; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                                                                    Label { text: modelData.location !== undefined ? modelData.location : "-"; color: root.textSecondary; Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 2 }
                                                                }
                                                            }
                                                        }                                                    
                                                    }
                                                }                                                
                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter; spacing: 20
                                                    Button { text: qsTr("上一页"); enabled: root.currentPageB > 1; onClicked: root.currentPageB--; background: Rectangle { color: "transparent" } }
                                                    Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageB).arg(root.totalPagesB); font.pixelSize: 16; color: root.textPrimary; Layout.preferredWidth: 150; horizontalAlignment: Text.AlignHCenter }
                                                    Button { text: qsTr("下一页"); enabled: root.currentPageB < root.totalPagesB; onClicked: root.currentPageB++; background: Rectangle { color: "transparent" } }
                                                }
                                            }
                                        }
                                    }
                                }

                                // 1.1 高级检索
                                Item {
                                    ColumnLayout {
                                        anchors.fill: parent; spacing: 15
                                        Label { text: qsTr("高级检索"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                        GridLayout {
                                            columns: 4; rowSpacing: 15; columnSpacing: 20
                                            Label { text: qsTr("书名:"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sBookTitle; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                            Label { text: qsTr("作者:"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sBookAuthor; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                            Label { text: qsTr("出版社:"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sBookPress; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                            Label { text: qsTr("ISBN:"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sBookIsbn; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                            Item { Layout.fillWidth: true; Layout.columnSpan: 2 }
                                            Button {
                                                text: qsTr("综合筛选")
                                                Layout.columnSpan: 2; Layout.alignment: Qt.AlignRight; Layout.preferredWidth: 120; Layout.preferredHeight: 40; Layout.topMargin: 10
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: root.textPrimary; radius: 3 }
                                                onClicked: { 
                                                    try {
                                                        root.currentSubMenu = 0
                                                        root.listModelA = SystemBridge.advancedSearchBooks(sBookTitle.text, sBookAuthor.text, sBookPress.text, sBookIsbn.text)
                                                        root.currentPageA = 1 
                                                    } catch (e) {
                                                        console.error("跨界调用受阻，未能触发检索动作:", e)
                                                    }
                                                }
                                            }
                                        }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary; Layout.topMargin: 10 }
                                        Item { Layout.fillWidth: true; Layout.fillHeight: true } 
                                    }
                                }

                                // 1.2 热门图书
                                Item {
                                    ColumnLayout {
                                        anchors.fill: parent; spacing: 15
                                        Label { text: qsTr("热门图书"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                        Item {
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            onHeightChanged: { 
                                                let r = Math.floor(height / 100)
                                                let newCapacity = Math.max(5, r - (r % 5))
                                                if (root.tableCapacityA !== newCapacity) {
                                                    root.tableCapacityA = newCapacity
                                                    root.currentPageA = 1
                                                }
                                            }
                                            ListView {
                                                anchors.fill: parent; clip: true; interactive: false; model: root.paginatedDataA; spacing: 10
                                                delegate: Rectangle {
                                                    required property var modelData; required property int index
                                                    width: ListView.view.width; height: 90; color: "transparent"; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.margins: 15; spacing: 20
                                                        ColumnLayout {
                                                            Layout.fillWidth: true; spacing: 5
                                                            Label { text: modelData.title || "未知"; font.pixelSize: 20; font.weight: Font.Bold; color: root.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                                                            Label { text: qsTr("作者: %1 | 累计借阅: %2 次").arg(modelData.author || "-").arg(modelData.borrowCount || 0); font.pixelSize: 14; color: root.textSecondary; Layout.fillWidth: true }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20
                                            Button { text: qsTr("上一页"); enabled: root.currentPageA > 1; onClicked: root.currentPageA--; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageA).arg(root.totalPagesA); font.pixelSize: 16; color: root.textPrimary; Layout.preferredWidth: 150; horizontalAlignment: Text.AlignHCenter }
                                            Button { text: qsTr("下一页"); enabled: root.currentPageA < root.totalPagesA; onClicked: root.currentPageA++; background: Rectangle { color: "transparent" } }
                                        }
                                    }
                                }

                                // 1.3 单册管理 (Admin)
                                Item {
                                    id: adminBookMgmtRoot
                                    property int bookMgmtViewIdx: 0 
                                    property var targetBookData: ({}) 

                                    // 局部检索沙箱
                                    property var mgmtListModel: []
                                    property int mgmtCurrentPage: 1
                                    property int mgmtTableCapacity: 4
                                    property int mgmtTotalPages: Math.max(1, Math.ceil(mgmtListModel.length / mgmtTableCapacity))
                                    property var mgmtPaginatedData: { 
                                        let p = mgmtCurrentPage
                                        let limit = mgmtTableCapacity
                                        return mgmtListModel.slice((p - 1) * limit, p * limit)
                                    }

                                    // 单册内存视图局部沙箱 (针对详情页单册列表)
                                    property int mgmtVolCurrentPage: 1
                                    property int mgmtVolTableCapacity: 5
                                    property int mgmtVolTotalPages: Math.max(1, Math.ceil((targetBookData.volumes || []).length / mgmtVolTableCapacity))
                                    property var mgmtVolPaginatedData: {
                                        let vols = targetBookData.volumes || []
                                        let p = mgmtVolCurrentPage
                                        let limit = mgmtVolTableCapacity
                                        return vols.slice((p - 1) * limit, p * limit)
                                    }

                                    property bool volIsEditMode: false
                                    property string editVolId: ""
                                    property int editVolOriginalStatus: 1 
                                    property int editVolLibIdx: 0
                                    property string editVolFloor: "1"
                                    property int editVolAreaIdx: 0
                                    property string editVolShelf: "1"
                                    property string editVolLayer: "1"
                                    property int editVolStatusIdx: 0
                                    property int editVolOpenShelfIdx: 1
                                    property string editVolNote: ""

                                    function openVolumeForm(isEdit, volData) {
                                        volIsEditMode = isEdit
                                        if (isEdit && volData) {
                                            editVolId = volData.volId
                                            editVolNote = volData.note !== undefined ? volData.note : ""
                                            let st = volData.status || ""
                                            if (st.indexOf("在馆可借") !== -1) editVolOriginalStatus = 1
                                            else if (st.indexOf("已借出") !== -1) editVolOriginalStatus = 2
                                            else if (st.indexOf("遗失") !== -1) editVolOriginalStatus = 3
                                            else if (st.indexOf("加工中") !== -1) editVolOriginalStatus = 4
                                            else editVolOriginalStatus = 1
                                            
                                            editVolStatusIdx = 0

                                            let locText = volData.location || ""
                                            let regex = /(.+?)\s+(\d+)层\s+(.+?)\s+(\d+)架\s+(\d+)层/
                                            let match = locText.match(regex)
                                            if (match) {
                                                let lMap = {"主馆北馆": 0, "主馆西馆": 1, "经管图书馆": 2, "人文社科图书馆": 3, "法律图书馆": 4}
                                                let aMap = {"东区": 0, "西区": 1, "南区": 2, "北区": 3}
                                                editVolLibIdx = lMap[match[1]] !== undefined ? lMap[match[1]] : 0
                                                editVolFloor = match[2]
                                                editVolAreaIdx = aMap[match[3]] !== undefined ? aMap[match[3]] : 0
                                                editVolShelf = match[4]
                                                editVolLayer = match[5]
                                            }
                                        } else {
                                            editVolId = ""
                                            editVolNote = ""
                                            editVolLibIdx = 0
                                            editVolFloor = "1"
                                            editVolAreaIdx = 0
                                            editVolShelf = "1"
                                            editVolLayer = "1"
                                            editVolOriginalStatus = 1
                                            editVolStatusIdx = 0
                                            editVolOpenShelfIdx = 1
                                        }
                                        bookMgmtViewIdx = 2
                                    }

                                    StackLayout {
                                        anchors.fill: parent
                                        currentIndex: adminBookMgmtRoot.bookMgmtViewIdx
                                        
                                        // 视图 0：高级检索面板
                                        Item {
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 15
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Label { text: qsTr("图书与单册库务管理"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary; Layout.fillWidth: true }
                                                    Button {
                                                        text: qsTr("+ 新增图书"); Layout.preferredWidth: 140; Layout.preferredHeight: 40
                                                        background: Rectangle { color: root.textPrimary; radius: 3 }
                                                        contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                        onClicked: {
                                                            adminBookMgmtRoot.targetBookData = {isbn:"", title:"", author:"", press:"", pubYear:"", intro:"", volumes:[]}
                                                            adminBookMgmtRoot.bookMgmtViewIdx = 1
                                                        }
                                                    }
                                                }
                                                Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

                                                GridLayout {
                                                    columns: 4; rowSpacing: 15; columnSpacing: 20
                                                    Label { text: qsTr("书名:"); color: root.textPrimary; font.pixelSize: 16 }
                                                    TextField { id: mgmtTitle; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                                    Label { text: qsTr("作者:"); color: root.textPrimary; font.pixelSize: 16 }
                                                    TextField { id: mgmtAuthor; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                                    Label { text: qsTr("出版社:"); color: root.textPrimary; font.pixelSize: 16 }
                                                    TextField { id: mgmtPress; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                                    Label { text: qsTr("ISBN:"); color: root.textPrimary; font.pixelSize: 16 }
                                                    TextField { id: mgmtIsbn; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } }
                                                    Item { Layout.fillWidth: true; Layout.columnSpan: 2 }
                                                    Button {
                                                        text: qsTr("检索")
                                                        Layout.columnSpan: 2; Layout.alignment: Qt.AlignRight; Layout.preferredWidth: 120; Layout.preferredHeight: 40; Layout.topMargin: 10
                                                        contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                        background: Rectangle { color: root.textPrimary; radius: 3 }
                                                        onClicked: { 
                                                            adminBookMgmtRoot.mgmtListModel = SystemBridge.advancedSearchBooks(mgmtTitle.text, mgmtAuthor.text, mgmtPress.text, mgmtIsbn.text)
                                                            adminBookMgmtRoot.mgmtCurrentPage = 1
                                                        }
                                                    }
                                                }
                                                Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary; Layout.topMargin: 10 }

                                                Item {
                                                    Layout.fillWidth: true; Layout.fillHeight: true
                                                    onHeightChanged: { 
                                                        let r = Math.floor(height / 100)
                                                        let newCapacity = Math.max(4, r) // 动态自适应行数
                                                        if (adminBookMgmtRoot.mgmtTableCapacity !== newCapacity) {
                                                            adminBookMgmtRoot.mgmtTableCapacity = newCapacity
                                                            adminBookMgmtRoot.mgmtCurrentPage = 1
                                                        }
                                                    }
                                                    ListView {
                                                        anchors.fill: parent; clip: true; interactive: false; spacing: 10; model: adminBookMgmtRoot.mgmtPaginatedData
                                                        delegate: Rectangle {
                                                            required property var modelData; required property int index
                                                            width: ListView.view.width; height: 90; color: "transparent"; border.color: root.textSecondary; border.width: 1
                                                            RowLayout {
                                                                anchors.fill: parent; anchors.margins: 15; spacing: 20
                                                                ColumnLayout {
                                                                    Layout.fillWidth: true; spacing: 5
                                                                    Label { text: modelData.title || "未知"; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                                                                    Label { text: qsTr("ISBN: %1 | 作者: %2").arg(modelData.isbn || "-").arg(modelData.author || "-"); font.pixelSize: 14; color: root.textSecondary; Layout.fillWidth: true }
                                                                }
                                                                Button {
                                                                    text: qsTr("编辑"); Layout.preferredWidth: 100; Layout.preferredHeight: 40
                                                                    contentItem: Text { text: parent.text; color: root.textPrimary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                    background: Rectangle { color: "transparent"; border.color: root.textPrimary; border.width: 1 }
                                                                    onClicked: {
                                                                        adminBookMgmtRoot.targetBookData = SystemBridge.getBookDetails(modelData.isbn)
                                                                        adminBookMgmtRoot.bookMgmtViewIdx = 1
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } 
                                                }
                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter; spacing: 20
                                                    visible: adminBookMgmtRoot.mgmtListModel.length > 0
                                                    
                                                    Button { text: qsTr("上一页"); enabled: adminBookMgmtRoot.mgmtCurrentPage > 1; onClicked: adminBookMgmtRoot.mgmtCurrentPage--; background: Rectangle { color: "transparent" } }
                                                    Label { 
                                                        text: qsTr("第 %1 页 / 共 %2 页").arg(adminBookMgmtRoot.mgmtCurrentPage).arg(adminBookMgmtRoot.mgmtTotalPages)
                                                        font.pixelSize: 16; color: root.textPrimary; Layout.preferredWidth: 150; horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    Button { text: qsTr("下一页"); enabled: adminBookMgmtRoot.mgmtCurrentPage < adminBookMgmtRoot.mgmtTotalPages; onClicked: adminBookMgmtRoot.mgmtCurrentPage++; background: Rectangle { color: "transparent" } }
                                                    TextField { 
                                                        id: jumpMgmtSearch
                                                        Layout.preferredWidth: 50
                                                        validator: IntValidator { bottom: 1; top: adminBookMgmtRoot.mgmtTotalPages } 
                                                    }
                                                    Button { 
                                                        text: "Go"
                                                        onClicked: { 
                                                            let p = parseInt(jumpMgmtSearch.text)
                                                            if (p >= 1 && p <= adminBookMgmtRoot.mgmtTotalPages) { adminBookMgmtRoot.mgmtCurrentPage = p }
                                                        } 
                                                    }
                                                }
                                            }
                                        }

                                        // 视图 1：图书元数据与单册拓扑树
                                        Item {
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 15
                                                Label { text: qsTr("< 返回检索"); font.pixelSize: 16; font.underline: true; color: root.textSecondary; MouseArea { anchors.fill: parent; onClicked: adminBookMgmtRoot.bookMgmtViewIdx = 0 } }
                                                
                                                Rectangle {
                                                    Layout.fillWidth: true; Layout.preferredHeight: 280; color: root.bgSecondary; radius: 5
                                                    GridLayout {
                                                        anchors.fill: parent; anchors.margins: 20; columns: 4; rowSpacing: 10; columnSpacing: 15
                                                        Label { text: "ISBN:"; color: root.textPrimary } 
                                                        TextField { id: eIsbn; text: adminBookMgmtRoot.targetBookData.isbn || ""; enabled: adminBookMgmtRoot.targetBookData.isbn === ""; Layout.preferredWidth: 200; color: root.textPrimary; font.pixelSize: 14; background: Rectangle{ border.color: root.textSecondary; border.width: 1; color: parent.enabled ? root.bgPrimary : root.bgSecondary } }
                                                        Label { text: "题名:"; color: root.textPrimary } 
                                                        TextField { id: eTitle; text: adminBookMgmtRoot.targetBookData.title || ""; Layout.preferredWidth: 200; color: root.textPrimary; font.pixelSize: 14; background: Rectangle{ border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } }
                                                        Label { text: "编著者 (逗号分隔):"; color: root.textPrimary } 
                                                        TextField { id: eAuthor; text: adminBookMgmtRoot.targetBookData.author || ""; Layout.preferredWidth: 200; color: root.textPrimary; font.pixelSize: 14; background: Rectangle{ border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } }
                                                        Label { text: "出版社:"; color: root.textPrimary } 
                                                        TextField { id: ePress; text: adminBookMgmtRoot.targetBookData.press || ""; Layout.preferredWidth: 200; color: root.textPrimary; font.pixelSize: 14; background: Rectangle{ border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } }
                                                        Label { text: "出版年份:"; color: root.textPrimary } 
                                                        TextField { id: eYear; text: adminBookMgmtRoot.targetBookData.pubYear || ""; validator: IntValidator{} Layout.preferredWidth: 200; color: root.textPrimary; font.pixelSize: 14; background: Rectangle{ border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } }
    
                                                        Label { text: "图书分类:"; color: root.textPrimary } 
                                                        ComboBox { 
                                                            id: eCategory
                                                            model: [qsTr("文学"), qsTr("哲学"), qsTr("语言学"), qsTr("艺术"), qsTr("科技")]
                                                            currentIndex: adminBookMgmtRoot.targetBookData.category !== undefined ? (adminBookMgmtRoot.targetBookData.category - 1) : 0
                                                            Layout.preferredWidth: 200; font.pixelSize: 14 
                                                        }
                                                        Label { text: "语种:"; color: root.textPrimary } 
                                                        ComboBox { 
                                                            id: eLanguage
                                                            model: [qsTr("中文"), qsTr("英文"), qsTr("俄文"), qsTr("法文"), qsTr("西班牙文"), qsTr("阿拉伯文"), qsTr("日文"), qsTr("韩文"), qsTr("其他")]
                                                            currentIndex: adminBookMgmtRoot.targetBookData.language !== undefined ? (adminBookMgmtRoot.targetBookData.language - 1) : 0
                                                            Layout.preferredWidth: 200; font.pixelSize: 14 
                                                        }

                                                        Label { text: "内容提要:"; color: root.textPrimary; Layout.alignment: Qt.AlignTop } 
                                                        ScrollView {
                                                            Layout.columnSpan: 3; Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                                            TextArea { 
                                                                id: eIntro; text: adminBookMgmtRoot.targetBookData.intro || ""; 
                                                                wrapMode: Text.Wrap; color: root.textPrimary; font.pixelSize: 14; 
                                                                background: Rectangle{ border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } 
                                                            }
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    spacing: 20
                                                    Button { 
                                                        text: qsTr("提交"); Layout.preferredWidth: 180; Layout.preferredHeight: 35; background: Rectangle { color: root.textPrimary; radius: 3 }
                                                        contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                        onClicked: { 
                                                                let catEnum = eCategory.currentIndex + 1;
                                                                let langEnum = eLanguage.currentIndex + 1;
                                                                if(SystemBridge.saveBook(eIsbn.text, eTitle.text, eAuthor.text, ePress.text, parseInt(eYear.text), catEnum, langEnum, eIntro.text) === 0) {
                                                                    adminBookMgmtRoot.targetBookData = SystemBridge.getBookDetails(eIsbn.text)
                                                                    messageDialog.messageText = "成功。"
                                                                    messageDialog.open()
                                                                }
                                                        }                                                    
                                                    }
                                                    Button { 
                                                        text: qsTr("删除图书 (危险)"); Layout.preferredWidth: 200; Layout.preferredHeight: 35; enabled: !!adminBookMgmtRoot.targetBookData.isbn !== ""
                                                        background: Rectangle { color: "transparent"; border.color: "#dc2626"; border.width: 1; radius: 3 }
                                                        contentItem: Text { text: parent.text; color: parent.enabled ? "#dc2626" : root.textSecondary; font.pixelSize: 14; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                        onClicked: { 
                                                            if(SystemBridge.deleteBook(eIsbn.text) === 0) { adminBookMgmtRoot.bookMgmtViewIdx = 0 } 
                                                        } 
                                                    }
                                                }
                                                Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                                
                                                RowLayout {
                                                    Label { text: qsTr("下属单册"); font.pixelSize: 20; font.weight: Font.Bold; color: root.textPrimary }
                                                    Item { Layout.fillWidth: true }
                                                    Button { 
                                                        text: qsTr("+ 新增单册"); Layout.preferredWidth: 140; Layout.preferredHeight: 35; enabled: adminBookMgmtRoot.targetBookData.isbn !== "" && adminBookMgmtRoot.targetBookData.isbn !== undefined
                                                        background: Rectangle { color: "transparent"; border.color: root.textPrimary; border.width: 1; radius: 3 }
                                                        contentItem: Text { text: parent.text; color: parent.enabled ? root.textPrimary : root.textSecondary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                        onClicked: { adminBookMgmtRoot.openVolumeForm(false, null) } 
                                                    }
                                                }
                                                
                                                Item {
                                                    Layout.fillWidth: true; Layout.fillHeight: true
                                                    onHeightChanged: {
                                                        let r = Math.floor(height / 60)
                                                        let newCapacity = Math.max(2, r)
                                                        if (adminBookMgmtRoot.mgmtVolTableCapacity !== newCapacity) {
                                                            adminBookMgmtRoot.mgmtVolTableCapacity = newCapacity
                                                            adminBookMgmtRoot.mgmtVolCurrentPage = 1
                                                        }
                                                    }
                                                    ListView {
                                                        anchors.fill: parent; clip: true; model: adminBookMgmtRoot.mgmtVolPaginatedData
                                                        delegate: Rectangle {
                                                            required property var modelData; required property int index
                                                            width: ListView.view.width; height: 60; color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a")
                                                            RowLayout {
                                                                anchors.fill: parent; anchors.margins: 10; spacing: 15
                                                                Label { text: modelData.volId; font.pixelSize: 16; font.weight: Font.Bold; color: root.textPrimary; Layout.preferredWidth: 150 }
                                                                Label { text: modelData.status; color: root.textSecondary; Layout.preferredWidth: 100 }
                                                                Label { text: modelData.location; color: root.textSecondary; Layout.fillWidth: true }
                                                                Button { 
                                                                    text: "编辑"; Layout.preferredWidth: 60; Layout.preferredHeight: 30; background: Rectangle { color: "transparent"; border.color: root.textPrimary; border.width: 1 }
                                                                    contentItem: Text { text: parent.text; color: root.textPrimary; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                    onClicked: { adminBookMgmtRoot.openVolumeForm(true, modelData) } 
                                                                }
                                                                Button { 
                                                                    text: "删除"; Layout.preferredWidth: 60; Layout.preferredHeight: 30; background: Rectangle { color: root.bgSecondary; border.color: "#dc2626"; border.width: 1 }
                                                                    contentItem: Text { text: parent.text; color: "#dc2626"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                    onClicked: { 
                                                                        if (SystemBridge.deleteVolume(adminBookMgmtRoot.targetBookData.isbn, modelData.volId) === 0) {
                                                                            adminBookMgmtRoot.targetBookData = SystemBridge.getBookDetails(adminBookMgmtRoot.targetBookData.isbn)
                                                                        }
                                                                    } 
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                RowLayout {
                                                    Layout.alignment: Qt.AlignHCenter; spacing: 20
                                                    visible: (adminBookMgmtRoot.targetBookData.volumes || []).length > 0
                                                    Button { text: qsTr("上一页"); enabled: adminBookMgmtRoot.mgmtVolCurrentPage > 1; onClicked: adminBookMgmtRoot.mgmtVolCurrentPage--; background: Rectangle { color: "transparent" } }
                                                    Label { text: qsTr("第 %1 页 / 共 %2 页").arg(adminBookMgmtRoot.mgmtVolCurrentPage).arg(adminBookMgmtRoot.mgmtVolTotalPages); font.pixelSize: 16; color: root.textPrimary; Layout.preferredWidth: 150; horizontalAlignment: Text.AlignHCenter }
                                                    Button { text: qsTr("下一页"); enabled: adminBookMgmtRoot.mgmtVolCurrentPage < adminBookMgmtRoot.mgmtVolTotalPages; onClicked: adminBookMgmtRoot.mgmtVolCurrentPage++; background: Rectangle { color: "transparent" } }
                                                }
                                            }
                                        }

                                        // 视图 2：单册物理节点详情编辑
                                        Item {
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 15
                                                
                                                Label { text: qsTr("< 放弃并返回"); font.pixelSize: 16; font.underline: true; color: root.textSecondary; MouseArea { anchors.fill: parent; onClicked: adminBookMgmtRoot.bookMgmtViewIdx = 1 } }
                                                Label { text: adminBookMgmtRoot.volIsEditMode ? qsTr("单册编辑") : qsTr("单册录入"); font.pixelSize: 26; font.weight: Font.Bold; color: root.textPrimary }
                                                Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

                                                Rectangle {
                                                    Layout.fillWidth: true; Layout.preferredHeight: 340; color: root.bgSecondary; border.color: root.textSecondary; border.width: 1; radius: 5
                                                    
                                                    GridLayout {
                                                        anchors.fill: parent; anchors.margins: 25; columns: 4; rowSpacing: 20; columnSpacing: 25
                                                        
                                                        Label { text: "单册条码 (VolID):"; font.weight: Font.Bold; color: root.textPrimary }
                                                        TextField { id: fVolId; text: adminBookMgmtRoot.editVolId; enabled: !adminBookMgmtRoot.volIsEditMode; Layout.preferredWidth: 200; font.pixelSize: 14; color: root.textPrimary; background: Rectangle { border.color: root.textSecondary; border.width: 1; color: parent.enabled ? root.bgPrimary : root.bgSecondary } }
                                                        
                                                        Label { text: "流通状态:"; font.weight: Font.Bold; color: root.textPrimary }
                                                        ComboBox { 
                                                            id: fStatus
                                                            model: adminBookMgmtRoot.volIsEditMode ? [qsTr("(不修改)"), qsTr("遗失"), qsTr("加工中")] : [qsTr("在馆可借"), qsTr("遗失"), qsTr("加工中")]
                                                            currentIndex: adminBookMgmtRoot.editVolStatusIdx
                                                            Layout.preferredWidth: 200; font.pixelSize: 14 
                                                        }

                                                        Label { text: "藏书馆:"; font.weight: Font.Bold; color: root.textPrimary }
                                                        ComboBox { id: fLib; model: [qsTr("主馆北馆"), qsTr("主馆西馆"), qsTr("经管图书馆"), qsTr("人文社科图书馆"), qsTr("法律图书馆")]; currentIndex: adminBookMgmtRoot.editVolLibIdx; Layout.preferredWidth: 200; font.pixelSize: 14 }
                                                        
                                                        Label { text: "分区:"; font.weight: Font.Bold; color: root.textPrimary }
                                                        ComboBox { id: fArea; model: [qsTr("东区"), qsTr("西区"), qsTr("南区"), qsTr("北区")]; currentIndex: adminBookMgmtRoot.editVolAreaIdx; Layout.preferredWidth: 200; font.pixelSize: 14 }

                                                        Label { text: "楼层:"; font.weight: Font.Bold; color: root.textPrimary }
                                                        TextField { id: fFloor; text: adminBookMgmtRoot.editVolFloor; validator: IntValidator { bottom: 1 } Layout.preferredWidth: 200; font.pixelSize: 14; color: root.textPrimary; background: Rectangle { border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } }
                                                        
                                                        Label { text: "排架:"; font.weight: Font.Bold; color: root.textPrimary }
                                                        TextField { id: fShelf; text: adminBookMgmtRoot.editVolShelf; validator: IntValidator { bottom: 1 } Layout.preferredWidth: 200; font.pixelSize: 14; color: root.textPrimary; background: Rectangle { border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } }

                                                        Label { text: "架层号:"; font.weight: Font.Bold; color: root.textPrimary }
                                                        TextField { id: fLayer; text: adminBookMgmtRoot.editVolLayer; validator: IntValidator { bottom: 1 } Layout.preferredWidth: 200; font.pixelSize: 14; color: root.textPrimary; background: Rectangle { border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } }

                                                        Label { text: "闭/开架属性:"; font.weight: Font.Bold; color: root.textPrimary }
                                                        ComboBox { id: fOpenShelf; model: [qsTr("密集闭架"), qsTr("流通开架")]; currentIndex: adminBookMgmtRoot.editVolOpenShelfIdx; Layout.preferredWidth: 200; font.pixelSize: 14 }

                                                        Label { text: "备注:"; font.weight: Font.Bold; color: root.textPrimary }
                                                        TextField { id: fNote; text: adminBookMgmtRoot.editVolNote; Layout.columnSpan: 3; Layout.fillWidth: true; font.pixelSize: 14; color: root.textPrimary; background: Rectangle { border.color: root.textSecondary; border.width: 1; color: root.bgPrimary } }
                                                    }
                                                }
                                                
                                                Button {
                                                    text: qsTr("提交")
                                                    Layout.preferredWidth: 200; Layout.preferredHeight: 45; Layout.alignment: Qt.AlignRight
                                                    background: Rectangle { color: root.textPrimary; radius: 3 }
                                                    contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                    onClicked: {
                                                        let isbn = adminBookMgmtRoot.targetBookData.isbn
                                                        let volId = fVolId.text
                                                        let lib = fLib.currentIndex + 1       
                                                        let floor = parseInt(fFloor.text)
                                                        let area = fArea.currentIndex + 1     
                                                        let shelf = parseInt(fShelf.text)
                                                        let layer = parseInt(fLayer.text)
                                                        let isOpenshelf = (fOpenShelf.currentIndex === 1)
                                                        let note = fNote.text

                                                        let availability = 1
                                                        if (adminBookMgmtRoot.volIsEditMode) {
                                                            if (fStatus.currentIndex === 0) availability = adminBookMgmtRoot.editVolOriginalStatus
                                                            else if (fStatus.currentIndex === 1) availability = 3
                                                            else if (fStatus.currentIndex === 2) availability = 4 
                                                        } else {
                                                            if (fStatus.currentIndex === 0) availability = 1
                                                            else if (fStatus.currentIndex === 1) availability = 3
                                                            else if (fStatus.currentIndex === 2) availability = 4
                                                        }

                                                        let st = SystemBridge.saveVolume(isbn, volId, lib, floor, area, shelf, layer, availability, isOpenshelf, note)
                                                        if (st === 0) {
                                                            adminBookMgmtRoot.targetBookData = SystemBridge.getBookDetails(isbn)
                                                            messageDialog.messageText = "成功。"
                                                            messageDialog.open()
                                                            adminBookMgmtRoot.bookMgmtViewIdx = 1
                                                        }
                                                    }
                                                }
                                                Item { Layout.fillHeight: true } 
                                            }
                                        }
                                    }
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

                                Item {
                                    ColumnLayout {
                                        anchors.fill: parent; spacing: 15
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Label { text: root.isAdmin ? qsTr("流水查询") : qsTr("借阅历史"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary; Layout.fillWidth: true }
                                            Button {
                                                text: qsTr("高级检索"); Layout.preferredWidth: 120; Layout.preferredHeight: 40
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: root.textPrimary; radius: 3 }
                                                onClicked: root.currentSubMenu = 1
                                            }
                                        }
                                        
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 80; color: "transparent"; visible: !root.isAdmin
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

                                        Item {
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            onHeightChanged: { 
                                                let r = Math.floor((height - 50) / root.rowHeight)
                                                let newCapacity = Math.max(5, r - (r % 5))
                                                if (root.tableCapacityA !== newCapacity) {
                                                    root.tableCapacityA = newCapacity
                                                    root.currentPageA = 1
                                                }
                                            }
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 0
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 50; color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                        Label { text: qsTr("操作"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 60; visible: root.isAdmin; horizontalAlignment: Text.AlignHCenter }
                                                        Label { text: qsTr("序号"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                                                        Label { text: qsTr("借阅者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100; visible: root.isAdmin }
                                                        Label { text: qsTr("单册条码"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100 }
                                                        Label { text: qsTr("题名"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true; Layout.minimumWidth: 120 }
                                                        Label { text: qsTr("作者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80 }
                                                        Label { text: qsTr("单册状态"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 70 }
                                                        Label { text: qsTr("借阅日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                        Label { text: qsTr("应还日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                        Label { text: qsTr("归还日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                    }
                                                }
                                                ListView {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; interactive: false; model: root.paginatedDataA
                                                    delegate: Rectangle {
                                                        required property var modelData; required property int index
                                                        width: ListView.view.width; height: root.rowHeight; color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a"); border.color: root.bgSecondary; border.width: 1
                                                        RowLayout {
                                                            Item {
                                                                Layout.preferredWidth: 60; Layout.fillHeight: true; visible: root.isAdmin
                                                                Button {
                                                                    text: qsTr("归还"); anchors.centerIn: parent; width: 45; height: 28; visible: modelData.status === "未归还" || modelData.status === "已逾期"
                                                                    contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                    background: Rectangle { color: root.textPrimary; radius: 3 }
                                                                    onClicked: {
                                                                        if (SystemBridge.returnVolume(modelData.isbn, modelData.volId) === 0) {
                                                                            root.listModelA = SystemBridge.getAllLoanRecords()
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                            Label { text: (root.currentPageA - 1) * root.tableCapacityA + index + 1; color: root.textSecondary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                                                            Label { text: modelData.borrowerId || "-"; color: root.textSecondary; Layout.preferredWidth: 100; visible: root.isAdmin }
                                                            Label { text: modelData.volId || "-"; color: root.textSecondary; Layout.preferredWidth: 100 }
                                                            Label { text: modelData.title || "-"; color: root.textPrimary; font.weight: Font.Bold; Layout.fillWidth: true; Layout.minimumWidth: 120; wrapMode: Text.Wrap; elide: Text.ElideRight; maximumLineCount: 2 }
                                                            Label { text: modelData.author || "-"; color: root.textSecondary; Layout.preferredWidth: 80; elide: Text.ElideRight }
                                                            Label { text: modelData.status || "-"; color: modelData.status === "已逾期" ? root.textPrimary : root.textSecondary; font.weight: modelData.status === "已逾期" ? Font.Bold : Font.Normal; Layout.preferredWidth: 70 }
                                                            Label { text: modelData.borrowDate || "-"; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                            Label { text: modelData.dueDate || "-"; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                            Label { text: modelData.returnDate ? modelData.returnDate : "——"; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20; visible: root.listModelA.length > 0
                                            Button { text: qsTr("上一页"); enabled: root.currentPageA > 1; onClicked: root.currentPageA--; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageA).arg(root.totalPagesA); font.pixelSize: 16; color: root.textPrimary; Layout.preferredWidth: 150; horizontalAlignment: Text.AlignHCenter }
                                            Button { text: qsTr("下一页"); enabled: root.currentPageA < root.totalPagesA; onClicked: root.currentPageA++; background: Rectangle { color: "transparent" } }
                                            TextField { id: jumpL; Layout.preferredWidth: 50; validator: IntValidator { bottom: 1; top: root.totalPagesA } }
                                            Button { text: "Go"; onClicked: { let p = parseInt(jumpL.text); if(p >= 1 && p <= root.totalPagesA) { root.currentPageA = p } } }
                                        }
                                    }
                                }

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
                                            TextField { id: sStart; placeholderText: "YYYY-MM-DD"; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } validator: RegularExpressionValidator { regularExpression: /^\d{4}-\d{2}-\d{2}$/ } }
                                            Label { text: qsTr("截止日期:"); color: root.textPrimary; font.pixelSize: 16 }
                                            TextField { id: sEnd; placeholderText: "YYYY-MM-DD"; Layout.preferredWidth: 200; font.pixelSize: 14; background: Rectangle{ color: "transparent"; border.color: root.textSecondary; border.width: 1 } validator: RegularExpressionValidator { regularExpression: /^\d{4}-\d{2}-\d{2}$/ } }
                                            Label { text: qsTr("单册状态:"); color: root.textPrimary; font.pixelSize: 16 }
                                            ComboBox { id: sStatus; model: [qsTr("全部"), qsTr("已归还"), qsTr("未归还"), qsTr("已逾期")]; Layout.preferredWidth: 200; font.pixelSize: 14 }
                                            Item { Layout.fillWidth: true; Layout.columnSpan: 2 }
                                            Button {
                                                text: qsTr("综合筛选"); Layout.columnSpan: 4; Layout.alignment: Qt.AlignRight; Layout.preferredWidth: 120; Layout.preferredHeight: 40; Layout.topMargin: 10
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                background: Rectangle { color: root.textPrimary; radius: 3 }
                                                onClicked: { root.listModelB = SystemBridge.advancedSearch(sIsbn.text, sVolId.text, sStatus.currentIndex, sStart.text, sEnd.text); root.currentPageB = 1 }
                                            }
                                        }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary; Layout.topMargin: 10 }
                                        Item {
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            onHeightChanged: { 
                                                let r = Math.floor((height - 50) / root.rowHeight)
                                                let newCapacity = Math.max(5, r - (r % 5))
                                                if (root.tableCapacityB !== newCapacity) { root.tableCapacityB = newCapacity; root.currentPageB = 1 }
                                            }
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 0
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 50; color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                        Label { text: qsTr("操作"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 60; visible: root.isAdmin; horizontalAlignment: Text.AlignHCenter }
                                                        Label { text: qsTr("序号"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                                                        Label { text: qsTr("借阅者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100; visible: root.isAdmin }
                                                        Label { text: qsTr("单册条码"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100 }
                                                        Label { text: qsTr("题名"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true; Layout.minimumWidth: 120 }
                                                        Label { text: qsTr("作者"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 80 }
                                                        Label { text: qsTr("单册状态"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 70 }
                                                        Label { text: qsTr("借阅日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                        Label { text: qsTr("应还日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                        Label { text: qsTr("归还日期"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 90 }
                                                    }
                                                }
                                                ListView {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; interactive: false; model: root.paginatedDataB
                                                    delegate: Rectangle {
                                                        required property var modelData; required property int index
                                                        width: ListView.view.width; height: root.rowHeight; color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a"); border.color: root.bgSecondary; border.width: 1
                                                        RowLayout {
                                                            Item {
                                                                Layout.preferredWidth: 60; Layout.fillHeight: true; visible: root.isAdmin
                                                                Button {
                                                                    text: qsTr("归还"); anchors.centerIn: parent; width: 45; height: 28; visible: modelData.status === "未归还" || modelData.status === "已逾期"
                                                                    contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                    background: Rectangle { color: root.textPrimary; radius: 3 }
                                                                    onClicked: {
                                                                        if (SystemBridge.returnVolume(modelData.isbn, modelData.volId) === 0) { root.listModelA = SystemBridge.getAllLoanRecords() }
                                                                    }
                                                                }
                                                            }
                                                            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                            Label { text: (root.currentPageB - 1) * root.tableCapacityB + index + 1; color: root.textSecondary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                                                            Label { text: modelData.borrowerId || "-"; color: root.textSecondary; Layout.preferredWidth: 100; visible: root.isAdmin }
                                                            Label { text: modelData.volId || "-"; color: root.textSecondary; Layout.preferredWidth: 100 }
                                                            Label { text: modelData.title || "-"; color: root.textPrimary; font.weight: Font.Bold; Layout.fillWidth: true; Layout.minimumWidth: 120; wrapMode: Text.Wrap; elide: Text.ElideRight; maximumLineCount: 2 }
                                                            Label { text: modelData.author || "-"; color: root.textSecondary; Layout.preferredWidth: 80; elide: Text.ElideRight }
                                                            Label { text: modelData.status || "-"; color: modelData.status === "已逾期" ? root.textPrimary : root.textSecondary; font.weight: modelData.status === "已逾期" ? Font.Bold : Font.Normal; Layout.preferredWidth: 70 }
                                                            Label { text: modelData.borrowDate || "-"; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                            Label { text: modelData.dueDate || "-"; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                            Label { text: modelData.returnDate ? modelData.returnDate : "——"; color: root.textSecondary; Layout.preferredWidth: 90 }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20; visible: root.listModelB.length > 0
                                            Button { text: qsTr("上一页"); enabled: root.currentPageB > 1; onClicked: root.currentPageB--; background: Rectangle { color: "transparent" } }
                                            Label { text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageB).arg(root.totalPagesB); font.pixelSize: 16; color: root.textPrimary; Layout.preferredWidth: 150; horizontalAlignment: Text.AlignHCenter }
                                            Button { text: qsTr("下一页"); enabled: root.currentPageB < root.totalPagesB; onClicked: root.currentPageB++; background: Rectangle { color: "transparent" } }
                                            TextField { id: jumpB; Layout.preferredWidth: 50; validator: IntValidator { bottom: 1; top: root.totalPagesB } }
                                            Button { text: "Go"; onClicked: { let p = parseInt(jumpB.text); if(p >= 1 && p <= root.totalPagesB) { root.currentPageB = p } } }
                                        }
                                    }
                                }

                                // 2.2 借阅统计 (Reader)
                                Item {
                                    id: readerStatsView

                                    property int yBooks: 0
                                    property int yDays: 0
                                    property var monthlyData: []
                                    property var monthLabels: []
                                    property var catData: []
                                    property var langData: []

                                    // 提升为根作用域成员函数，确保符号全局可见
                                    function renderPieChart(ctx, w, h, data) {
                                        ctx.clearRect(0, 0, w, h)
                                        if (!data || data.length === 0) {
                                            ctx.fillStyle = root.textSecondary
                                            ctx.textAlign = "center"
                                            ctx.font = "14px sans-serif"
                                            ctx.fillText("该区间暂无借阅记录", w / 2, h / 2)
                                            return
                                        }

                                        let colors = root.lightMode ? ["#475569", "#64748b", "#94a3b8", "#cbd5e1", "#f1f5f9"] : ["#cbd5e1", "#94a3b8", "#64748b", "#475569", "#334155"]
                                        let cx = w / 2 - 60
                                        let cy = h / 2
                                        let r = Math.min(cx, cy) - 15
                                        let startAngle = -Math.PI / 2

                                        for (let i = 0; i < data.length; i++) {
                                            let sliceAngle = data[i].pct * 2 * Math.PI
                                            ctx.beginPath()
                                            ctx.moveTo(cx, cy)
                                            ctx.arc(cx, cy, r, startAngle, startAngle + sliceAngle)
                                            ctx.closePath()
                                            ctx.fillStyle = colors[i % colors.length]
                                            ctx.fill()
                                            startAngle += sliceAngle
                                        }

                                        let legendX = cx + r + 25
                                        let legendY = cy - (data.length * 20) / 2
                                        ctx.textAlign = "left"
                                        ctx.font = "13px sans-serif"
                                        for (let i = 0; i < data.length; i++) {
                                            ctx.fillStyle = colors[i % colors.length]
                                            ctx.fillRect(legendX, legendY, 14, 14)
                                            ctx.fillStyle = root.textPrimary
                                            ctx.fillText(data[i].name + " (" + data[i].val + ")", legendX + 22, legendY + 12)
                                            legendY += 22
                                        }
                                    }

                                    function computeStats() {
                                        let history = SystemBridge.getBorrowingHistory()
                                        let now = new Date()
                                        let currentYear = now.getFullYear()

                                        let localYB = 0
                                        let localYD = 0
                                        let mData = new Array(12).fill(0)
                                        let mLabels = []
                                        let cData = {}
                                        let lData = {}

                                        for (let m = 11; m >= 0; m--) {
                                            let d = new Date(now.getFullYear(), now.getMonth() - m, 1)
                                            mLabels.push((d.getMonth() + 1) + "月")
                                        }
                                        monthLabels = mLabels

                                        for (let i = 0; i < history.length; i++) {
                                            let rec = history[i]
                                            let bDate = new Date(rec.borrowDate)
                                            let rDate = rec.returnDate ? new Date(rec.returnDate) : now

                                            if (bDate.getFullYear() === currentYear || rDate.getFullYear() === currentYear || (bDate.getFullYear() < currentYear && rDate.getFullYear() >= currentYear)) {
                                                localYB++
                                                let start = bDate.getFullYear() < currentYear ? new Date(currentYear, 0, 1) : bDate
                                                let end = rDate.getFullYear() > currentYear ? new Date(currentYear, 11, 31) : rDate
                                                let diffTime = end.getTime() - start.getTime()
                                                let diffDays = Math.max(1, Math.ceil(diffTime / 86400000))
                                                localYD += diffDays
                                            }

                                            let diffMonths = (now.getFullYear() - bDate.getFullYear()) * 12 + (now.getMonth() - bDate.getMonth())
                                            if (diffMonths >= 0 && diffMonths < 12) {
                                                mData[11 - diffMonths]++
                                                let cat = (rec.category !== undefined && rec.category !== null) ? rec.category : -1
                                                let lang = (rec.language !== undefined && rec.language !== null) ? rec.language : -1
                                                cData[cat] = (cData[cat] || 0) + 1
                                                lData[lang] = (lData[lang] || 0) + 1
                                            }
                                        }

                                        yBooks = localYB
                                        yDays = localYD
                                        monthlyData = mData

                                        let catNames = {1: "文学", 2: "哲学", 3: "语言学", 4: "艺术", 5: "科技"}
                                        let langNames = {1: "中文", 2: "英文", 3: "俄文", 4: "法文", 5: "西班牙文", 6: "阿拉伯文", 7: "日文", 8: "韩文", 9: "其他"}

                                        let processPieData = function(dict, nameMap) {
                                            let arr = []
                                            let total = 0
                                            for (let k in dict) total += dict[k]
                                            for (let k in dict) {
                                                let label = nameMap[k] || "未分类"
                                                arr.push({name: label, val: dict[k], pct: dict[k] / total})
                                            }
                                            return arr.sort((a, b) => b.val - a.val)
                                        }

                                        catData = processPieData(cData, catNames)
                                        langData = processPieData(lData, langNames)

                                        barChartCanvas.requestPaint()
                                        catPieCanvas.requestPaint()
                                        langPieCanvas.requestPaint()
                                    }

                                    Connections {
                                        target: root
                                        function onCurrentSubMenuChanged() {
                                            if (root.currentTopMenu === 2 && root.currentSubMenu === 2 && !root.isAdmin) {
                                                readerStatsView.computeStats()
                                            }
                                        }
                                        function onLightModeChanged() {
                                            if (root.currentTopMenu === 2 && root.currentSubMenu === 2) {
                                                barChartCanvas.requestPaint()
                                                catPieCanvas.requestPaint()
                                                langPieCanvas.requestPaint()
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 20

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 50
                                            ColumnLayout {
                                                spacing: 5
                                                RowLayout {
                                                    spacing: 8
                                                    Label { text: readerStatsView.yBooks; font.pixelSize: 42; font.weight: Font.Bold; color: root.textPrimary }
                                                    Label { text: qsTr("册"); font.pixelSize: 16; color: root.textSecondary; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 6 }
                                                }
                                                Label { text: qsTr("本年度借阅量"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                            }
                                            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 40; color: root.textSecondary }
                                            ColumnLayout {
                                                spacing: 5
                                                RowLayout {
                                                    spacing: 8
                                                    Label { text: readerStatsView.yDays; font.pixelSize: 42; font.weight: Font.Bold; color: root.textPrimary }
                                                    Label { text: qsTr("天"); font.pixelSize: 16; color: root.textSecondary; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 6 }
                                                }
                                                Label { text: qsTr("本年度借阅总天数"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary }
                                            }
                                            Item { Layout.fillWidth: true }
                                        }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }

                                        Label { text: qsTr("近12个月借阅趋势 (册/月)"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary; Layout.topMargin: 10 }
                                        Canvas {
                                            id: barChartCanvas
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 180
                                            onWidthChanged: requestPaint()
                                            onHeightChanged: requestPaint()
                                            onPaint: {
                                                let ctx = getContext("2d")
                                                ctx.clearRect(0, 0, width, height)
                                                let data = readerStatsView.monthlyData
                                                let labels = readerStatsView.monthLabels
                                                if (!data || data.length === 0) return

                                                let maxVal = Math.max(...data) || 1
                                                let barW = 35
                                                let startX = 20
                                                let spacing = (width - 40 - data.length * barW) / (data.length - 1)

                                                ctx.font = "12px sans-serif"
                                                ctx.textAlign = "center"
                                                for (let i = 0; i < data.length; i++) {
                                                    let h = (data[i] / maxVal) * (height - 40)
                                                    let x = startX + i * (barW + spacing)
                                                    let y = height - 30 - h

                                                    ctx.fillStyle = root.textPrimary
                                                    ctx.fillRect(x, y, barW, h)

                                                    ctx.fillStyle = root.textSecondary
                                                    ctx.fillText(labels[i], x + barW / 2, height - 10)
                                                    if (data[i] > 0) {
                                                        ctx.fillStyle = root.textPrimary
                                                        ctx.fillText(data[i], x + barW / 2, y - 8)
                                                    }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 20

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Label { text: qsTr("近一年借阅分类占比"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary; Layout.alignment: Qt.AlignHCenter }
                                                Canvas { 
                                                    id: catPieCanvas
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    onWidthChanged: requestPaint()
                                                    onHeightChanged: requestPaint()
                                                    onPaint: readerStatsView.renderPieChart(getContext("2d"), width, height, readerStatsView.catData)
                                                }
                                            }
                                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: root.textSecondary }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Label { text: qsTr("近一年借阅语种占比"); font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary; Layout.alignment: Qt.AlignHCenter }
                                                Canvas { 
                                                    id: langPieCanvas
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    onWidthChanged: requestPaint()
                                                    onHeightChanged: requestPaint()
                                                    onPaint: readerStatsView.renderPieChart(getContext("2d"), width, height, readerStatsView.langData)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ==========================================
                        // Page 3: 个人信息
                        // ==========================================
                        Item {
                            StackLayout {
                                anchors.fill: parent
                                currentIndex: root.currentSubMenu
                                
                                Item {
                                    ColumnLayout {
                                        anchors.margins: 40; spacing: 25
                                        Label { text: qsTr("账户资料"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                        GridLayout {
                                            columns: 2; rowSpacing: 20; columnSpacing: 40
                                            Label { text: qsTr("用户 ID :"); font.pixelSize: 18; color: root.textSecondary }
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
                                
                                // 3.1 复合业务节点
                                Item {
                                    // 轨 1：读者信息修改
                                    ColumnLayout {
                                        anchors.margins: 40; spacing: 20; visible: !root.isAdmin
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

                                    // 轨 2：Admin 读者管理全域模块
                                    ColumnLayout {
                                        anchors.margins: 40; spacing: 20; anchors.fill: parent; visible: root.isAdmin
                                        Label { text: qsTr("读者管理"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary }
                                        Rectangle { Layout.fillWidth: true; height: 1; color: root.textPrimary }
                                        
                                        RowLayout {
                                            spacing: 15
                                            TextField { 
                                                id: adminSearchReaderId
                                                Layout.preferredWidth: 250; Layout.preferredHeight: 40
                                                placeholderText: qsTr("输入读者 ID 以检索")
                                                font.pixelSize: 16; color: root.textPrimary
                                                background: Rectangle { border.color: root.textSecondary; border.width: 1; color: "transparent" }
                                            }
                                            Button {
                                                text: qsTr("检索")
                                                Layout.preferredWidth: 100; Layout.preferredHeight: 40
                                                background: Rectangle { color: root.textPrimary; radius: 3 }
                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                onClicked: {
                                                    root.listModelC = SystemBridge.searchReaders(adminSearchReaderId.text)
                                                    root.currentPageC = 1
                                                }
                                            }
                                            Item { Layout.fillWidth: true }
                                        }

                                        Item {
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            onHeightChanged: { 
                                                let r = Math.floor((height - 50) / 75)
                                                let newCapacity = Math.max(4, r)
                                                if (root.tableCapacityC !== newCapacity) {
                                                    root.tableCapacityC = newCapacity
                                                    root.currentPageC = 1
                                                }
                                            }
                                            ColumnLayout {
                                                anchors.fill: parent; spacing: 0
                                                Rectangle {
                                                    Layout.fillWidth: true; height: 50; color: root.bgSecondary; border.color: root.textSecondary; border.width: 1
                                                    RowLayout {
                                                        anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 10
                                                        Label { text: qsTr("操作"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignHCenter }
                                                        Label { text: qsTr("账户ID"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 150 }
                                                        Label { text: qsTr("用户名"); font.bold: true; color: root.textPrimary; Layout.preferredWidth: 250 }
                                                        Label { text: qsTr("账户状态"); font.bold: true; color: root.textPrimary; Layout.fillWidth: true }
                                                    }
                                                }
                                                ListView {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; interactive: false; spacing: 10; model: root.paginatedDataC
                                                    delegate: Rectangle {
                                                        required property var modelData; required property int index
                                                        width: ListView.view.width; height: 75; color: index % 2 === 0 ? "transparent" : (root.lightMode ? "#f5f5f5" : "#2a2a2a"); border.color: root.textSecondary; border.width: 1
                                                        RowLayout {
                                                            anchors.fill: parent; anchors.margins: 15; spacing: 15
                                                            
                                                            Button {
                                                                text: qsTr("更新")
                                                                Layout.preferredWidth: 100; Layout.preferredHeight: 35
                                                                background: Rectangle { color: root.textPrimary; radius: 3 }
                                                                contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                                                onClicked: {
                                                                    let isValidStatus = (validityBox.currentIndex === 1)
                                                                    let st = SystemBridge.updateReaderStatusByAdmin(modelData.id, editReaderName.text, isValidStatus)
                                                                    if (st === 0) {
                                                                        messageDialog.messageText = "账户(" + modelData.id + ")信息已更新。"
                                                                        messageDialog.open()
                                                                        root.listModelC = SystemBridge.searchReaders(adminSearchReaderId.text)
                                                                    } else {
                                                                        messageDialog.messageText = "错误：账户(" + modelData.id + ")有未归还单册，不可冻结或注销。"
                                                                        messageDialog.open()
                                                                    }
                                                                }
                                                            }
                                                            Label { text: modelData.id; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary; Layout.preferredWidth: 150 }
                                                            TextField { 
                                                                id: editReaderName; text: modelData.name; Layout.preferredWidth: 250; font.pixelSize: 16; color: root.textPrimary
                                                                background: Rectangle { border.color: root.textSecondary; border.width: 1; color: root.bgPrimary }
                                                            }
                                                            ComboBox {
                                                                id: validityBox
                                                                model: [qsTr("不可用 (False)"), qsTr("可用 (True)")]
                                                                currentIndex: modelData.isValid ? 1 : 0
                                                                Layout.preferredWidth: 200; font.pixelSize: 14
                                                            }
                                                            Item { Layout.fillWidth: true }
                                                        }
                                                    }
                                                } 
                                            }
                                        }

                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter; spacing: 20; visible: root.listModelC.length > 0
                                            Button { text: qsTr("上一页"); enabled: root.currentPageC > 1; onClicked: root.currentPageC--; background: Rectangle { color: "transparent" } }
                                            Label { 
                                                text: qsTr("第 %1 页 / 共 %2 页").arg(root.currentPageC).arg(root.totalPagesC)
                                                font.pixelSize: 16; color: root.textPrimary; Layout.preferredWidth: 150; horizontalAlignment: Text.AlignHCenter
                                            }
                                            Button { text: qsTr("下一页"); enabled: root.currentPageC < root.totalPagesC; onClicked: root.currentPageC++; background: Rectangle { color: "transparent" } }
                                            TextField { id: jumpReader; Layout.preferredWidth: 50; validator: IntValidator { bottom: 1; top: root.totalPagesC } }
                                            Button { text: "Go"; onClicked: { let p = parseInt(jumpReader.text); if (p >= 1 && p <= root.totalPagesC) root.currentPageC = p } }
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
                                anchors.fill: parent; currentIndex: root.currentSubMenu
                                Item {
                                    ColumnLayout {
                                        anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 40; spacing: 20
                                        ColumnLayout { Layout.fillWidth: true; spacing: 6; Label { text: qsTr("界面偏好"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary } Rectangle { Layout.preferredWidth: 500; height: 1; color: root.textPrimary } }
                                        RowLayout { spacing: 20; Layout.topMargin: 10; Label { text: qsTr("界面主题"); font.pixelSize: 18; color: root.textPrimary } Button { text: root.lightMode ? qsTr("切换至黑暗模式") : qsTr("切换至明亮模式"); contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } background: Rectangle { color: root.textPrimary; radius: 3; implicitWidth: 140; implicitHeight: 35 } onClicked: root.lightMode = !root.lightMode } }
                                    }
                                }
                                Item {
                                    ColumnLayout {
                                        anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 40; spacing: 20
                                        ColumnLayout { Layout.fillWidth: true; spacing: 6; Label { text: qsTr("数据库连接状态"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary } Rectangle { Layout.preferredWidth: 600; height: 1; color: root.textPrimary } }
                                        GridLayout { Layout.topMargin: 15; columns: 2; rowSpacing: 25; columnSpacing: 40; Label { text: qsTr("底层驱动引擎:"); font.pixelSize: 18; color: root.textSecondary } Label { text: "QSQLITE"; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary } Label { text: qsTr("活动连接句柄:"); font.pixelSize: 18; color: root.textSecondary } Label { text: "qt_sql_default_connection"; font.pixelSize: 18; font.weight: Font.Bold; color: root.textPrimary } }
                                    }
                                }
                                Item {
                                    ColumnLayout {
                                        anchors.centerIn: parent; spacing: 35
                                        Label { text: qsTr("安全注销"); font.pixelSize: 32; font.weight: Font.Bold; color: root.textPrimary; Layout.alignment: Qt.AlignHCenter }
                                        RowLayout { Layout.alignment: Qt.AlignHCenter; spacing: 40; Layout.topMargin: 20; Button { text: qsTr("确认注销 (回主页)"); Layout.preferredWidth: 200; Layout.preferredHeight: 50; contentItem: Text { text: parent.text; color: root.bgPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } background: Rectangle { color: root.textPrimary; radius: 5 } onClicked: { SystemBridge.logout(); if (typeof debugLoader !== "undefined") { debugLoader.active = false } } } Button { text: qsTr("终止程序进程"); Layout.preferredWidth: 200; Layout.preferredHeight: 50; contentItem: Text { text: parent.text; color: root.textPrimary; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } background: Rectangle { color: "transparent"; border.color: root.textPrimary; border.width: 1; radius: 5 } onClicked: { SystemBridge.logout(); Qt.exit(0) } } }
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