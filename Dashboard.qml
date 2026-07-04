pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

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
    // 🗃️ 视图状态与数据绑定
    // ==========================================
    property string userName: "Admin" 
    property int currentTopMenu: 0    
    property int currentSubMenu: 0    

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
                    text: qsTr("欢迎您，%1！").arg(root.userName)
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: root.textPrimary
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 30

                    Repeater {
                        model: [qsTr("主页"), qsTr("图书业务"), qsTr("个人信息"), qsTr("系统设置")]
                        
                        Button {
                            id: topMenuBtn
                            
                            required property int index
                            required property string modelData

                            text: topMenuBtn.modelData
                            font.pixelSize: 18
                            
                            contentItem: Text {
                                text: topMenuBtn.text
                                color: root.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                
                                font.pixelSize: topMenuBtn.font.pixelSize
                                font.bold: root.currentTopMenu === topMenuBtn.index
                                font.underline: root.currentTopMenu === topMenuBtn.index
                            }
                            
                            background: Item {} 
                            
                            onClicked: {
                                root.currentSubMenu = 0; 
                                root.currentTopMenu = topMenuBtn.index;
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

                        // Page 2: 个人信息
                        Item {
                            Label {
                                text: root.getSafeSubMenuName(2, root.currentSubMenu) + qsTr(" 详情界面接入点")
                                font.pixelSize: 20
                                color: root.textSecondary
                                anchors.centerIn: parent
                            }
                        }

                        // Page 3: 系统设置
                        Item {
                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 40 
                                spacing: 20 // 调整组件间距

                                // --------------------------------------
                                // 【板块一】：系统设置
                                // --------------------------------------
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6 // 强行拉近大标题与横线的距离

                                    Label {
                                        text: qsTr("系统设置")
                                        font.pixelSize: 32
                                        font.weight: Font.Bold
                                        color: root.textPrimary
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: root.textPrimary
                                    }
                                }

                                // 系统设置的内容项
                                ColumnLayout {
                                    spacing: 20
                                    Layout.fillWidth: true
                                    Layout.topMargin: 10 // 让内容与上方分割线保持合适间距

                                    RowLayout {
                                        spacing: 20
                                        Label {
                                            text: qsTr("界面主题")
                                            font.pixelSize: 18
                                            color: root.textPrimary
                                        }
                
                                        Button {
                                            id: modeBtn
                                            text: root.lightMode ? qsTr("切换至黑暗模式") : qsTr("切换至明亮模式")
                                            font.pixelSize: 16
                    
                                            contentItem: Text {
                                                text: modeBtn.text
                                                font: modeBtn.font
                                                color: root.bgPrimary
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: 10
                                                rightPadding: 10
                                            }
                                            background: Rectangle {
                                                color: root.textPrimary
                                                radius: 2
                                            }
                                            onClicked: root.lightMode = !root.lightMode
                                        }
                                    }

                                    RowLayout {
                                        spacing: 20
                                        Label {
                                            text: qsTr("系统语言")
                                            font.pixelSize: 18
                                            color: root.textPrimary
                                        }
                                        Label {
                                            text: qsTr("简体中文")
                                            font.pixelSize: 18
                                            color: root.textSecondary
                                        }
                                    }
                                }

                                // --------------------------------------
                                // 【间距隔离层】：显式拉开板块间的物理高度
                                // --------------------------------------
                                Item {
                                    Layout.preferredHeight: 50 // 精确控制两个板块之间的空隙距离
                                    Layout.fillWidth: true
                                }

                                // --------------------------------------
                                // 【板块二】：关于
                                // --------------------------------------
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6 // 同步拉近“关于”标题与横线的距离

                                    Label {
                                        text: qsTr("关于")
                                        font.pixelSize: 32
                                        font.weight: Font.Bold
                                        color: root.textPrimary
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: root.textPrimary
                                    }
                                }

                                // 关于的内容项
                                ColumnLayout {
                                    spacing: 20
                                    Layout.fillWidth: true
                                    Layout.topMargin: 10

                                    RowLayout {
                                        spacing: 20
                                        Label {
                                            text: qsTr("系统版本")
                                            font.pixelSize: 18
                                            color: root.textPrimary
                                        }
                                        Label {
                                            text: qsTr("0.0.1")
                                            font.pixelSize: 18
                                            color: root.textSecondary
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
            case 2: return [qsTr("账户资料"), qsTr("修改密码"), qsTr("权限状态")];
            case 3: return [qsTr("界面偏好"), qsTr("数据库连接状态")];
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