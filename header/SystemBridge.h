#pragma once
#include <QObject>
#include <QtQml/qqmlregistration.h>
#include <QQmlEngine>
#include <QJSEngine>
#include <QString>
#include <QVariantList>
#include <QDebug>
#include <optional>

// 包含现有的后端头文件（此处直接复用已有的实体类和业务逻辑）
#include "header/TypeCode.h"
#include "header/DataTemplates.h"
#include "header/DatabaseManager.h"

// 前向声明业务类，或直接在 cpp 中 include 对应的业务 cpp
class Login;

class SystemBridge : public QObject {
    Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        // 向 QML 暴露的属性：用户名与权限状态
        Q_PROPERTY(QString currentUserName READ currentUserName NOTIFY userInfoChanged)
        Q_PROPERTY(bool isAdmin READ isAdmin NOTIFY userInfoChanged)
        Q_PROPERTY(QString currentUserId READ currentUserId NOTIFY userInfoChanged)
        Q_PROPERTY(QString currentAuthType READ currentAuthType NOTIFY userInfoChanged)
        Q_PROPERTY(int currentBorrowLimit READ currentBorrowLimit NOTIFY userInfoChanged)
        Q_PROPERTY(int currentBorrowedCount READ currentBorrowedCount NOTIFY userInfoChanged)
        Q_PROPERTY(int currentOverdueCount READ currentOverdueCount NOTIFY userInfoChanged)

public:
    explicit SystemBridge(QObject* parent = nullptr) : QObject(parent), m_isAdmin(false) {}

    // Qt 6 单例工厂函数
    static SystemBridge* create(QQmlEngine*, QJSEngine*) {
        return new SystemBridge();
    }

    // Getter 接口
    QString currentUserName() const;
    bool isAdmin() const { return m_isAdmin; }
    QString currentUserId() const;
    QString currentAuthType() const;
    int currentBorrowLimit() const;
    int currentBorrowedCount() const;
    int currentOverdueCount() const;

    // ==========================================
    // 🗃️ Q_INVOKABLE: 暴露给 QML 的核心业务接口
    // ==========================================

    // 读者登录
    Q_INVOKABLE int loginReader(const QString& userid, const QString& password);

    // 管理员登录
    Q_INVOKABLE int loginAdmin(const QString& userid, const QString& password);

    // 退出登录清除状态
    Q_INVOKABLE void logout();

    // 读者注册
    Q_INVOKABLE int registerReader(const QString& userid, const QString& username, const QString& password, const QString& confirmPassword);

    // 修改个人信息
    Q_INVOKABLE int updateUserInfo(const QString& currentPwd, const QString& newName, const QString& newPwd, const QString& confirmPwd);

    // 查询当前读者借阅历史，并打包为前端可直接绑定的 QVariantList
    Q_INVOKABLE QVariantList getBorrowingHistory();

    // 供系统管理员使用的全局借阅流水获取接口
    Q_INVOKABLE QVariantList getAllLoanRecords();

    // 多条件组合高级检索接口
    Q_INVOKABLE QVariantList advancedSearch(const QString& isbn, const QString& volId, int statusIndex, const QString& startDate, const QString& endDate);

    // ----------------------------------------------------
    // 图书业务核心接口
    // ----------------------------------------------------
    Q_INVOKABLE QVariantList searchBooks(const QString& keyword);
    // 新增高级检索接口
    Q_INVOKABLE QVariantList advancedSearchBooks(const QString& title, const QString& author, const QString& press, const QString& isbn);
    Q_INVOKABLE QVariantList getPopularBooks();
    Q_INVOKABLE QVariantMap getBookDetails(const QString& isbn);

    // 读者单册借阅
    Q_INVOKABLE int borrowVolume(const QString& isbn, const QString& volId);

    // 管理员图书维护接口
    Q_INVOKABLE int saveBook(const QString& isbn, const QString& title, const QString& author, const QString& press, int pubYear, int category, int language, const QString& intro);
    Q_INVOKABLE int deleteBook(const QString& isbn);
    Q_INVOKABLE int saveVolume(const QString& isbn, const QString& volId, int lib, int floor, int area, int shelf, int layer, int availability, bool isOpenshelf, const QString& note);
    Q_INVOKABLE int deleteVolume(const QString& isbn, const QString& volId);
    Q_INVOKABLE int returnVolume(const QString& isbn, const QString& volId);

signals:
    void userInfoChanged();
    void loginError(const QString& errorMsg);

private:
    bool m_isAdmin;
    std::optional<ReaderAccount> m_currentReader;
    std::optional<AdminAccount> m_currentAdmin;
};