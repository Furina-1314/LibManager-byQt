#pragma once
#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QString>
#include <QDebug>
#include "DataTemplates.h"
#include "TypeCode.h"
#include "DataException.h"

class DatabaseController : public QObject {
    Q_OBJECT 

public:
    explicit DatabaseController(QObject* parent = nullptr) : QObject(parent) {}

    // 析构函数
    ~DatabaseController() {
        // 若连接池中仍存在该连接，则执行安全关闭逻辑
        if (QSqlDatabase::contains("qt_sql_default_connection")) {
            closeDatabase();
        }
    }

    // Q_INVOKABLE 宏暴露该函数，使其可在 QML 的 JavaScript 引擎中被直接调用
    Q_INVOKABLE ErrorCode initializeDatabase() {
        QSqlDatabase db;
        // 检查全局连接池中是否已有默认连接
        if (!QSqlDatabase::contains("qt_sql_default_connection")) {
            db = QSqlDatabase::addDatabase("QSQLITE");
        }
        else {
            db = QSqlDatabase::database("qt_sql_default_connection");
        }
        
        db.setDatabaseName("LibManager.db");
        if (!db.open()) {
            qWarning() << "数据库连接失败:" << db.lastError().text();
            return ErrorCode::DATABASE_ERROR;
        }

        // 开启事务：确保所有建表操作的原子性
        db.transaction();
        QSqlQuery query;

        try {
            if (!query.exec("PRAGMA foreign_keys = ON;"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "开启外键约束失败", query.lastError());

            if (!query.exec(R"(
                        --图书表
                         CREATE TABLE IF NOT EXISTS Book (
                         ISBN TEXT NOT NULL PRIMARY KEY,
                         Title TEXT NOT NULL COLLATE NOCASE,
                         Introduction TEXT,
                         Press TEXT NOT NULL COLLATE NOCASE,
                         PubYear INTEGER NOT NULL,
                         Language INTEGER NOT NULL,
                         Category INTEGER NOT NULL,
                         CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         EditedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                       )
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 Book 表失败", query.lastError());

            if (!query.exec(R"(
                        --单册表
                         CREATE TABLE IF NOT EXISTS Volume (
                         VolId INTEGER NOT NULL,
                         ISBN TEXT NOT NULL,
                         VolNote TEXT,
                         VolAvailability INTEGER NOT NULL,
                         VolIsOpenshelf INTEGER NOT NULL,

                         PRIMARY KEY (ISBN, VolId),
                         FOREIGN KEY (ISBN) REFERENCES Book(ISBN) ON DELETE CASCADE ON UPDATE CASCADE
                       )
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 Volume 表失败", query.lastError());

            if (!query.exec(R"(
                        --作者表
                         CREATE TABLE IF NOT EXISTS Authors (
                         ISBN TEXT NOT NULL,
                         AuthorName TEXT NOT NULL COLLATE NOCASE,
                         AuthorOrder INTEGER NOT NULL,      -- 第几作者 
 
                         PRIMARY KEY (ISBN, AuthorOrder),
                         UNIQUE (ISBN, AuthorName),
                         FOREIGN KEY (ISBN) REFERENCES Book(ISBN) ON DELETE CASCADE ON UPDATE CASCADE
                       )
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 Authors 表失败", query.lastError());

            if (!query.exec(R"(
                        --位置表
                         CREATE TABLE IF NOT EXISTS VolLocation (
                         ISBN TEXT NOT NULL,
                         VolId INTEGER NOT NULL,
                         Lib INTEGER NOT NULL,
                         Floor INTEGER NOT NULL,
                         Area INTEGER NOT NULL,
                         Shelf INTEGER NOT NULL,
                         Layer INTEGER NOT NULL,

                         PRIMARY KEY (ISBN, VolId),
                         FOREIGN KEY (ISBN, VolId) REFERENCES Volume(ISBN, VolId) ON DELETE CASCADE ON UPDATE CASCADE
                       )
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 VolLocation 表失败", query.lastError());

            // 索引
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_book_press ON Book(Press);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_book_press 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_book_pubyear ON Book(PubYear);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_book_pubyear 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_book_category ON Book(Category);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_book_category 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_author_name ON Authors(AuthorName);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_author_name 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_location_loc ON VolLocation(Lib);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_location_loc 索引失败", query.lastError());

            if (!query.exec(R"(
                        --账户表
                         CREATE TABLE IF NOT EXISTS Account (
                         ID TEXT NOT NULL PRIMARY KEY,
                         UserName TEXT NOT NULL COLLATE NOCASE,
                         Auth INTEGER NOT NULL,
                         Validity INTEGER NOT NULL,
                         BorrowLimit INTEGER NOT NULL,
                         Salt TEXT NOT NULL,
                         PasswordHash TEXT NOT NULL,                         
                         CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         EditedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                       )
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 Account 表失败", query.lastError());

            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_account_username ON Account(UserName);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_account_username 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_account_auth_id ON Account(Auth, ID);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_account_auth_id 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_account_id ON Account(ID);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_account_id 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_account_validity ON Account(Validity);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_account_validity 索引失败", query.lastError());

            if (!query.exec(R"(
                        --借阅流水表
                         CREATE TABLE IF NOT EXISTS LoanRecord (
                         RecordID INTEGER PRIMARY KEY AUTOINCREMENT,
                         ISBN TEXT NOT NULL,
                         VolID INTEGER NOT NULL,
                         BorrowerID TEXT NOT NULL,
                         IsReturned INTEGER NOT NULL,
                         IsOverdue INTEGER NOT NULL,
                         BorrowDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         DueDate TIMESTAMP NOT NULL,        -- 应还时间由 C++ 业务层计算后传入
                         ReturnDate TIMESTAMP,              -- 应还时间必须由 C++ 业务层计算后传入      

                         FOREIGN KEY (ISBN, VolID) REFERENCES Volume(ISBN, VolID) ON DELETE RESTRICT ON UPDATE CASCADE,
                         FOREIGN KEY (BorrowerID) REFERENCES Account(ID) ON DELETE RESTRICT ON UPDATE CASCADE                       )
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 LoanRecord 表失败", query.lastError());

            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_loanrecord_borrowdate ON LoanRecord(BorrowDate);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_loanrecord_borrowdate 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_loanrecord_volume ON LoanRecord(ISBN, VolID);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_loanrecord_volume 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_loanrecord_borrower ON LoanRecord(BorrowerID);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_loanrecord_borrower 索引失败", query.lastError());

            // 所有语句均无异常，提交事务
            db.commit();

        }
        catch (const DatabaseException& ex) {
            // 捕获异常后回滚已执行部分，防止产生脏表
            db.rollback();
            // 在 C++ 控制台打印 QString 错误轨迹
            qCritical().noquote() << "初始化受阻:" << ex.qWhat();
            // ErrorCode 返回给 QML 业务层
            return ex.code();
        }
        return ErrorCode::SUCCESS;
    }
    //暴露给前端，允许手动断开连接释放文件锁
    Q_INVOKABLE ErrorCode closeDatabase() {
        //使用局部作用域控制 db 对象的生命周期
        {
            QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
            if (db.isOpen()) {
                db.close();
            }
        } // 离开此作用域时，局部的 db 对象析构，引用计数减 1

        // 从全局连接池中注销该连接
        // 调用 removeDatabase 前，必须确保没有任何 QSqlDatabase 或 QSqlQuery 对象持有该连接名
        QSqlDatabase::removeDatabase("qt_sql_default_connection");

        return ErrorCode::SUCCESS;
    }
};

// 账户DAO
class AccountDAO : public QObject {//账户类DAO
// 注销将采用软删除方式，故只需 Update
public:

    [[nodiscard]] ErrorCode isUserExists(const QString& userid) const//查询用户是否存在
    {
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开，无法执行查询");
        }
        QSqlQuery query(db);
        query.setForwardOnly(true);
        query.prepare("SELECT COUNT(*) FROM Account WHERE ID = :input");
        query.bindValue(":input", userid);
        if (!query.exec()) {
            throw DatabaseException(ErrorCode::FAILED_SEARCH, "查询账户表失败", query.lastError());
        }

        if (query.next()) {
            if (query.value(0).toInt() > 0) return ErrorCode::SUCCESS;
            else return ErrorCode::USERID_NOT_EXIST;
        }
    }

    // 查询读者接口
    [[nodiscard]] ErrorCode getReaderInfo(const QString& userid, QList<ReaderAccount>& results) const // 查询读者信息
    {
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开，无法执行查询");
        }
        // 确保传出的容器初始状态干净
        results.clear();

        QSqlQuery query(db);
        query.setForwardOnly(true);
        // 带过滤约束的查询
        query.prepare("SELECT * FROM Account WHERE Auth=0 AND ID LIKE :input");
        query.bindValue(":input", userid);
        if (!query.exec()) {
            throw DatabaseException(ErrorCode::FAILED_SEARCH, "查询失败", query.lastError());
        }

        QSqlRecord record = query.record();
        int idxId = record.indexOf("ID");
        int idxUserName = record.indexOf("UserName");
        int idxAuth = record.indexOf("Auth");
        int idxValidity = record.indexOf("Validity");
        int idxLimit = record.indexOf("BorrowLimit");
        int idxSalt = record.indexOf("Salt");
        int idxHash = record.indexOf("PasswordHash");

        // 检查字段映射是否断裂
        if (idxId == -1 || idxUserName == -1) {
            throw DatabaseException(ErrorCode::SYSTEM_ERROR, "底层 SQL 字段映射异常");
        }

        while (query.next()) {
            ReaderAccount account;
            UserID uid;
            uid.SetValue(query.value(idxId).toString());
            account.SetID(uid);
            account.SetName(query.value(idxUserName).toString());
            account.SetIsValid(query.value(idxValidity).toInt() != 0);
            account.ActivateReader(static_cast<Auth>(query.value(idxAuth).toInt()));
            account.SetBorrowLimit(query.value(idxLimit).toInt());
            account.SetSalt(QByteArray::fromBase64(query.value(idxSalt).toString().toUtf8()));
            account.SetPasswordHash(QByteArray::fromBase64(query.value(idxHash).toString().toUtf8()));

            results.append(account);
        }
        // 根据结果集容量判定状态
        if (results.isEmpty()) {
            return ErrorCode::USERID_NOT_EXIST;
        }
        // 正常执行流的返回值
        return ErrorCode::SUCCESS;
    }

    // 查询管理员接口
    [[nodiscard]] ErrorCode getAdminInfo(const QString& userid, QList<AdminAccount>& results) // 查询管理员信息
    {
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开，无法执行查询");
        }
        // 确保传出的容器初始状态干净
        results.clear();

        QSqlQuery query(db);
        query.setForwardOnly(true);
        // 带过滤约束的查询
        query.prepare("SELECT * FROM Account WHERE Auth=1 AND ID LIKE :input");
        query.bindValue(":input", userid);
        if (!query.exec()) {
            throw DatabaseException(ErrorCode::FAILED_SEARCH, "查询失败", query.lastError());
        }

        QSqlRecord record = query.record();
        int idxId = record.indexOf("ID");
        int idxAuth = record.indexOf("Auth");
        int idxValidity = record.indexOf("Validity");
        int idxSalt = record.indexOf("Salt");
        int idxHash = record.indexOf("PasswordHash");

        // 检查字段映射是否断裂
        if (idxId == -1) {
            throw DatabaseException(ErrorCode::SYSTEM_ERROR, "底层 SQL 字段映射异常");
        }

        while (query.next()) {
            AdminAccount account;
            AdminID adminid;
            adminid.SetValue(query.value(idxId).toString());
            account.SetID(adminid);
            account.SetIsValid(query.value(idxValidity).toInt() != 0);
            account.ActivateAdmin(static_cast<Auth>(query.value(idxAuth).toInt()));
            account.SetSalt(QByteArray::fromBase64(query.value(idxSalt).toString().toUtf8()));
            account.SetPasswordHash(QByteArray::fromBase64(query.value(idxHash).toString().toUtf8()));

            results.append(account);
        }
        // 根据结果集容量判定状态
        if (results.isEmpty()) {
            return ErrorCode::USERID_NOT_EXIST;
        }
        // 正常执行流的返回值
        return ErrorCode::SUCCESS;
    }

    [[nodiscard]] ErrorCode updateReaderInfo(const ReaderAccount& in) // 更新读者信息
    {
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开");
        }
        if (!in.IsReady())   return ErrorCode::ILLEGAL_INPUT; // 保证传入的信息合法
        QSqlQuery query(db);
        query.setForwardOnly(true);

        // 使用 ON CONFLICT 实现Upsert
        // 这里的 excluded 是 SQLite 的内置关键字，代表“刚才试图插入的那批新数据”
        query.prepare(R"(
            INSERT INTO Account (ID, UserName, Auth, Validity, BorrowLimit, Salt, PasswordHash, CreatedAt, EditedAt) 
            VALUES (:id, :name, :auth, :validity, :limit, :salt, :hash, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT(ID) DO UPDATE SET 
                UserName = excluded.UserName,
                Auth = excluded.Auth,
                Validity = excluded.Validity,
                BorrowLimit = excluded.BorrowLimit,
                Salt = excluded.Salt,
                PasswordHash = excluded.PasswordHash,
                -- 冲突时，旧记录的 CreatedAt 将原封不动，仅 EditedAt 会被刷新
                EditedAt = CURRENT_TIMESTAMP
        )");

        // 数据装配与类型强转
        query.bindValue(":id", in.c_ID().qs_Value());
        query.bindValue(":name", in.qs_Name());
        query.bindValue(":auth", static_cast<int>(in.enum_ReaderAuth()));
        query.bindValue(":validity", in.b_IsValid() ? 1 : 0);
        query.bindValue(":limit", in.i_BorrowLimit());
        // 二进制转换：QByteArray -> Base64 编码 -> 存入 TEXT
        query.bindValue(":salt", QString(in.qba_Salt().toBase64()));
        query.bindValue(":hash", QString(in.qba_PasswordHash().toBase64()));

        // 执行并捕获异常
        if (!query.exec()) {
            throw DatabaseException(ErrorCode::FAILED_TO_WRITE, "保存账户数据失败", query.lastError());
        }

        return ErrorCode::SUCCESS;
    }
    [[nodiscard]] ErrorCode updateAdminInfo(const AdminAccount& in) // 更新管理员信息
    {
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开");
        }
        if (!in.IsReady())   return ErrorCode::ILLEGAL_INPUT; // 保证传入的信息合法
        QSqlQuery query(db);
        query.setForwardOnly(true);

        // 使用 ON CONFLICT 实现Upsert
        // 这里的 excluded 是 SQLite 的内置关键字，代表“刚才试图插入的那批新数据”
        query.prepare(R"(
            INSERT INTO Account (ID, UserName, Auth, Validity, BorrowLimit, Salt, PasswordHash, CreatedAt, EditedAt) 
            VALUES (:id, :name, :auth, :validity, :limit, :salt, :hash, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT(ID) DO UPDATE SET 
                UserName = excluded.UserName,
                Auth = excluded.Auth,
                Validity = excluded.Validity,
                BorrowLimit = excluded.BorrowLimit,
                Salt = excluded.Salt,
                PasswordHash = excluded.PasswordHash,
                -- 冲突时，旧记录的 CreatedAt 将原封不动，仅 EditedAt 会被刷新
                EditedAt = CURRENT_TIMESTAMP
        )");

        // 数据装配与类型强转
        query.bindValue(":id", in.c_ID().qs_Value());
        query.bindValue(":name", in.qs_Name());
        query.bindValue(":auth", static_cast<int>(in.enum_AdminAuth()));
        query.bindValue(":validity", in.b_IsValid() ? 1 : 0);
        query.bindValue(":limit", in.i_BorrowLimit());
        // 二进制转换：QByteArray -> Base64 编码 -> 存入 TEXT
        query.bindValue(":salt", QString(in.qba_Salt().toBase64()));
        query.bindValue(":hash", QString(in.qba_PasswordHash().toBase64()));

        // 执行并捕获异常
        if (!query.exec()) {
            throw DatabaseException(ErrorCode::FAILED_TO_WRITE, "保存账户数据失败", query.lastError());
        }

        return ErrorCode::SUCCESS;
    }
};

// 图书DAO
class BookDAO {// 图书类DAO
public:
    // 查询图书接口
    [[nodiscard]] ErrorCode getBookInfo(const QString& ISBN, QList<Book>& results) const // 查询图书信息
    {
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开，无法执行查询");
        }
        // 确保传出的容器初始状态干净
        results.clear();

        // 查询Book
        QSqlQuery query(db);
        query.setForwardOnly(true);
        // 带过滤约束的查询
        query.prepare("SELECT * FROM Book WHERE ISBN LIKE :input");
        query.bindValue(":input", ISBN);
        if (!query.exec()) {
            throw DatabaseException(ErrorCode::FAILED_SEARCH, "查询失败", query.lastError());
        }
        
        QSqlRecord record = query.record();
        int idxISBN = record.indexOf("ISBN");
        int idxTitle = record.indexOf("Title");
        int idxPress = record.indexOf("Press");
        int idxLanguage = record.indexOf("Language");
        int idxPubYear = record.indexOf("PubYear");
        int idxCategory = record.indexOf("Category");
        int idxIntroduction = record.indexOf("Introduction");

        // 检查字段映射是否断裂
        if (idxISBN == -1 || idxTitle == -1) {
            throw DatabaseException(ErrorCode::SYSTEM_ERROR, "底层 SQL 字段映射异常");
        }

        // 预编译之后 Authors 的查询
        QSqlQuery query2(db);
        query2.setForwardOnly(true);
        query2.prepare("SELECT * FROM Authors WHERE ISBN = :input ORDER BY AuthorOrder ASC");

        while (query.next()) {
            // 查询Authors
            query2.bindValue(":input", query.value(idxISBN).toString());
            if (!query2.exec()) {
                throw DatabaseException(ErrorCode::FAILED_SEARCH, "查询失败", query2.lastError());
            }
            QSqlRecord record2 = query2.record();
            int idxAuthorName = record2.indexOf("AuthorName");
            QList<QString> authors;
            while (query2.next()) {
                authors.append(query2.value(idxAuthorName).toString());
            }

            Book book;
            book.SetISBN(query.value(idxISBN).toString());
            book.SetName(query.value(idxTitle).toString());
            book.SetPress(query.value(idxPress).toString());
            book.SetPubYear(query.value(idxPubYear).toInt());
            book.SetPubCategory(static_cast<Category>(query.value(idxCategory).toInt()));
            book.SetPubLanguage(static_cast<Language>(query.value(idxLanguage).toInt()));
            book.SetIntroduction(query.value(idxIntroduction).toString());
            book.SetAuthor(authors);

            results.append(book);
        }
        // 根据结果集容量判定状态
        if (results.isEmpty()) {
            return ErrorCode::NO_RESULT;
        }
        // 正常执行流的返回值
        return ErrorCode::SUCCESS;
    }
    [[nodiscard]] ErrorCode getVolumeInfo(Book& querybook) const // 查询单册信息
    {
        QList<Volume> results;
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开，无法执行查询");
        }

        // 查询Volume
        QSqlQuery query(db);
        query.setForwardOnly(true);
        // 带过滤约束的查询
        query.prepare("SELECT * FROM Volume WHERE ISBN = :input");
        query.bindValue(":input", querybook.c_BookISBN().qs_Value());
        if (!query.exec()) {
            throw DatabaseException(ErrorCode::FAILED_SEARCH, "查询失败", query.lastError());
        }

        QSqlRecord record = query.record();
        int idxVolID = record.indexOf("VolID");
        int idxVolNote = record.indexOf("VolNote");
        int idxVolAvailability = record.indexOf("VolAvailability");
        int idxVolIsOpenshelf = record.indexOf("VolIsOpenshelf");

        // 检查字段映射是否断裂
        if (idxVolID == -1) {
            throw DatabaseException(ErrorCode::SYSTEM_ERROR, "底层 SQL 字段映射异常");
        }

        while (query.next()) {
            Volume  volume;
            VolumeID temp;

            temp.SetValue(query.value(idxVolID).toString());

            volume.SetVolID(temp);
            volume.SetNote(query.value(idxVolNote).toString());
            volume.SetAvailability(static_cast<Availability>(query.value(idxVolAvailability).toInt()));
            volume.SetIsOpenshelf(query.value(idxVolIsOpenshelf).toInt());
            results.append(volume);
        }

        querybook.SetVolumeList(results);

        // 根据结果集容量判定状态
        if (results.isEmpty()) {
            return ErrorCode::NO_RESULT;
        }
        // 正常执行流的返回值
        return ErrorCode::SUCCESS;
    }

    [[nodiscard]] ErrorCode updateBookInfo(const Book& in) // 更新图书信息
    {
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开");
        }
        // 利用 transaction 保证 Book 表和 Authors 表的更新状态同步
        if (!db.transaction()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "无法开启数据库事务");
        }
        try
        {
            QSqlQuery query(db);
            query.setForwardOnly(true);

            // 使用 ON CONFLICT 实现Upsert
            // 这里的 excluded 是 SQLite 的内置关键字，代表“刚才试图插入的那批新数据”
            query.prepare(R"(
            INSERT INTO Book (ISBN, Title, Introduction, Press, PubYear, Language, Category, CreatedAt, EditedAt) 
            VALUES (:isbn, :title, :introduction, :press, :pubyear, :language, :category, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT(ISBN) DO UPDATE SET 
                Title = excluded.Title,
                Introduction = excluded.Introduction,
                Press = excluded.Press,
                PubYear = excluded.PubYear,
                Language = excluded.Language,
                Category = excluded.Category,
                -- 冲突时，旧记录的 CreatedAt 将原封不动，仅 EditedAt 会被刷新
                EditedAt = CURRENT_TIMESTAMP
        )");

            // 数据装配与类型强转
            // 更新 Book 表
            query.bindValue(":isbn", in.c_BookISBN().qs_Value());
            query.bindValue(":title", in.qs_Name());
            query.bindValue(":introduction", in.qs_Introduction());
            query.bindValue(":press", in.qs_Press());
            query.bindValue(":pubyear", in.i_PubYear());
            query.bindValue(":language", static_cast<int>(in.enum_PubLanguage()));
            query.bindValue(":category", static_cast<int>(in.enum_PubCategory()));

            // 执行并捕获异常
            if (!query.exec()) {
                throw DatabaseException(ErrorCode::FAILED_TO_WRITE, "保存图书数据失败", query.lastError());
            }

            // 更新 Authors 表
            // 先清理旧数据，以应对作者数减少的情况
            query.prepare("DELETE FROM Authors WHERE ISBN = :isbn");
            query.bindValue(":isbn", in.c_BookISBN().qs_Value());
            if (!query.exec()) {
                throw DatabaseException(ErrorCode::FAILED_TO_WRITE, "清理旧作者失败", query.lastError());
            }
            query.prepare(R"(
            INSERT INTO Authors (ISBN, AuthorName, AuthorOrder) 
            VALUES (:isbn, :authorname, :authororder)
        )");
            int i = 0;
            const QList<QString>& temp = in.ql_Author();
            for (i = 0; i < temp.size(); i++) {
                query.bindValue(":isbn", in.c_BookISBN().qs_Value());
                query.bindValue(":authorname", temp[i]);
                query.bindValue(":authororder", i + 1);
                // 执行并捕获异常
                if (!query.exec()) {
                    throw DatabaseException(ErrorCode::FAILED_TO_WRITE, "保存图书作者数据失败", query.lastError());
                }
            }

            // 提交事务
            if (!db.commit()) {
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "事务提交失败");
            }

            return ErrorCode::SUCCESS;
        }
        catch(const DatabaseException& ex){
            // 中途任一步抛出异常即回滚
            db.rollback();
            // 返回错误值
            qWarning() << "更新图书发生致命错误，数据已回滚：" << ex.qWhat();
            return ex.code();
        }

    }

    [[nodiscard]] ErrorCode updateVolumeInfo(const Book& in) // 更新单册信息
    {
        QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
        if (!db.isValid() || !db.isOpen()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "数据库连接断开");
        }
        QSqlQuery query(db);
        query.setForwardOnly(true);

        // 利用事务保证若干本单册的更新状态同步
        if (!db.transaction()) {
            throw DatabaseException(ErrorCode::DATABASE_ERROR, "无法开启数据库事务");
        }

        try
        {
            // 使用 ON CONFLICT 实现Upsert
            // 这里的 excluded 是 SQLite 的内置关键字，代表“刚才试图插入的那批新数据”
            query.prepare(R"(
            INSERT INTO Volume (VolID, ISBN, VolNote, VolAvailability, VolIsOpenshelf) 
            VALUES (:volid, :isbn, :volnote, :volavailability, :volisopenshelf)
            ON CONFLICT(ISBN, VolID) DO UPDATE SET 
                VolNote = excluded.VolNote,
                VolAvailability = excluded.VolAvailability,
                VolIsOpenshelf = excluded.VolIsOpenshelf
        )");

            // 数据装配与类型强转
            // 更新 Volume 表
            const QList<Volume>& temp = in.ql_VolumeList();
            int i = 0;
            for (i = 0; i < temp.size(); i++) {
                query.bindValue(":volid", temp[i].c_VolID().qs_Value());
                query.bindValue(":isbn", in.c_BookISBN().qs_Value());
                query.bindValue(":volnote", temp[i].qs_Note());
                query.bindValue(":volavailability", static_cast<int>(temp[i].enum_IsAvailable()));
                query.bindValue(":volisopenshelf", temp[i].b_IsOpenshelf());

                // 执行并捕获异常
                if (!query.exec()) {
                    throw DatabaseException(ErrorCode::FAILED_TO_WRITE, "保存单册数据失败", query.lastError());
                }
            }

            // 提交事务
            if (!db.commit()) {
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "事务提交失败");
            }
            return ErrorCode::SUCCESS;
        }
        catch (const DatabaseException& ex) {
            // 中途任一步抛出异常即回滚
            db.rollback();
            // 返回错误值
            qWarning() << "更新单册发生致命错误，数据已回滚：" << ex.qWhat();
            return ex.code();
        }
    }

};