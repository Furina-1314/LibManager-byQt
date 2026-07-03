// 统计服务
#include "header/TypeCode.h"
#include "header/DataTemplates.h"
#include "header/DataException.h"
#include "header/DatabaseManager.h"

class Stats {
public:

    // 获取前 20 名热门书籍详细榜单
    [[nodiscard]] static ErrorCode getTop20Books(QList<QPair<Book, int>>& topList) {
        LoanRecordDAO loanDAO;
        BookDAO bookDAO;
        topList.clear();

        QList<QPair<QString, int>> rawRank;
        try {
            // 从流水库获取前 20 名的 ISBN 与对应借阅量
            ErrorCode status = loanDAO.getTopPopularBooks(20, rawRank);
            if (status != ErrorCode::SUCCESS) {
                return status;
            }

            // 遍历 ISBN 列表，从图书库装配完整的 Book 实体
            for (int i = 0; i < rawRank.size(); i++) {
                QList<Book> bookResults;
                // 通过 ISBN 查询具体图书信息，具备容错跳过机制
                ErrorCode bookStatus = bookDAO.getBookInfobyISBN(rawRank[i].first, bookResults);
                if (bookStatus == ErrorCode::SUCCESS && !bookResults.isEmpty()) {
                    // 将完整的 Book 对象与借阅次数配对，推入最终榜单
                    topList.append(qMakePair(bookResults[0], rawRank[i].second));
                }
            }
            return ErrorCode::SUCCESS;
        }
        catch (DatabaseException& ex) {
            qWarning() << "错误：" << ex.qWhat();
            return ex.code();
        }
    }

    // 获取前 20 名借阅达人详细榜单
    [[nodiscard]] static ErrorCode getTop20Readers(QList<QPair<ReaderAccount, int>>& topList) {
        LoanRecordDAO loanDAO;
        AccountDAO acDAO;
        topList.clear();

        QList<QPair<QString, int>> rawRank;
        try {
            // 从流水库获取前 20 名的 BorrowerID 与对应借阅量
            ErrorCode status = loanDAO.getTopReaders(20, rawRank);
            if (status != ErrorCode::SUCCESS) {
                return status;
            }

            // 遍历 BorrowerID 列表，从账户类装配完整的 Reader 实体
            for (int i = 0; i < rawRank.size(); i++) {
                QList<ReaderAccount> readerResults;
                // 通过 BorrowerID 查询具体读者信息
                ErrorCode readerStatus = acDAO.getReaderInfo(rawRank[i].first, readerResults);
                if (readerStatus == ErrorCode::SUCCESS && !readerResults.isEmpty()) {
                    // 将完整的 Reader 对象与借阅次数配对，推入最终榜单
                    topList.append(qMakePair(readerResults[0], rawRank[i].second));
                }
            }
            return ErrorCode::SUCCESS;
        }
        catch (DatabaseException& ex) {
            qWarning() << "错误：" << ex.qWhat();
            return ex.code();
        }
    }

    // 按月获取读者借阅流水明细
    [[nodiscard]] static ErrorCode getReaderHistorybyMonth(const ReaderAccount& in, const int year, const int month, QList<LoanRecord>& results) {
        if (!(month >= 1 && month <= 12))  return ErrorCode::ILLEGAL_INPUT;

        LoanRecordDAO lrDAO;
        LoanRecord lr_tmp;
        QList<Filter> filter = { Filter::BorrowerID };
        lr_tmp.SetBorrowerID(in.c_ID());

        QDate start(year, month, 1);
        QDate end = start.addMonths(1);

        try {
            // 透传 DAO 层返回的状态码（ NO_RESULT 等）
            return lrDAO.getLoanRecord(lr_tmp, start, end, filter, results);
        }
        catch (DatabaseException& ex) {
            qWarning() << "查询失败：" << ex.qWhat();
            return ex.code();
        }
    }

    // 按年获取读者借阅流水明细
    [[nodiscard]] static ErrorCode getReaderHistorybyYear(const ReaderAccount& in, const int year, QList<LoanRecord>& results) {
        LoanRecordDAO lrDAO;
        LoanRecord lr_tmp;
        QList<Filter> filter = { Filter::BorrowerID };

        lr_tmp.SetBorrowerID(in.c_ID());

        QDate start(year, 1, 1);
        QDate end = start.addYears(1);

        try {
            return lrDAO.getLoanRecord(lr_tmp, start, end, filter, results);
        }
        catch (DatabaseException& ex) {
            qWarning() << "查询失败：" << ex.qWhat();
            return ex.code();
        }
    }

    // 按月统计读者借阅总数
    [[nodiscard]] static ErrorCode getReaderCountbyMonth(const ReaderAccount& in, const int year, const int month, int& result) {
        if (!(month >= 1 && month <= 12))  return ErrorCode::ILLEGAL_INPUT;

        LoanRecordDAO lrDAO;
        LoanRecord lr_tmp;
        QList<Filter> filter = { Filter::BorrowerID };

        lr_tmp.SetBorrowerID(in.c_ID());

        QDate start(year, month, 1);
        QDate end = start.addMonths(1);

        try {
            return lrDAO.getLoanCountbyFilter(start, end, result, filter, lr_tmp);
        }
        catch (DatabaseException& ex) {
            qWarning() << "统计失败：" << ex.qWhat();
            return ex.code();
        }
    }

    // 按年统计读者借阅总数
    [[nodiscard]] static ErrorCode getReaderCountbyYear(const ReaderAccount& in, const int year, int& result) {
        LoanRecordDAO lrDAO;
        LoanRecord lr_tmp;
        QList<Filter> filter = { Filter::BorrowerID };

        lr_tmp.SetBorrowerID(in.c_ID());

        QDate start(year, 1, 1);
        QDate end = start.addYears(1);

        try {
            return lrDAO.getLoanCountbyFilter(start, end, result, filter, lr_tmp);
        }
        catch (DatabaseException& ex) {
            qWarning() << "统计失败：" << ex.qWhat();
            return ex.code();
        }
    }
};