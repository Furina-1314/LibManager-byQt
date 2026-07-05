#include "header/SystemBridge.h"
// 引入后端实现
#include "src/UserService.cpp" 
#include "header/Stats.h"
#include <QVariantMap>
#include <algorithm>

// ==========================================
// 属性 Getter 实现
// ==========================================
QString SystemBridge::currentUserName() const {
    if (m_isAdmin && m_currentAdmin.has_value()) return m_currentAdmin->qs_Name();
    if (!m_isAdmin && m_currentReader.has_value()) return m_currentReader->qs_Name();
    return QString("未登录");
}

QString SystemBridge::currentUserId() const {
    if (m_isAdmin && m_currentAdmin.has_value()) return m_currentAdmin->c_ID().qs_Value();
    if (!m_isAdmin && m_currentReader.has_value()) return m_currentReader->c_ID().qs_Value();
    return QString("-");
}

QString SystemBridge::currentAuthType() const {
    if (m_isAdmin) return QString("系统管理员 (Admin)");
    if (m_currentReader.has_value()) {
        return m_currentReader->enum_ReaderAuth() == Auth::Reader ? QString("普通读者 (Reader)") : QString("未知权限");
    }
    return QString("-");
}

int SystemBridge::currentBorrowLimit() const {
    if (m_isAdmin) return 0;
    if (m_currentReader.has_value()) return m_currentReader->i_BorrowLimit();
    return 0;
}

int SystemBridge::loginReader(const QString& userid, const QString& password) {
    ReaderAccount account;
    UserID uid;

    // 1. 数据校验与转换
    ErrorCode idStatus = uid.SetValue(userid);
    if (idStatus != ErrorCode::SUCCESS) {
        emit loginError("非法的读者账号格式");
        return static_cast<int>(idStatus);
    }

    account.SetID(uid);

    // 2. 调用底层静态业务
    ErrorCode status = Login::UserLogin(account, password);

    // 3. 状态机流转
    if (status == ErrorCode::SUCCESS) {
        m_currentReader = account;
        m_isAdmin = false;
        // 清除旧的 admin 状态
        m_currentAdmin = AdminAccount();

        emit userInfoChanged();
    }
    else {
        emit loginError("读者登录失败，错误码：" + QString::number(static_cast<int>(status)));
    }

    return static_cast<int>(status);
}

int SystemBridge::loginAdmin(const QString& userid, const QString& password) {
    AdminAccount account;
    AdminID adminId;

    // 1. 数据校验与转换
    ErrorCode idStatus = adminId.SetValue(userid);
    if (idStatus != ErrorCode::SUCCESS) {
        emit loginError("非法的管理员账号格式");
        return static_cast<int>(idStatus);
    }

    account.SetID(adminId);

    // 2. 调用底层静态业务
    ErrorCode status = Login::UserLogin(account, password);

    // 3. 状态机流转
    if (status == ErrorCode::SUCCESS) {
        m_currentAdmin = account;
        m_isAdmin = true;
        // 清除旧的 reader 状态
        m_currentReader = ReaderAccount();

        emit userInfoChanged();
    }
    else {
        emit loginError("管理员登录失败，错误码：" + QString::number(static_cast<int>(status)));
    }

    return static_cast<int>(status);
}

void SystemBridge::logout() {
    m_currentReader.reset();
    m_currentAdmin.reset();
    m_isAdmin = false;    emit userInfoChanged();
}

int SystemBridge::registerReader(const QString& userid, const QString& username, const QString& password, const QString& confirmPassword) {
    UserID uid;

    // 1. 严格的数据类型前置校验
    ErrorCode idStatus = uid.SetValue(userid);
    if (idStatus != ErrorCode::SUCCESS) {
        emit loginError("非法的读者账号格式，ID需为8位非零开头数字");
        return static_cast<int>(idStatus);
    }

    // 2. 调用后端静态注册服务
    ErrorCode status = Register::UserRegister(uid, username, password, confirmPassword, Auth::Reader);

    // 3. 状态分发
    if (status != ErrorCode::SUCCESS) {
        // 利用现有的 loginError 信号触发前端弹窗
        emit loginError("注册受阻，错误码：" + QString::number(static_cast<int>(status)));
    }

    return static_cast<int>(status);
}

