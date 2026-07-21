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
		if (!vl_tmp[i].b_IsValid())	return ErrorCode::NOT_EXIST;

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

	// 单册信息更新（仅限 Admin ）（增加及修改操作）
	// 单册中的借阅事务相关（ BorrowerID ，DueDate ）理论上不应该在此修改
	[[nodiscard]] static ErrorCode VolUpdate(Book& bkin, const Volume& volin, const AdminAccount& admin) {
		
		// Admin 鉴权
		if (!admin.b_IsValid() || admin.enum_AdminAuth() != Auth::Admin)	return ErrorCode::NO_ACCESS;

		// 软删除检验
		if (!volin.b_IsValid())	return ErrorCode::NOT_EXIST;

		// 非法输入检验
		if (volin.enum_IsAvailable() == Availability::Illegal)	return ErrorCode::ILLEGAL_INPUT;

		// 搜寻单册信息，若已存在单册即更新
		int i = 0;
		bool isExist = false;

		QList<Volume> vl_tmp = bkin.ql_VolumeList();
		for (i = 0; i < vl_tmp.size(); i++) {
			if (vl_tmp[i].c_VolID() == volin.c_VolID()) {
				isExist = true;
				vl_tmp[i].SetAvailability(volin.enum_IsAvailable());
				vl_tmp[i].SetIsOpenshelf(volin.b_IsOpenshelf());
				vl_tmp[i].SetLocation(volin.stct_Location());
				vl_tmp[i].SetNote(volin.qs_Note());
				vl_tmp[i].SetIsValid(volin.b_IsValid());
				break;
			}
		}
		if (!isExist)	vl_tmp.append(volin);

		// 更新
		BookDAO bkDAO;
		bkin.SetVolumeList(vl_tmp);
		try {
			ErrorCode status= bkDAO.updateVolumeInfo(bkin);
			return status;
		}
		catch (DatabaseException& ex) {
			qWarning() << "错误：" << ex.qWhat();
			return ex.code();
		}

		return ErrorCode::SUCCESS;

	}

	// 单册删除（仅限 Admin ）
	[[nodiscard]] static ErrorCode VolDelete(Book& bkin, const Volume& volin, const AdminAccount& admin) {
		// Admin 鉴权
		if (!admin.b_IsValid() || admin.enum_AdminAuth() != Auth::Admin)	return ErrorCode::NO_ACCESS;

		// 软删除检验
		if (!volin.b_IsValid())	return ErrorCode::NOT_EXIST;


		// 搜寻单册信息及业务校验
		int i = 0;
		bool isExist = false;

		QList<Volume> vl_tmp = bkin.ql_VolumeList();
		for (i = 0; i < vl_tmp.size(); i++) {
			if (vl_tmp[i].c_VolID() == volin.c_VolID()) {
				isExist = true;
				// 禁止删除未归还的单册
				if (vl_tmp[i].enum_IsAvailable() == Availability::Unavailable_OnLoan) {
					return ErrorCode::VOLUME_ONLOAN;
				}
				// 软删除
				vl_tmp[i].SetIsValid(false);
				vl_tmp[i].SetAvailability(Availability::Unavailable_Deleted);
				break;
			}
		}
		if (!isExist)	return ErrorCode::NOT_EXIST;

		// 更新
		BookDAO bkDAO;
		bkin.SetVolumeList(vl_tmp);
		try {
			ErrorCode status = bkDAO.updateVolumeInfo(bkin);
			return status;
		}
		catch (DatabaseException& ex) {
			qWarning() << "错误：" << ex.qWhat();
			return ex.code();
		}

		return ErrorCode::SUCCESS;

	}

	// 禁止 Reader 修改单册信息
	[[nodiscard]] static ErrorCode VolUpdate(Book& bkin, const Volume& volin, const ReaderAccount& reader) {
		return ErrorCode::NO_ACCESS;
	}

	[[nodiscard]] static ErrorCode VolDelete(Book& bkin, const Volume& volin, const ReaderAccount& reader) {
		return ErrorCode::NO_ACCESS;
	}

};

