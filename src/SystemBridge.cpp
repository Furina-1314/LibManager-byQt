#include "header/SystemBridge.h"
// 引入后端实现
#include "src/UserService.cpp" 
#include "src/LibraryService.cpp"
#include "header/Stats.h"
#include <QVariantMap>
#include <algorithm>

// 辅助函数，用于转换馆藏位置枚举
static QString formatLocation(const BookLocation& loc) {
    QString libStr, areaStr;
    switch (loc.libraryID) {
    case Library::LIB_North: libStr = "主馆北馆"; break;
    case Library::LIB_West: libStr = "主馆西馆"; break;
    case Library::LIB_Economic: libStr = "经管图书馆"; break;
    case Library::LIB_Literature: libStr = "人文社科图书馆"; break;
    case Library::LIB_Law: libStr = "法律图书馆"; break;
    default: libStr = "未知馆"; break;
    }
    switch (loc.areaID) {
    case Area::AREA_E: areaStr = "东区"; break;
    case Area::AREA_W: areaStr = "西区"; break;
    case Area::AREA_S: areaStr = "南区"; break;
    case Area::AREA_N: areaStr = "北区"; break;
    default: areaStr = "未知区"; break;
    }
    return QString("%1  %2层  %3  %4架  %5层").arg(libStr).arg(loc.floor).arg(areaStr).arg(loc.shelf).arg(loc.layer);
}

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

// ----------------------------------------------------
// 高级条件检索 (复用底层 LoanRecordDAO)
// statusIndex 映射: 0=全部, 1=已归还, 2=未归还, 3=已逾期
// ----------------------------------------------------
QVariantList SystemBridge::advancedSearch(const QString& isbn, const QString& volId, int statusIndex, const QString& startDate, const QString& endDate) {
    QVariantList resultList;
    if (!m_isAdmin && !m_currentReader.has_value()) return resultList;

    LoanRecordDAO lrDAO;
    LoanRecord queryLr;
    QList<Filter> filters;

    // 1. 权限隔离：如果不是管理员，强制注入 BorrowerID 过滤条件
    if (!m_isAdmin) {
        queryLr.SetBorrowerID(m_currentReader->c_ID());
        filters.append(Filter::BorrowerID);
    }

    // 2. 动态装配查询条件
    if (!isbn.trimmed().isEmpty()) {
        ISBN iso; iso.SetValue(isbn.trimmed());
        queryLr.SetBookISBN(iso);
        filters.append(Filter::ISBN);
    }

    if (!volId.trimmed().isEmpty()) {
        VolumeID v; v.SetValue(volId.trimmed());
        queryLr.SetVolumeID(v);
        filters.append(Filter::VolID);
    }

    if (statusIndex == 1) { // 已归还
        queryLr.SetIsReturned(true);
        filters.append(Filter::IsReturned);
    }
    else if (statusIndex == 2) { // 未归还
        queryLr.SetIsReturned(false);
        filters.append(Filter::IsReturned);
    }
    else if (statusIndex == 3) { // 已逾期
        queryLr.SetIsReturned(false);
        queryLr.SetIsOverdue(true);
        filters.append(Filter::IsReturned);
        filters.append(Filter::IsOverdue);
    }

    // 3. 处理时间区间
    QDate sDate(1970, 1, 1);
    QDate eDate(2100, 1, 1);
    if (!startDate.trimmed().isEmpty()) {
        QDate parsed = QDate::fromString(startDate.trimmed(), "yyyy-MM-dd");
        if (parsed.isValid()) sDate = parsed;
    }
    if (!endDate.trimmed().isEmpty()) {
        QDate parsed = QDate::fromString(endDate.trimmed(), "yyyy-MM-dd");
        if (parsed.isValid()) eDate = parsed;
    }

    // 4. 执行查询
    QList<LoanRecord> records;
    ErrorCode status = lrDAO.getLoanRecord(queryLr, sDate, eDate, filters, records);
    if (status != ErrorCode::SUCCESS) return resultList;

    // 5. 自新到旧降序排序
    std::sort(records.begin(), records.end(), [](const LoanRecord& a, const LoanRecord& b) {
        return a.qd_BorrowDate() > b.qd_BorrowDate();
        });

    // 6. 数据组装 (与全量查询复用映射逻辑)
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
        resultList.append(map);
    }
    return resultList;
}

