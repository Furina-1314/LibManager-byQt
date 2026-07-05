//图书业务
#include "header/TypeCode.h"
#include "header/DataTemplates.h"
#include "header/DataException.h"
#include "header/DatabaseManager.h"
#include "header/Stats.h"

class VolOperation {// 单册操作
public:

	// 单册借阅
	[[nodiscard]] static ErrorCode VolReserve(Book& reserve, const VolumeID& volID, const ReaderAccount& borrower) {
		
		// 查询 Reader 借阅上限
		int count = 0;
		if (Stats::getReaderCountbyNotReturned(borrower, count) == ErrorCode::SUCCESS && count >= borrower.i_BorrowLimit())
			return ErrorCode::MAX_BORROW_LIMIT;

		// 搜寻单册信息
		bool flag = false;
		int i = 0;
		QList<Volume> vl_tmp = reserve.ql_VolumeList();
		for (i = 0; i < vl_tmp.size(); i++) {
			if (vl_tmp[i].c_VolID() == volID) {
				flag = true; break;
			}
		}
		if (!flag)return ErrorCode::NO_RESULT;

		// 针对软删除的检验
		if (!vl_tmp[i].b_IsValid())	return ErrorCode::VOLUME_NOT_AVAILABLE;

		// 检查单册可用性
		switch (vl_tmp[i].enum_IsAvailable()) {
		case Availability::Unavailable_OnLoan:
			if (vl_tmp[i].c_BorrowerID().qs_Value() == borrower.c_ID().qs_Value()) { return ErrorCode::VOLUME_RESERVED; }
			else {
				return ErrorCode::VOLUME_ONLOAN;
			}
		case Availability::Available:
			break;
		default:
			return ErrorCode::VOLUME_NOT_AVAILABLE;
		}

		// 借阅操作
		vl_tmp[i].SetBorrowerID(borrower.c_ID());
		vl_tmp[i].SetAvailability(Availability::Unavailable_OnLoan);
		vl_tmp[i].SetDueDate(QDate::currentDate().addDays(30));

		reserve.SetVolumeList(vl_tmp);

		LoanRecord lr_tmp;
		lr_tmp.SetBookISBN(reserve.c_BookISBN());
		lr_tmp.SetVolumeID(vl_tmp[i].c_VolID());
		lr_tmp.SetBorrowerID(borrower.c_ID());
		lr_tmp.SetBorrowDate(QDate::currentDate());
		lr_tmp.SetDueDate(QDate::currentDate().addDays(30));
		lr_tmp.SetIsReturned(false);
		lr_tmp.SetIsOverdue(false);
		
		// 提交事务
		BookDAO bkDAO;
		LoanRecordDAO lrDAO;
		QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
		if (!db.transaction()) {
			return ErrorCode::DATABASE_ERROR; // 无法开启事务
		}

		try {
			bkDAO.updateVolumeInfo(reserve);
			lrDAO.updateLoanRecord(lr_tmp);

			if (!db.commit()) {
				throw DatabaseException(ErrorCode::DATABASE_ERROR, "事务提交失败");
			}
		}
		catch (DatabaseException& ex) {
			db.rollback(); // 发生异常即回滚
			qWarning() << "跨表写入失败，数据已回滚：" << ex.qWhat();
			return ex.code();
		}

		return ErrorCode::SUCCESS;

	}

	// 单册归还
	[[nodiscard]] static ErrorCode VolReturn(Book& bkreturn, const VolumeID& volID) {
		
		// 搜寻单册信息
		bool flag = false;
		int i = 0;
		QList<Volume> vl_tmp = bkreturn.ql_VolumeList();
		for (i = 0; i < vl_tmp.size(); i++) {
			if (vl_tmp[i].c_VolID() == volID) {
				flag = true; break;
			}
		}
		if (!flag)return ErrorCode::NO_RESULT;

		// 检查单册是否待归还
		switch (vl_tmp[i].enum_IsAvailable()) {
		case Availability::Unavailable_OnLoan:
			break;
		default:
			return ErrorCode::VOLUME_NOT_BORROWED;
		}

		// 归还操作
		LoanRecordDAO lrDAO;
		LoanRecord lr_query;
		QList<Filter> filter = { Filter::ISBN,Filter::VolID,Filter::IsReturned };

		// 定位对应流水
		lr_query.SetBookISBN(bkreturn.c_BookISBN());
		lr_query.SetVolumeID(vl_tmp[i].c_VolID());
		lr_query.SetIsReturned(false);
		QList<LoanRecord> lr;
		ErrorCode status = lrDAO.getLoanRecord(lr_query, QDate(-9999, 1, 1), QDate(9999, 12, 31), filter, lr);

		if (status != ErrorCode::SUCCESS || lr.isEmpty()) {
			return ErrorCode::SYSTEM_ERROR; // 物理状态为已借出，但找不到对应流水，说明底层数据已损坏
		}
		if (lr.size() != 1) {
			return ErrorCode::SYSTEM_ERROR; // 物理单册不可能同时存在多条未还记录
		}

		// 更新流水记录
		lr[0].SetIsReturned(true);
		lr[0].SetReturnDate(QDate::currentDate());// 设置归还日期

		// 逾期判定
		if (lr[0].qd_ReturnDate() > lr[0].qd_DueDate()) {
			lr[0].SetIsOverdue(true);
		}
		else {
			lr[0].SetIsOverdue(false);
		}

		// 更新单册信息
		UserID emptyUid;

		vl_tmp[i].SetBorrowerID(emptyUid);// 清空借阅者信息
		vl_tmp[i].SetAvailability(Availability::Available);
		vl_tmp[i].SetDueDate(QDate());// 清空到期日期
		bkreturn.SetVolumeList(vl_tmp);

		// 提交事务
		BookDAO bkDAO;
		QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
		if (!db.transaction()) {
			return ErrorCode::DATABASE_ERROR; // 无法开启事务
		}

		try {
			bkDAO.updateVolumeInfo(bkreturn);
			lrDAO.updateLoanRecord(lr[0]);

			if (!db.commit()) {
				throw DatabaseException(ErrorCode::DATABASE_ERROR, "事务提交失败");
			}
		}
		catch (DatabaseException& ex) {
			db.rollback(); // 发生异常即回滚
			qWarning() << "跨表写入失败，数据已回滚：" << ex.qWhat();
			return ex.code();
		}

		return ErrorCode::SUCCESS;

	}

	// 图书信息更新（仅限 Admin ）
	[[nodiscard]] static ErrorCode BookUpdate();

};