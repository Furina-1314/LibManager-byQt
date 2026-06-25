//数据类
#pragma once
#include<QDate>
#include<QList>
#include<QString>
#include <QRandomGenerator>
#include <QCryptographicHash>
#include <QByteArray>
#include "header/TypeCode.h"
struct BookLocation {        

	Library libraryID = Library::Illegal; // 馆
	int floor = -1;                       // 楼层
	Area areaID = Area::Illegal;          // 图书区
	int shelf = -1;                       // 架
	int layer = -1;                       // 层
	//有效性自检
	bool isValid() const {
		return libraryID != Library::Illegal &&
			areaID != Area::Illegal &&
			floor >= 0 && shelf >= 0 && layer >= 0;
	}
};//馆藏位置
class ISBN {
private:
	QString Value;//ISBN的值
	bool isValid;
public:
	// 缺省构造：处于非法空状态
	ISBN() : Value(""), isValid(false) {}
	// Setter
	[[nodiscard]] ErrorCode SetValue(const QString& Input) {
		//空输入检查
		if (Input.isEmpty()) {
			isValid = false;
			return ErrorCode::EMPTY_INPUT;
		}
		//正负检查
		if (Input.startsWith('-')) {
			isValid = false;
			return ErrorCode::ILLEGAL_INPUT;
		}
		// 位数检查，仅放行10位或13位的纯数字串
		int len = Input.length();
		if (len == 10 || len == 13) {
			Value = Input;
			isValid = true;
			return ErrorCode::SUCCESS;
		}
		else {
			isValid = false;
			return ErrorCode::ILLEGAL_INPUT;
		}//位数不符
	}
	// Getter
	const QString& qs_Value() const { return Value; }
	const bool b_isValid() const { return isValid; }
};
struct UserID {
	long long int Value = -1;//UserID的值，默认非法
	//运算符重载
	bool operator ==(const UserID& other) const { return Value == other.Value; }
	bool operator !=(const UserID& other) const { return Value != other.Value; }
};
struct VolumeID {
	long long int Value = -1;//VolumeID的值，默认非法
	//运算符重载
	bool operator ==(const VolumeID& other) const { return Value == other.Value; }
	bool operator !=(const VolumeID& other) const { return Value != other.Value; }
};
class Volume {
private:
	VolumeID ID;//单册ID，默认初始化置零，实际数据应为条码编号
	Availability IsAvailable;//可用状态
	bool IsOpenshelf;//是否开架图书，1为开架图书，0为闭架图书
	BookLocation Location;//馆藏位置
	QDate DueDate;//外借到期时间
	long long int BorrowerID;//目前借阅者的ID，预备供用户管理使用
public:
	Volume(Availability b = Availability::Illegal, bool c = 0, QDate date = QDate()) {
		IsAvailable = b; IsOpenshelf = c;
		DueDate = date;
		BorrowerID = -1;
	}
	const VolumeID stct_ID() const { return ID; }
	const Availability enum_IsAvailable() const { return IsAvailable; }
	const bool b_IsOpenshelf() const { return IsOpenshelf; }
	const BookLocation& stct_Location() const { return Location; }
	const QDate& qd_DueDate() const { return DueDate; }
	ErrorCode SetID(const VolumeID& in) {
		if (in.Value > 0) { ID = in; return ErrorCode::SUCCESS; }
		else  return ErrorCode::ILLEGAL_INPUT;
	}
	ErrorCode SetBorrwerID(const long long int id) {
		if (IsAvailable == Availability::Available) { BorrowerID = id; return ErrorCode::SUCCESS; }
		else  return ErrorCode::ILLEGAL_INPUT;
	}
	ErrorCode SetAvailability(const Availability in) {
		if (in != Availability::Illegal) { IsAvailable = in; return ErrorCode::SUCCESS; }
		else  return ErrorCode::ILLEGAL_INPUT;
	}
	ErrorCode SetIsOpenshelf(bool in) {
		IsOpenshelf = in; return ErrorCode::SUCCESS;
	}
	void SetDueDate(const QDate& in) { DueDate = in; }
	void SetLocation(const BookLocation& in) { Location = in; }
};
class Book {
private:
	ISBN BookISBN;//ISBN编码
	QString Name;//书名
	QList<QString> Author;//作者（一位或若干位）
	QString Press;//出版社
	Category PubCategory;//图书分类
	int PubYear;//出版年份
	Language PubLanguage;//出版文种
	QList<Volume> VolumeList;//单册列表
public:
	Book(QString b = "", QList<QString> auth = QList<QString>(), QString prss = "",
		Category cat = Category::Illegal, int yr = -9999, Language lang = Language::Illegal,
		QList<Volume> list = QList<Volume>()) {
		Name = b; Author = auth; Press = prss;
		PubCategory = cat; PubYear = yr; PubLanguage = lang;
		VolumeList = list;
	}
	const QString& qs_Name() const { return Name; }
	const QList<QString>& ql_Author() const { return Author; }
	const QString& qs_Press() const { return Press; }
	const Category enum_PubCategory() const { return PubCategory; }
	const int i_PubYear() const { return PubYear; }
	const Language enum_PubLanguage() const { return PubLanguage; }
	const QList<Volume>& ql_VolumeList() const { return VolumeList; }
	ErrorCode SetISBN(const QString& in) { return BookISBN.SetValue(in); }
	ErrorCode SetName(const QString& in) {
		if (in.isEmpty()) { return ErrorCode::EMPTY_INPUT; }
		else { Name = in; return ErrorCode::SUCCESS; }
	}
	ErrorCode SetAuthor(const QList<QString>& in) {
		if (in.isEmpty() || in[0].isEmpty()) { return ErrorCode::EMPTY_INPUT; }
		else { Author = in; return ErrorCode::SUCCESS; }
	}
	ErrorCode SetPress(const QString& in) {
		if (in.isEmpty()) { return ErrorCode::EMPTY_INPUT; }
		else { Press = in; return ErrorCode::SUCCESS; }
	}
	ErrorCode SetPubCategory(const Category in) {
		if (in != Category::Illegal) { PubCategory = in; return ErrorCode::SUCCESS; }
		else  return ErrorCode::ILLEGAL_INPUT;
	}
	void SetPubYear(const int yr) { PubYear = yr; }
	ErrorCode SetPubLanguage(const Language in) {
		if (in != Language::Illegal) { PubLanguage = in; return ErrorCode::SUCCESS; }
		else  return ErrorCode::ILLEGAL_INPUT;
	}
};
class LoanRecord {
private:
	long long int RecordID = -1; //借阅流水号（数据库自增主键）
	VolumeID VolumeIDValue;//单册ID
	UserID BorrowerID;//借阅者ID
	bool IsReturned;//是否已归还，默认为1（已归还）
	QDate LoanDate;//借书日期
	QDate DueDate;//应还日期
	QDate ReturnDate;//归还日期
public:
	LoanRecord(bool b = true, QDate c = QDate(), QDate d = QDate(), QDate e = QDate()) :
		IsReturned(b), LoanDate(c), DueDate(d), ReturnDate(e) {
	}
	//Getter
	const long long int lli_RecordID() const { return RecordID; }
	const VolumeID& stct_VolumeIDValue() const { return VolumeIDValue; }
	const UserID& stct_BorrowerID() const { return BorrowerID; }
	const bool b_IsReturned() const { return IsReturned; }
	const QDate& qd_LoanDate() const { return LoanDate; }
	const QDate& qd_DueDate() const { return DueDate; }
	const QDate& qd_ReturnDate() const { return ReturnDate; }
	//Setter
	[[nodiscard]] ErrorCode SetRecordID(long long int id) {
		if (id <= 0) return ErrorCode::ILLEGAL_INPUT;
		RecordID = id; return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode SetVolumeID(const VolumeID& id) {
		if (id.Value <= 0) return ErrorCode::ILLEGAL_INPUT;
		VolumeIDValue = id; return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode SetBorrowerID(const UserID& id) {
		if (id.Value <= 0) return ErrorCode::ILLEGAL_INPUT;
		BorrowerID = id; return ErrorCode::SUCCESS;
	}
	void SetLoanDate(const QDate& d) { LoanDate = d; }
	void SetDueDate(const QDate& d) { DueDate = d; }
	void SetReturnDate(const QDate& d) { ReturnDate = d; }
	void SetIsReturned(bool b) { IsReturned = b; }
};
class BorrowHistory {
private:
	ISBN BookISBN;
	QList<LoanRecord> RecordList;
public:
	BorrowHistory(QList<LoanRecord> b = QList<LoanRecord>()) {
		RecordList = b;
	}
	//Getter
	const QList<LoanRecord>& ql_RecordList() const { return RecordList; }
};
class Account {
private:
	UserID ID;//用户ID，Reader的ID应为8位数字
	bool IsValid;//账户有效性
	QString Name;
	Auth UserAuth;
	QByteArray PasswordHash; // Hash
	QByteArray Salt;         // salt
public:
	Account() :Name(""), IsValid(false), UserAuth(Auth::Illegal) {}
	// 身份与名称Setter
	[[nodiscard]] ErrorCode SetID(long long int id) {
		if (!(ID.Value <= 99999999 && ID.Value >= 10000000)) return ErrorCode::ILLEGAL_INPUT;
		ID.Value = id;
		return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode SetName(const QString& name) {
		if (name.isEmpty()) return ErrorCode::EMPTY_USERNAME;
		Name = name;
		return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode SetUserAuth(Auth in) {
		if (in == Auth::Reader || in == Auth::Admin) { UserAuth = in; return ErrorCode::SUCCESS; }
		else  return ErrorCode::SYSTEM_ERROR;
	}
	[[nodiscard]] ErrorCode SetIsValid(bool in) {
		IsValid = in; return ErrorCode::SUCCESS;
	}
	// 密码设值（存储Hash）
	[[nodiscard]] ErrorCode SetPassword(const QString& plainPassword) {
		if (plainPassword.length() < 8) return ErrorCode::PASSWORD_TOO_SHORT;
		//生成随机盐 (Salt)
		this->Salt = QByteArray::number(QRandomGenerator::global()->generate64(), 16);
		//加盐哈希 (Salt + Password)
		QByteArray combined = plainPassword.toUtf8() + Salt;
		this->PasswordHash = QCryptographicHash::hash(combined, QCryptographicHash::Sha3_512);
		return ErrorCode::SUCCESS;
	}
	//终态自检接口，确保该账户已准备就绪
	const bool IsReady() const {
		return IsValid && !Name.isEmpty() && !PasswordHash.isEmpty();
	}
	//Getter
	const UserID& stct_ID() const { return ID; }
	const bool b_IsValid() const { return IsValid; }
	const QString& qs_Name() const { return Name; }
	const Auth enum_UserAuth() const { return UserAuth; }
	const QByteArray& qba_PasswordHash() const { return PasswordHash; }
	const QByteArray& qba_Salt() const { return Salt; }
};