// ----------------------------------------------------
// 图书检索与展示
// ----------------------------------------------------
QVariantList SystemBridge::searchBooks(const QString& keyword) {
    QVariantList res;
    BookDAO dao;
    QList<Book> books;
    QList<QString> kws;
    if (!keyword.trimmed().isEmpty()) kws.append(keyword.trimmed());
    else kws.append("");

    if (dao.getBookInfobyTitle(kws, books) == ErrorCode::SUCCESS) {
        for (Book& b : books) {
            QVariantMap m;
            m["isbn"] = b.c_BookISBN().qs_Value();
            m["title"] = b.qs_Name();
            m["author"] = b.ql_Author().join(", ");
            m["press"] = b.qs_Press();
            m["pubYear"] = b.i_PubYear();

            // 挂载单册信息以判定可用性与馆藏地
            dao.getVolumeInfo(b);
            bool hasAvailable = false;
            QString locStr = "无馆藏信息";
            const auto& vols = b.ql_VolumeList();

            if (!vols.isEmpty()) {
                for (const auto& v : vols) {
                    if (v.enum_IsAvailable() == Availability::Available) {
                        hasAvailable = true;
                        locStr = formatLocation(v.stct_Location());
                        if (vols.size() > 1) locStr += " 等馆藏地";
                        break;
                    }
                }
                // 若无可用单册，但存在实体，则默认展示第一本单册的位置
                if (!hasAvailable) {
                    locStr = formatLocation(vols[0].stct_Location());
                    if (vols.size() > 1) locStr += " 等馆藏地";
                }
            }

            m["availabilityStr"] = hasAvailable ? "可外借" : "不可用";
            m["locationStr"] = locStr;
            res.append(m);
        }
    }
    return res;
}

// ----------------------------------------------------
// 高级检索核心逻辑 (新增)
// ----------------------------------------------------
QVariantList SystemBridge::advancedSearchBooks(const QString& title, const QString& author, const QString& press, const QString& isbn) {
    QVariantList res;
    BookDAO dao;
    QList<Book> books;
    QList<QString> kws;
    kws.append(""); // 传入空字符串通配符以拉取全量合法数据，在内存中进行多维过滤

    if (dao.getBookInfobyTitle(kws, books) == ErrorCode::SUCCESS) {
        for (Book& b : books) {
            // 多维度联合过滤
            if (!title.trimmed().isEmpty() && !b.qs_Name().contains(title.trimmed(), Qt::CaseInsensitive)) continue;
            if (!isbn.trimmed().isEmpty() && !b.c_BookISBN().qs_Value().contains(isbn.trimmed(), Qt::CaseInsensitive)) continue;
            if (!press.trimmed().isEmpty() && !b.qs_Press().contains(press.trimmed(), Qt::CaseInsensitive)) continue;

            if (!author.trimmed().isEmpty()) {
                bool authorMatch = false;
                for (const QString& a : b.ql_Author()) {
                    if (a.contains(author.trimmed(), Qt::CaseInsensitive)) {
                        authorMatch = true;
                        break;
                    }
                }
                if (!authorMatch) continue;
            }

            QVariantMap m;
            m["isbn"] = b.c_BookISBN().qs_Value();
            m["title"] = b.qs_Name();
            m["author"] = b.ql_Author().join(", ");
            m["press"] = b.qs_Press();
            m["pubYear"] = b.i_PubYear();

            dao.getVolumeInfo(b);
            bool hasAvailable = false;
            QString locStr = "无馆藏信息";
            const auto& vols = b.ql_VolumeList();

            if (!vols.isEmpty()) {
                for (const auto& v : vols) {
                    if (v.enum_IsAvailable() == Availability::Available) {
                        hasAvailable = true;
                        locStr = formatLocation(v.stct_Location());
                        if (vols.size() > 1) locStr += " 等馆藏地";
                        break;
                    }
                }
                if (!hasAvailable) {
                    locStr = formatLocation(vols[0].stct_Location());
                    if (vols.size() > 1) locStr += " 等馆藏地";
                }
            }

            m["availabilityStr"] = hasAvailable ? "可外借" : "不可用";
            m["locationStr"] = locStr;
            res.append(m);
        }
    }
    return res;
}

