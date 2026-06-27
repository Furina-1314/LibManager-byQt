//数据类
//数据类主要用于打包转发
#pragma once
#include<QDate>
#include<QList>
#include<QString>
#include <QRandomGenerator>
#include <QCryptographicHash>
#include <QByteArray>
#include <QRegularExpression>
#include "header/TypeCode.h"
class NumCheck //纯数字ID检验
{
public:
	const ErrorCode IsNumID(const QString& str) const {
		int i = 0;
		for (i = 0; i < str.length(); i++) {
			if (!str[i].isDigit())	return ErrorCode::ILLEGAL_INPUT;
		}
		return ErrorCode::SUCCESS;
	}
};
class DigitCheck //位数检验
{
public:
	const ErrorCode IsRightDigit(const QString& str, int digit) const {
		if (str.length() == digit) return ErrorCode::SUCCESS;
		else  return ErrorCode::ILLEGAL_INPUT;
	}
};
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
class StringID {//字符型ID的抽象类
public:
	virtual ~StringID() = default;
	//设置值
	[[nodiscard]] virtual ErrorCode SetValue(const QString& Input) = 0;
	//Getter
	virtual const QString& qs_Value() const = 0;
};
class ISBN :public StringID,public NumCheck,public DigitCheck {
private:
	QString Value;//ISBN的值
public:
	//析构
	~ISBN() override = default;
	// 缺省构造：处于非法空状态
	ISBN() : Value("") {}
	// Setter
	[[nodiscard]] ErrorCode SetValue(const QString& Input) {
		if (Input.isEmpty())	return ErrorCode::EMPTY_INPUT;
		else {
			if (IsNumID(Input) == ErrorCode::SUCCESS &&
				(IsRightDigit(Input, 13) == ErrorCode::SUCCESS || IsRightDigit(Input, 10) == ErrorCode::SUCCESS)) {
				Value = Input; return ErrorCode::SUCCESS;
			}
			else  return ErrorCode::ILLEGAL_INPUT;
		}
	}
	//运算符重载
	bool operator ==(const ISBN& other) const { return Value == other.Value; }
	bool operator !=(const ISBN& other) const { return Value != other.Value; }
	// Getter
	const QString& qs_Value() const { return Value; }
};
class UserID :public StringID, public NumCheck, public DigitCheck {
private:
	QString Value;//用户ID的值
public:
	//析构
	~UserID() override = default;
	// 缺省构造：处于非法空状态
	UserID() : Value("") {}
	// Setter
	[[nodiscard]] ErrorCode SetValue(const QString& Input) {
		if (Input.isEmpty())	return ErrorCode::EMPTY_INPUT;
		else {
			if (IsNumID(Input) == ErrorCode::SUCCESS &&
				IsRightDigit(Input, 8) == ErrorCode::SUCCESS) {//8位ID
				Value = Input; return ErrorCode::SUCCESS;
			}
			else  return ErrorCode::ILLEGAL_INPUT;
		}
	}
	//运算符重载
	bool operator ==(const UserID& other) const { return Value == other.Value; }
	bool operator !=(const UserID& other) const { return Value != other.Value; }
	// Getter
	const QString& qs_Value() const { return Value; }
};
class AdminID :public StringID, public NumCheck, public DigitCheck {
private:
	QString Value;//管理员ID的值
public:
	//析构
	~AdminID() override = default;
	// 缺省构造：处于非法空状态
	AdminID() : Value("") {}
	// Setter
	[[nodiscard]] ErrorCode SetValue(const QString& Input) {
		if (Input.isEmpty())	return ErrorCode::EMPTY_INPUT;
		else {
			if (IsNumID(Input) == ErrorCode::SUCCESS &&
				IsRightDigit(Input, 5) == ErrorCode::SUCCESS) {//5位ID
				Value = Input; return ErrorCode::SUCCESS;
			}
			else  return ErrorCode::ILLEGAL_INPUT;
		}
	}
	//运算符重载
	bool operator ==(const AdminID& other) const { return Value == other.Value; }
	bool operator !=(const AdminID& other) const { return Value != other.Value; }
	// Getter
	const QString& qs_Value() const { return Value; }
};
class VolumeID :public StringID, public NumCheck {
private:
	QString Value;//用户ID的值
public:
	//析构
	~VolumeID() override = default;
	// 缺省构造：处于非法空状态
	VolumeID() : Value("") {}
	// Setter
	[[nodiscard]] ErrorCode SetValue(const QString& Input) {
		if (Input.isEmpty())	return ErrorCode::EMPTY_INPUT;
		else {
			if (IsNumID(Input) == ErrorCode::SUCCESS) {
				Value = Input; return ErrorCode::SUCCESS;
			}
			else  return ErrorCode::ILLEGAL_INPUT;
		}
	}
	//运算符重载
	bool operator ==(const VolumeID& other) const { return Value == other.Value; }
	bool operator !=(const VolumeID& other) const { return Value != other.Value; }
	// Getter
	const QString& qs_Value() const { return Value; }
};
class Volume {
private:
	VolumeID VolID;//单册ID，默认初始化置零，实际数据应为条码编号
	Availability IsAvailable;//可用状态
	bool IsOpenshelf;//是否开架图书，1为开架图书，0为闭架图书
	BookLocation Location;//馆藏位置
	QDate DueDate;//外借到期时间
	UserID BorrowerID;//目前借阅者的ID，预备供用户管理使用
public:
	Volume(Availability b = Availability::Illegal, bool c = 0, QDate date = QDate()) {
		IsAvailable = b; IsOpenshelf = c;
		DueDate = date;
			}
	const Availability enum_IsAvailable() const { return IsAvailable; }
	const bool b_IsOpenshelf() const { return IsOpenshelf; }
	const BookLocation& stct_Location() const { return Location; }
	const QDate& qd_DueDate() const { return DueDate; }
	ErrorCode SetVolID(const VolumeID& in) {
		return VolID.SetValue(in.qs_Value());
	}
	ErrorCode SetBorrwerID(const UserID& in) {
		return BorrowerID.SetValue(in.qs_Value());
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
	ISBN BookISBN;//单册ISBN
	VolumeID VolID;//单册ID
	UserID BorrowerID;//借阅者ID
	bool IsReturned;//是否已归还，默认为1（已归还）
	bool IsOverdue;//是否已逾期，默认为0（未逾期）
	QDate LoanDate;//借书日期
	QDate DueDate;//应还日期
	QDate ReturnDate;//归还日期
public:
	LoanRecord(bool b = true, bool bb=false,QDate c = QDate(), QDate d = QDate(), QDate e = QDate()) :
		IsReturned(b), IsOverdue(bb), LoanDate(c), DueDate(d), ReturnDate(e) {}
	//Getter
	const long long int lli_RecordID() const { return RecordID; }
	const bool b_IsReturned() const { return IsReturned; }
	const bool b_IsOverdue() const { return IsOverdue; }
	const QDate& qd_LoanDate() const { return LoanDate; }
	const QDate& qd_DueDate() const { return DueDate; }
	const QDate& qd_ReturnDate() const { return ReturnDate; }
	//Setter
	[[nodiscard]] ErrorCode SetRecordID(long long int id) {
		if (id <= 0) return ErrorCode::ILLEGAL_INPUT;
		RecordID = id; return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode SetVolumeID(const VolumeID& in) {
		return VolID.SetValue(in.qs_Value());
	}
	[[nodiscard]] ErrorCode SetBorrowerID(const UserID& id) {
		return BorrowerID.SetValue(id.qs_Value());
	}
	void SetLoanDate(const QDate& d) { LoanDate = d; }
	void SetDueDate(const QDate& d) { DueDate = d; }
	void SetReturnDate(const QDate& d) { ReturnDate = d; }
	void SetIsReturned(bool b) { IsReturned = b; }
	void SetIsOverdue(bool b) { IsOverdue = b; }
};
class ReaderAccount {
private:
	UserID ID;//用户ID，ReaderID应为8位非零开头数字
	bool IsValid;//账户有效性
	QString Name;
	Auth ReaderAuth;
	QByteArray PasswordHash; // Hash
	QByteArray Salt;         // salt
	int BorrowLimit;//借阅上限
public:
	ReaderAccount() :Name(""), IsValid(false), ReaderAuth(Auth::Illegal), BorrowLimit(-1) {}
	// 身份与名称Setter
	[[nodiscard]] ErrorCode SetID(const UserID& id) {
		return ID.SetValue(id.qs_Value());
	}
	[[nodiscard]] ErrorCode SetName(const QString& name) {
		if (name.isEmpty()) return ErrorCode::EMPTY_USERNAME;
		Name = name;
		return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode ActivateReader(Auth in) {
		if (in == Auth::Reader) { ReaderAuth = in; return ErrorCode::SUCCESS; }
		else if (in == Auth::Admin) { return ErrorCode::NO_ACCESS; }//Reader无权限置为Admin
		else  return ErrorCode::SYSTEM_ERROR;//不应有其他情况
	}
	[[nodiscard]] ErrorCode SetIsValid(bool in) {
		IsValid = in; return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode SetBorrowLimit(int in) {
		if (in<0) { return ErrorCode::ILLEGAL_INPUT; }
		else { BorrowLimit=in; return ErrorCode::SUCCESS; }
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
	const bool b_IsValid() const { return IsValid; }
	const QString& qs_Name() const { return Name; }
	const Auth enum_ReaderAuth() const { return ReaderAuth; }
	const QByteArray& qba_PasswordHash() const { return PasswordHash; }
	const QByteArray& qba_Salt() const { return Salt; }
	const int i_BorrowLimit() const { return BorrowLimit; }
};
class AdminAccount {
private:
	AdminID ID;//用户ID，AdminID应为5位非零开头数字
	bool IsValid;//账户有效性
	Auth AdminAuth;
	QByteArray PasswordHash; // Hash
	QByteArray Salt;         // salt
public:
	AdminAccount() :IsValid(false), AdminAuth(Auth::Illegal) {}
	// Setter
	[[nodiscard]] ErrorCode SetID(const AdminID& id) {
		return ID.SetValue(id.qs_Value());
	}
	[[nodiscard]] ErrorCode ActivateAdmin(Auth in) {
		if (in == Auth::Admin) { AdminAuth = in; return ErrorCode::SUCCESS; }
		else if (in == Auth::Reader) { return ErrorCode::NO_ACCESS; }//Admin无权限置为Reader
		else  return ErrorCode::SYSTEM_ERROR;//不应有其他情况
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
		return IsValid && !PasswordHash.isEmpty();
	}
	//Getter
	const bool b_IsValid() const { return IsValid; }
	const Auth enum_AdminAuth() const { return AdminAuth; }
	const QByteArray& qba_PasswordHash() const { return PasswordHash; }
	const QByteArray& qba_Salt() const { return Salt; }
};