// ==========================================
// 🚀 新增：修改信息综合接口
// ==========================================
int SystemBridge::updateUserInfo(const QString& currentPwd, const QString& newName, const QString& newPwd, const QString& confirmPwd) {
    if (m_isAdmin) {
        emit loginError("系统管理员 (Admin) 暂不支持在前端终端修改账户信息。");
        return static_cast<int>(ErrorCode::NO_ACCESS);
    }
    if (!m_currentReader.has_value()) return static_cast<int>(ErrorCode::ACCOUNT_INVALID);

    ReaderAccount temp = m_currentReader.value();

    // 1. 若填写了新用户名，执行更新
    if (!newName.isEmpty() && newName != temp.qs_Name()) {
        ErrorCode status = EditProfile::EditName(temp, currentPwd, newName);
        if (status != ErrorCode::SUCCESS) {
            emit loginError("修改用户名受阻，错误码：" + QString::number(static_cast<int>(status)));
            return static_cast<int>(status);
        }
    }

    // 2. 若填写了新密码，执行更新
    if (!newPwd.isEmpty()) {
        ErrorCode status = EditProfile::EditPassword(temp, currentPwd, newPwd, confirmPwd);
        if (status != ErrorCode::SUCCESS) {
            emit loginError("修改密码受阻，错误码：" + QString::number(static_cast<int>(status)));
            return static_cast<int>(status);
        }
    }

    // 3. 内存状态与 UI 同步
    m_currentReader.emplace(temp);
    emit userInfoChanged();
    return static_cast<int>(ErrorCode::SUCCESS);
}

// ----------------------------------------------------
// 获取个人借阅历史 (Reader)
// ----------------------------------------------------
QVariantList SystemBridge::getBorrowingHistory() {
    QVariantList historyList;
    if (m_isAdmin || !m_currentReader.has_value()) return historyList;

    LoanRecordDAO lrDAO;
    LoanRecord queryLr;
    queryLr.SetBorrowerID(m_currentReader->c_ID());
    QList<Filter> filters = { Filter::BorrowerID };
    QList<LoanRecord> records;

    ErrorCode status = lrDAO.getLoanRecord(queryLr, QDate(1970, 1, 1), QDate(2100, 1, 1), filters, records);
    if (status != ErrorCode::SUCCESS) return historyList;

    // 🚀 核心修改：按借阅日期自新到旧排序
    std::sort(records.begin(), records.end(), [](const LoanRecord& a, const LoanRecord& b) {
        return a.qd_BorrowDate() > b.qd_BorrowDate();
        });

    BookDAO bDAO;
    for (const LoanRecord& lr : records) {
        QVariantMap map;
        map["borrowerId"] = lr.c_BorrowerID().qs_Value();
        map["borrowDate"] = lr.qd_BorrowDate().toString("yyyy-MM-dd");
        map["dueDate"] = lr.qd_DueDate().toString("yyyy-MM-dd");

        // 🚀 核心新增：单册状态逻辑计算
        QString statusStr = "已归还";
        if (!lr.b_IsReturned()) {
            statusStr = lr.b_IsOverdue() ? "已逾期" : "未归还";
        }
        map["status"] = statusStr;

        QList<Book> books;
        if (bDAO.getBookInfobyISBN(lr.c_ISBN().qs_Value(), books) == ErrorCode::SUCCESS && !books.isEmpty()) {
            Book bk = books[0];
            map["title"] = bk.qs_Name();
            map["author"] = bk.ql_Author().join(", ");

            if (bDAO.getVolumeInfo(bk) == ErrorCode::SUCCESS) {
                for (const Volume& vol : bk.ql_VolumeList()) {
                    if (vol.c_VolID().qs_Value() == lr.c_VolID().qs_Value()) {
                        BookLocation loc = vol.stct_Location();
                        map["location"] = QString("分馆代码:%1 | %2层 | 区代码:%3 | %4架%5层")
                            .arg(static_cast<int>(loc.libraryID)).arg(loc.floor)
                            .arg(static_cast<int>(loc.areaID)).arg(loc.shelf).arg(loc.layer);
                        break;
                    }
                }
            }
        }
        else {
            map["title"] = "数据脱机"; map["author"] = "-"; map["location"] = "-";
        }
        historyList.append(map);
    }
    return historyList;
}