QVariantList SystemBridge::getPopularBooks() {
    QVariantList res;
    QList<QPair<Book, int>> popList;
    if (Stats::getTop20Books(popList) == ErrorCode::SUCCESS) {
        for (const auto& pair : popList) {
            QVariantMap m;
            m["isbn"] = pair.first.c_BookISBN().qs_Value();
            m["title"] = pair.first.qs_Name();
            m["author"] = pair.first.ql_Author().join(", ");
            m["press"] = pair.first.qs_Press();
            m["pubYear"] = pair.first.i_PubYear();
            m["borrowCount"] = pair.second;
            res.append(m);
        }
    }
    return res;
}

QVariantMap SystemBridge::getBookDetails(const QString& isbn) {
    QVariantMap res;
    BookDAO dao;
    QList<Book> books;
    if (dao.getBookInfobyISBN(isbn, books) == ErrorCode::SUCCESS && !books.isEmpty()) {
        Book bk = books[0];
        res["isbn"] = bk.c_BookISBN().qs_Value();
        res["title"] = bk.qs_Name();
        res["author"] = bk.ql_Author().join(", ");
        res["press"] = bk.qs_Press();
        res["pubYear"] = bk.i_PubYear();
        res["intro"] = bk.qs_Introduction();

        QVariantList volList;
        if (dao.getVolumeInfo(bk) == ErrorCode::SUCCESS) {
            for (const Volume& v : bk.ql_VolumeList()) {
                QVariantMap vm;
                vm["volId"] = v.c_VolID().qs_Value();

                // 1. 状态判断及超期/到期时间括注逻辑
                QString statusStr = "未知";
                switch (v.enum_IsAvailable()) {
                case Availability::Available: statusStr = "在馆可借"; break;
                case Availability::Unavailable_OnLoan:
                    statusStr = "已借出";
                    if (v.qd_DueDate().isValid()) {
                        statusStr += QString("(%1)").arg(v.qd_DueDate().toString("yyyy-MM-dd"));
                    }
                    break;
                case Availability::Unavailable_Lost: statusStr = "遗失"; break;
                case Availability::Unavailable_Processing: statusStr = "加工中"; break;
                default: break;
                }
                vm["status"] = statusStr;
                vm["isAvailable"] = (v.enum_IsAvailable() == Availability::Available);

                // 2. 规范化单册在详情页的馆藏位置解析
                BookLocation loc = v.stct_Location();
                QString libStr, areaStr;
                switch (loc.libraryID) {
                case Library::LIB_North: libStr = "主馆北馆"; break;
                case Library::LIB_West: libStr = "主馆西馆"; break;
                case Library::LIB_Economic: libStr = "经管图书馆"; break;
                case Library::LIB_Literature: libStr = "人文社科图书馆"; break;
                case Library::LIB_Law: libStr = "法律图书馆"; break;
                default: libStr = "未知分馆"; break;
                }
                switch (loc.areaID) {
                case Area::AREA_E: areaStr = "东区"; break;
                case Area::AREA_W: areaStr = "西区"; break;
                case Area::AREA_S: areaStr = "南区"; break;
                case Area::AREA_N: areaStr = "北区"; break;
                default: areaStr = "未知区域"; break;
                }
                vm["location"] = QString("%1  %2层  %3  %4架  %5层").arg(libStr).arg(loc.floor).arg(areaStr).arg(loc.shelf).arg(loc.layer);

                volList.append(vm);
            }
        }
        res["volumes"] = volList;
    }
    return res;
}

// ----------------------------------------------------
// 单册借阅
// ----------------------------------------------------
int SystemBridge::borrowVolume(const QString& isbn, const QString& volId) {
    QSqlDatabase db = QSqlDatabase::database(); // 获取默认连接

    // 1. 防御性检查：清理可能存在的悬挂事务
    if (db.transaction() == false) {
        qWarning() << "检测到悬挂事务，强制回滚重置状态...";
        db.rollback();
        if (!db.transaction()) {
            qCritical() << "事务开启遭遇致命失败:" << db.lastError().text();
            return -1;
        }
    }

    // 2. 利用局部作用域严格控制查询对象的生命周期，确保读锁及时释放
    bool checkPassed = false;
    {
        QSqlQuery checkQuery(db);
        checkQuery.prepare("SELECT IsAvailable FROM Volume WHERE VolID = :volId");
        checkQuery.bindValue(":volId", volId);
        if (checkQuery.exec() && checkQuery.next()) {
            int status = checkQuery.value(0).toInt();
            if (status == 1) { // 假设 1 代表 Available
                checkPassed = true;
            }
        }
        checkQuery.finish(); // 💡 必须显式释放语句句柄，清除共享锁
    } // checkQuery 析构，进一步确保资源释放

    if (!checkPassed) {
        db.rollback();
        return 0; // 条件不满足，安全退出
    }

    // 3. 执行核心写入逻辑
    QSqlQuery updateQuery(db);
    updateQuery.prepare("UPDATE Volume SET IsAvailable = 0 WHERE VolID = :volId");
    updateQuery.bindValue(":volId", volId);

    if (updateQuery.exec()) {
        db.commit(); // 提交事务
        return 1;    // 成功
    }
    else {
        db.rollback(); // 发生异常，回滚事务
        return -1;
    }
}

