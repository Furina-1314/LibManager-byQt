//账户业务
#pragma once
#include "header/TypeCode.h"
#include "header/DataTemplates.h"
#include "header/DataException.h"
#include "header/DatabaseManager.h"
extern class QueryRequest;
extern class EditRequest;
extern class StatService;
class PasswordCheck {// 密码检查服务
public:
	// Reader 的密码检查
	[[nodiscard]] static ErrorCode ReaderPasswordCheck(const QString& passwd, const ReaderAccount& check) {
		QByteArray combined = passwd.toUtf8() + check.qba_Salt();
		if (QCryptographicHash::hash(combined, QCryptographicHash::Sha3_512) != check.qba_Salt())	return ErrorCode::WRONG_PASSWORD;
		else return ErrorCode::SUCCESS;
	}
	// Admin 的密码检查
	[[nodiscard]] static ErrorCode AdminPasswordCheck(const QString& passwd, const AdminAccount& check) {
		QByteArray combined = passwd.toUtf8() + check.qba_Salt();
		if (QCryptographicHash::hash(combined, QCryptographicHash::Sha3_512) != check.qba_Salt())	return ErrorCode::WRONG_PASSWORD;
		else return ErrorCode::SUCCESS;
	}


};
class Login :public PasswordCheck {// 登录服务
public:
	[[nodiscard]] ErrorCode ReaderLogin(ReaderAccount& in, const QString& passwd) const {// Reader 使用ID登录
		AccountDAO acDAO;
		QList<ReaderAccount> check;
		ErrorCode tmp = acDAO.isUserExists(in.c_ID().qs_Value());
		if (!(tmp == ErrorCode::SUCCESS))	return tmp;	// 检验用户是否存在
		// 依据 ID 获取数据库中用户信息，结果应唯一
		try {
			tmp = acDAO.getReaderInfo(in.c_ID().qs_Value(), check);
			if (check.size() != 1)	throw DatabaseException(ErrorCode::WRONG_USERID, "错误的 ID ");
		}
		catch (DatabaseException& ex) {
			qWarning() << "登录失败：" << ex.qWhat();
			return ex.code();
		}
		// 检验有效性
		if (check[0].b_IsValid() == false)	return ErrorCode::ACCOUNT_INVALID;

		// 密码检查
		return	ReaderPasswordCheck(passwd, check[0]);

	}

	[[nodiscard]] ErrorCode AdminLogin(AdminAccount& in, const QString& passwd) const {// Admin 使用ID登录
		AccountDAO acDAO;
		QList<AdminAccount> check;
		ErrorCode tmp = acDAO.isUserExists(in.c_ID().qs_Value());
		if (!(tmp == ErrorCode::ACCOUNT_ALREADY_EXIST))	return tmp;	// 检验用户是否存在
		// 依据 ID 获取数据库中用户信息，结果应唯一
		try {
			tmp = acDAO.getAdminInfo(in.c_ID().qs_Value(), check);
			if (check.size() != 1)	throw DatabaseException(ErrorCode::WRONG_USERID, "错误的 ID ");
		}
		catch (DatabaseException& ex) {
			qWarning() << "登录失败：" << ex.qWhat();
			return ex.code();
		}
		// 检验有效性
		if (check[0].b_IsValid() == false)	return ErrorCode::ACCOUNT_INVALID;

		// 密码检查
		return	AdminPasswordCheck(passwd, check[0]);

	}

};


class Logout {// 登出服务


};


class Register {// Reader 注册
public:
	[[nodiscard]] ErrorCode UserRegister(const UserID& id, const QString& name, QString& passwd, QString& confirmpasswd, const Auth role) {

		// Reader 注册
		if (role == Auth::Reader) {
			if (passwd != confirmpasswd)	return ErrorCode::PASSWORD_MISMATCH;	// 两次密码不一致
			if (passwd.length() < 8)	return ErrorCode::PASSWORD_TOO_SHORT;	// 密码要求不少于8位
			// 检查 ID 是否已存在
			AccountDAO acDAO;
			QList<ReaderAccount> check;
			ErrorCode tmp = acDAO.isUserExists(id.qs_Value());
			if (!(tmp == ErrorCode::ACCOUNT_ALREADY_EXIST))	return tmp;
			// 录入信息
			ReaderAccount regReader;
			regReader.SetID(id);
			regReader.SetName(name);
			regReader.SetPassword(passwd);
			regReader.SetIsValid(true);
			regReader.SetBorrowLimit(5);// Reader 默认借阅上限为5本
			regReader.ActivateReader(Auth::Reader);
			try {
				acDAO.updateReaderInfo(regReader);
			}
			catch (DatabaseException& ex) {
				qWarning() << "注册失败：" << ex.qWhat();
				return ex.code();
			}
			return ErrorCode::SUCCESS;
		}

		// Admin 不允许注册
		else return ErrorCode::NO_ACCESS;

	}

};
class Unregister : public PasswordCheck {// 注销服务，采取软删除的方式