// ----------------------------------------------------
// 获取全域借阅流水 (Admin)
// ----------------------------------------------------
QVariantList SystemBridge::getAllLoanRecords() {
    QVariantList historyList;
    if (!m_isAdmin) return historyList; // 严密权限拦截

    LoanRecordDAO lrDAO;
    LoanRecord queryLr;
    QList<Filter> filters; // 空过滤条件，拉取全库
    QList<LoanRecord> records;

    ErrorCode status = lrDAO.getLoanRecord(queryLr, QDate(1970, 1, 1), QDate(2100, 1, 1), filters, records);
    if (status != ErrorCode::SUCCESS) return historyList;

    // 🚀 按借阅日期自新到旧排序
    std::sort(records.begin(), records.end(), [](const LoanRecord& a, const LoanRecord& b) {
        return a.qd_BorrowDate() > b.qd_BorrowDate();
        });

    BookDAO bDAO;
    for (const LoanRecord& lr : records) {
        QVariantMap map;
        map["borrowerId"] = lr.c_BorrowerID().qs_Value();
        map["borrowDate"] = lr.qd_BorrowDate().toString("yyyy-MM-dd");
        map["dueDate"] = lr.qd_DueDate().toString("yyyy-MM-dd");

        QString statusStr = "已归还";
        if (!lr.b_IsReturned()) {
            statusStr = lr.b_IsOverdue() ? "已逾期" : "未归还";
        }
        map["status"] = statusStr;

        QList<Book> books;
        if (bDAO.getBookInfobyISBN(lr.c_ISBN().qs_Value(), books) == ErrorCode::SUCCESS && !books.isEmpty()) {
            Book bk = books[0];
            map["title"] = bk.qs_Name();
            map["author"] = bk.ql_Author().join(", ");
            if (bDAO.getVolumeInfo(bk) == ErrorCode::SUCCESS) {
                for (const Volume& vol : bk.ql_VolumeList()) {
                    if (vol.c_VolID().qs_Value() == lr.c_VolID().qs_Value()) {
                        BookLocation loc = vol.stct_Location();
                        map["location"] = QString("分馆代码:%1 | %2层 | 区代码:%3 | %4架%5层")
                            .arg(static_cast<int>(loc.libraryID)).arg(loc.floor)
                            .arg(static_cast<int>(loc.areaID)).arg(loc.shelf).arg(loc.layer);
                        break;
                    }
                }
            }
        }
        else {
            map["title"] = "数据脱机"; map["author"] = "-"; map["location"] = "-";
        }
        historyList.append(map);
    }
    return historyList;
}

int SystemBridge::currentBorrowedCount() const {
    if (!m_currentReader.has_value() || m_isAdmin) return 0;
    int count = 0;
    // 探查该读者当前未归还的单册总量
    if (Stats::getReaderCountbyNotReturned(m_currentReader.value(), count) == ErrorCode::SUCCESS) {
        return count;
    }
    return 0;
}

int SystemBridge::currentOverdueCount() const {
    if (!m_currentReader.has_value() || m_isAdmin) return 0;
    int count = 0;
    // 探查该读者当前已逾期的单册总量
    if (Stats::getReaderCountbyOverdue(m_currentReader.value(), count) == ErrorCode::SUCCESS) {
        return count;
    }
    return 0;
}