// ----------------------------------------------------
// 图书维护业务 (Admin)
// ----------------------------------------------------
int SystemBridge::saveBook(const QString& isbn, const QString& title, const QString& author, const QString& press, int pubYear, int category, int language, const QString& intro) {
    if (!m_currentAdmin.has_value() || !m_isAdmin) return static_cast<int>(ErrorCode::NO_ACCESS);

    Book bk;
    ErrorCode st = bk.SetISBN(isbn);
    if (st != ErrorCode::SUCCESS) return static_cast<int>(st);

    bk.SetName(title);
    bk.SetAuthor(author.split(","));
    bk.SetPress(press);
    bk.SetPubYear(pubYear);
    bk.SetPubCategory(static_cast<Category>(category));
    bk.SetPubLanguage(static_cast<Language>(language));
    bk.SetIntroduction(intro);
    bk.SetIsValid(true);

    return static_cast<int>(BookOperation::BookUpdate(bk, m_currentAdmin.value()));
}

int SystemBridge::deleteBook(const QString& isbn) {
    if (!m_currentAdmin.has_value() || !m_isAdmin) return static_cast<int>(ErrorCode::NO_ACCESS);
    BookDAO dao;
    QList<Book> books;
    ErrorCode st = dao.getBookInfobyISBN(isbn, books);
    if (st != ErrorCode::SUCCESS || books.isEmpty()) return static_cast<int>(st);

    Book bk = books[0];
    dao.getVolumeInfo(bk);
    return static_cast<int>(BookOperation::BookDelete(bk, m_currentAdmin.value()));
}

int SystemBridge::saveVolume(const QString& isbn, const QString& volId, int lib, int floor, int area, int shelf, int layer, int availability, bool isOpenshelf, const QString& note) {
    if (!m_currentAdmin.has_value() || !m_isAdmin) return static_cast<int>(ErrorCode::NO_ACCESS);

    BookDAO dao;
    QList<Book> books;
    ErrorCode st = dao.getBookInfobyISBN(isbn, books);
    if (st != ErrorCode::SUCCESS || books.isEmpty()) return static_cast<int>(st);
    Book bk = books[0];
    dao.getVolumeInfo(bk);

    Volume vol;
    VolumeID vId;
    if (vId.SetValue(volId) != ErrorCode::SUCCESS) return static_cast<int>(ErrorCode::ILLEGAL_INPUT);
    vol.SetVolID(vId);

    BookLocation loc;
    loc.libraryID = static_cast<Library>(lib);
    loc.floor = floor; loc.areaID = static_cast<Area>(area); loc.shelf = shelf; loc.layer = layer;
    vol.SetLocation(loc);

    vol.SetAvailability(static_cast<Availability>(availability));
    vol.SetIsOpenshelf(isOpenshelf);
    vol.SetNote(note);
    vol.SetIsValid(true);

    return static_cast<int>(VolOperation::VolUpdate(bk, vol, m_currentAdmin.value()));
}

int SystemBridge::deleteVolume(const QString& isbn, const QString& volId) {
    if (!m_currentAdmin.has_value() || !m_isAdmin) return static_cast<int>(ErrorCode::NO_ACCESS);

    BookDAO dao;
    QList<Book> books;
    if (dao.getBookInfobyISBN(isbn, books) != ErrorCode::SUCCESS || books.isEmpty()) return static_cast<int>(ErrorCode::NO_RESULT);
    Book bk = books[0];
    dao.getVolumeInfo(bk);

    Volume vol;
    VolumeID vId;
    if (vId.SetValue(volId) != ErrorCode::SUCCESS) return static_cast<int>(ErrorCode::ILLEGAL_INPUT);
    vol.SetVolID(vId);
    vol.SetIsValid(true);

    return static_cast<int>(VolOperation::VolDelete(bk, vol, m_currentAdmin.value()));
}