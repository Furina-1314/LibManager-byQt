#pragma once
#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QString>
#include <QDebug>
#include "DataTemplates.h"
#include "TypeCode.h"
#include "DataException.h"

class DatabaseController : public QObject {
    Q_OBJECT // 宏定义：启用元对象编译器 (MOC)，这是 QML 识别 C++ 类的核心

public:
    explicit DatabaseController(QObject* parent = nullptr) : QObject(parent) {}

    // 析构函数
    ~DatabaseController() {
        // 如果连接池中还存在该连接，则执行安全关闭逻辑
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
                         CREATE TABLE IF NOT EXISTS book (
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
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 book 表失败", query.lastError());

            if (!query.exec(R"(
                        --单册表
                         CREATE TABLE IF NOT EXISTS Volume (
                         VolId INTEGER NOT NULL,
                         ISBN TEXT NOT NULL,
                         VolNote TEXT,
                         VolAvailability INTEGER NOT NULL,
                         VolIsOpenshelf INTEGER NOT NULL,

                         PRIMARY KEY (ISBN, VolId),
                         FOREIGN KEY (ISBN) REFERENCES book(ISBN) ON DELETE CASCADE ON UPDATE CASCADE
                       )
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 Volume 表失败", query.lastError());

            if (!query.exec(R"(
                        --作者表
                         CREATE TABLE IF NOT EXISTS Authors (
                         ISBN TEXT NOT NULL,
                         AuthorName TEXT NOT NULL COLLATE NOCASE,
                         AuthorOrder INTEGER NOT NULL,      -- 第几作者 
 
                         PRIMARY KEY (ISBN, AuthorOrder),
                         FOREIGN KEY (ISBN) REFERENCES book(ISBN) ON DELETE CASCADE ON UPDATE CASCADE
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
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_book_press ON book(Press);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_book_press 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_book_pubyear ON book(PubYear);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_book_pubyear 索引失败", query.lastError());
            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_book_category ON book(Category);"))
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
                         Salt TEXT NOT NULL,
                         PasswordHash TEXT NOT NULL,                         
                         CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         EditedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                       )
                      )")) throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 Account 表失败", query.lastError());

            if (!query.exec("CREATE INDEX IF NOT EXISTS idx_account_username ON Account(UserName);"))
                throw DatabaseException(ErrorCode::DATABASE_ERROR, "创建 idx_account_username 索引失败", query.lastError());

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
            // 捕获到我们异常后回滚已执行的部分，防止产生脏表
            db.rollback();
            // 在 C++ 控制台打印安全的 QString 错误轨迹
            qCritical().noquote() << "初始化受阻:" << ex.qWhat();
            // 完美剥离 ErrorCode 返回给 QML 业务层
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