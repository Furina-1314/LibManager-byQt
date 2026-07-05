#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "header/DatabaseManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 实例化数据库控制器，其生命周期为整个 main 函数作用域
    DatabaseController dbController;

    // 建库建表与预编译初始化
    ErrorCode dbStatus = dbController.initializeDatabase();
    if (dbStatus != ErrorCode::SUCCESS) {
        qCritical() << "致命错误：数据库初始化失败，程序即将退出。错误码：" << static_cast<int>(dbStatus);
        return -1; // 数据库未能正常挂载，阻断后续所有 UI 渲染与业务逻辑
    }

    // ==========================================
    // 2. 预先注入初始管理员账号 🛡️
    // ==========================================
    AccountDAO acDAO;
    AdminAccount defaultAdmin;
    AdminID adminId;

    // 依据底层校验规范：AdminID 必须为5位非零开头的纯数字
    if (adminId.SetValue("10000") == ErrorCode::SUCCESS) {
        defaultAdmin.SetID(adminId);
        // 依据底层校验规范：密码长度必须 >= 8 位
        defaultAdmin.SetPassword("MySerenades");
        defaultAdmin.SetIsValid(true);
        defaultAdmin.ActivateAdmin(Auth::Admin);

        // 探测数据库中是否已存在该 ID，避免每次系统冷启动时触发重复插入（或主键冲突）
        if (acDAO.isUserExists("10000") == ErrorCode::USERID_NOT_EXIST) {
            ErrorCode insertStatus = acDAO.updateAdminInfo(defaultAdmin);
            if (insertStatus == ErrorCode::SUCCESS) {
                qDebug() << "初始管理员已生成 - 账号: 10000 | 密码: MySerenades";
            }
            else {
                qWarning() << "初始管理员注入失败，错误码：" << static_cast<int>(insertStatus);
            }
        }
    }
    // ==========================================

    // 3. 加载前端 QML 引擎
    
    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("LibManager", "Main");

    return QGuiApplication::exec();
}