class BookOperation {// 图书操作
public:

	// 图书信息更新（仅限 Admin ）（增加及修改操作）
	[[nodiscard]] static ErrorCode BookUpdate(Book& in, const AdminAccount& admin) {

		// Admin 鉴权
		if (!admin.b_IsValid() || admin.enum_AdminAuth() != Auth::Admin)	return ErrorCode::NO_ACCESS;

		// 空输入检验
		if (in.qs_Name().isEmpty() || in.ql_Author().isEmpty())	return ErrorCode::EMPTY_INPUT;

		// 软删除检验
		if (!in.b_IsValid())	return ErrorCode::NOT_EXIST;

		// 更新
		BookDAO bkDAO;
		QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");

		// 在 Service 开启事务
		if (!db.transaction()) {
			return ErrorCode::DATABASE_ERROR;
		}

		try {
			ErrorCode status = bkDAO.updateBookInfo(in);
			if (status != ErrorCode::SUCCESS) {
				db.rollback();
				return status;
			}

			if (!db.commit()) {
				throw DatabaseException(ErrorCode::DATABASE_ERROR, "事务提交失败");
			}
			return ErrorCode::SUCCESS;
		}
		catch (DatabaseException& ex) {
			db.rollback(); // 捕获底层抛出的异常并全局回滚
			qWarning() << "错误：" << ex.qWhat();
			return ex.code();
		}
		catch (const std::exception& ex) { // 核心修复：捕获标准库抛出的堆栈或缓存溢出异常
			db.rollback();
			qCritical() << "底层发生严重的 C++ 内存或逻辑异常：" << ex.what();
			return ErrorCode::SYSTEM_ERROR;
		}
	}

	// 图书删除（仅限 Admin ）
	[[nodiscard]] static ErrorCode BookDelete(Book& in, const AdminAccount& admin) {

		// Admin 鉴权
		if (!admin.b_IsValid() || admin.enum_AdminAuth() != Auth::Admin)	return ErrorCode::NO_ACCESS;

		// 软删除检验
		if (!in.b_IsValid())	return ErrorCode::NOT_EXIST;

		// 检验是否存在未归还的单册
		int i = 0;
		QList<Volume> vl_tmp = in.ql_VolumeList();
		for (i = 0; i < vl_tmp.size(); i++) {
			if (vl_tmp[i].enum_IsAvailable() == Availability::Unavailable_OnLoan)
				return ErrorCode::VOLUME_ONLOAN;
		}

		// 下属单册一并删除
		for (i = 0; i < vl_tmp.size(); i++) {
			vl_tmp[i].SetIsValid(false);
			vl_tmp[i].SetAvailability(Availability::Unavailable_Deleted);
		}
		in.SetVolumeList(vl_tmp);
		in.SetIsValid(false);

		// 同步更新
		BookDAO bkDAO;
		QSqlDatabase db = QSqlDatabase::database("qt_sql_default_connection");
		if (!db.transaction()) {
			return ErrorCode::DATABASE_ERROR;
		}

		try {
			bkDAO.updateBookInfo(in);
			bkDAO.updateVolumeInfo(in);

			if (!db.commit()) {
				throw DatabaseException(ErrorCode::DATABASE_ERROR, "删除失败");
			}
		}
		catch (DatabaseException& ex) {
			db.rollback(); // 发生异常即回滚
			qWarning() << "删除失败，数据已回滚：" << ex.qWhat();
			return ex.code();
		}

		return ErrorCode::SUCCESS;

	}

	// 禁止 Reader 修改单册信息
	[[nodiscard]] static ErrorCode BookUpdate(Book& in, const ReaderAccount& reader) {
		return ErrorCode::NO_ACCESS;
	}

	[[nodiscard]] static ErrorCode BookDelete(Book& in, const ReaderAccount& reader) {
		return ErrorCode::NO_ACCESS;
	}


};