	[[nodiscard]] ErrorCode ReaderUnregister(const ReaderAccount& in, const QString& passwd) const {// Reader 注销自己的账户，需要输入密码以确认操作
		AccountDAO acDAO;
		QList<ReaderAccount> check;
		ErrorCode tmp = acDAO.isUserExists(in.c_ID().qs_Value());
		if (!(tmp == ErrorCode::SUCCESS))	return tmp;	// 检验用户是否存在
		// 依据 ID 获取数据库中用户信息，结果应唯一
		try {
			tmp = acDAO.getReaderInfo(in.c_ID().qs_Value(), check);
			if (check.size() != 1)	throw DatabaseException(ErrorCode::WRONG_USERID, "错误的 ID ");
		}
		catch (DatabaseException& ex) {
			qWarning() << "注销失败：" << ex.qWhat();
			return ex.code();
		}
		// 检验有效性
		if (check[0].b_IsValid() == false)	return ErrorCode::ACCOUNT_INVALID;// 用户已不可用
		// 密码检查
		if (ReaderPasswordCheck(passwd, check[0]) == ErrorCode::WRONG_PASSWORD) {
			return ErrorCode::WRONG_PASSWORD;
		}

		// 注销账户
		check[0].SetIsValid(false);
		acDAO.updateReaderInfo(check[0]);
		return ErrorCode::SUCCESS;
	}

	// Admin 不允许自行注销
	[[nodiscard]] ErrorCode AdminUnregister(const AdminAccount& in) {
		return ErrorCode::NO_ACCESS;
	}
};

class EditProfile : public PasswordCheck {//编辑个人资料

	// Reader 更新用户名
	[[nodiscard]] ErrorCode ReaderEditName(ReaderAccount& in, const QString& passwd, const QString& newname) {
		AccountDAO acDAO;
		QList<ReaderAccount> check;
		ErrorCode tmp = acDAO.isUserExists(in.c_ID().qs_Value());
		if (!(tmp == ErrorCode::SUCCESS))	return tmp;	// 检验用户是否存在
		// 依据 ID 获取数据库中用户信息，结果应唯一
		try {
			tmp = acDAO.getReaderInfo(in.c_ID().qs_Value(), check);
			if (check.size() != 1)	throw DatabaseException(ErrorCode::WRONG_USERID, "错误的 ID ");
		}
		catch (DatabaseException& ex) {
			qWarning() << "失败：" << ex.qWhat();
			return ex.code();
		}
		// 检验有效性
		if (check[0].b_IsValid() == false)	return ErrorCode::ACCOUNT_INVALID;// 用户已不可用
		// 密码检查
		if (ReaderPasswordCheck(passwd, check[0]) == ErrorCode::WRONG_PASSWORD) {
			return ErrorCode::WRONG_PASSWORD;
		}

		// 更新用户名
		in.SetName(newname);
		acDAO.updateReaderInfo(in);
	}

	// Reader 更新密码
	[[nodiscard]] ErrorCode ReaderEditPassword(ReaderAccount& in, const QString& passwd, const QString& newpasswd, const QString& confirmnewpasswd) {
		AccountDAO acDAO;
		QList<ReaderAccount> check;
		ErrorCode tmp = acDAO.isUserExists(in.c_ID().qs_Value());
		if (!(tmp == ErrorCode::SUCCESS))	return tmp;	// 检验用户是否存在
		if (newpasswd != confirmnewpasswd)	return ErrorCode::PASSWORD_MISMATCH;	// 两次密码不一致
		if (newpasswd.length() < 8)	return ErrorCode::PASSWORD_TOO_SHORT;	// 密码要求不少于8位
		// 依据 ID 获取数据库中用户信息，结果应唯一
		try {
			tmp = acDAO.getReaderInfo(in.c_ID().qs_Value(), check);
			if (check.size() != 1)	throw DatabaseException(ErrorCode::WRONG_USERID, "错误的 ID ");
		}
		catch (DatabaseException& ex) {
			qWarning() << "失败：" << ex.qWhat();
			return ex.code();
		}
		// 检验有效性
		if (check[0].b_IsValid() == false)	return ErrorCode::ACCOUNT_INVALID;// 用户已不可用
		// 密码检查
		if (ReaderPasswordCheck(passwd, check[0]) == ErrorCode::WRONG_PASSWORD) {
			return ErrorCode::WRONG_PASSWORD;
		}

		// 更新密码
		in.SetPassword(newpasswd);
		acDAO.updateReaderInfo(in);

	}

	// Admin 不允许更改用户名
	[[nodiscard]] ErrorCode AdminEditName(const AdminAccount& in) {
		return ErrorCode::NO_ACCESS;
	}

	// Admin 不允许更改密码
	[[nodiscard]] ErrorCode AdminEditPassword(const AdminAccount& in) {
		return ErrorCode::NO_ACCESS;
	}

};
