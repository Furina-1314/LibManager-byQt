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
	virtual ~NumCheck() = default;
	static ErrorCode IsNumID(const QString& str) {
		int i = 0;
		for (i = 0; i < str.length(); i++) {
			if (!str[i].isDigit())	return ErrorCode::ILLEGAL_INPUT;
		}
		if (str[0] == '0')	return ErrorCode::ILLEGAL_INPUT;//要求非零开头
		return ErrorCode::SUCCESS;
	}
};
class DigitCheck //位数检验
{
public:
	virtual ~DigitCheck() = default;
	static ErrorCode IsRightDigit(const QString& str, int digit) {
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
	QString Note;//单册信息备注
public:
	Volume(Availability b = Availability::Illegal, bool c = 0, QDate date = QDate()) {
		IsAvailable = b; IsOpenshelf = c;
		DueDate = date;
			}
	Availability enum_IsAvailable() const { return IsAvailable; }
	bool b_IsOpenshelf() const { return IsOpenshelf; }
	const BookLocation& stct_Location() const { return Location; }
	const QDate& qd_DueDate() const { return DueDate; }
	const QString& qs_Note() const { return Note; }
	[[nodiscard]] ErrorCode SetVolID(const VolumeID& in) {
		return VolID.SetValue(in.qs_Value());
	}
	[[nodiscard]] ErrorCode SetBorrowerID(const UserID& in) {
		return BorrowerID.SetValue(in.qs_Value());
	}
	[[nodiscard]] ErrorCode SetAvailability(const Availability in) {
		if (in != Availability::Illegal) { IsAvailable = in; return ErrorCode::SUCCESS; }
		else  return ErrorCode::ILLEGAL_INPUT;
	}
	[[nodiscard]] ErrorCode SetIsOpenshelf(bool in) {
		IsOpenshelf = in; return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode SetDueDate(const QDate& in) { DueDate = in; return ErrorCode::SUCCESS; }
	[[nodiscard]] ErrorCode SetLocation(const BookLocation& in) { Location = in; return ErrorCode::SUCCESS; }
	[[nodiscard]] ErrorCode SetNote(const QString& in) { Note = in; return ErrorCode::SUCCESS; }
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
	QString Introduction;//图书介绍
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
	Category enum_PubCategory() const { return PubCategory; }
	int i_PubYear() const { return PubYear; }
	Language enum_PubLanguage() const { return PubLanguage; }
	const QList<Volume>& ql_VolumeList() const { return VolumeList; }
	const QString& qs_Introduction() const { return Introduction; }
	[[nodiscard]] ErrorCode SetISBN(const QString& in) { return BookISBN.SetValue(in); }
	[[nodiscard]] ErrorCode SetName(const QString& in) {
		if (in.isEmpty()) { return ErrorCode::EMPTY_INPUT; }
		else { Name = in; return ErrorCode::SUCCESS; }
	}
	[[nodiscard]] ErrorCode SetAuthor(const QList<QString>& in) {
		if (in.isEmpty() || in[0].isEmpty()) { return ErrorCode::EMPTY_INPUT; }
		else { Author = in; return ErrorCode::SUCCESS; }
	}
	[[nodiscard]] ErrorCode SetPress(const QString& in) {
		if (in.isEmpty()) { return ErrorCode::EMPTY_INPUT; }
		else { Press = in; return ErrorCode::SUCCESS; }
	}
	[[nodiscard]] ErrorCode SetPubCategory(const Category in) {
		if (in != Category::Illegal) { PubCategory = in; return ErrorCode::SUCCESS; }
		else  return ErrorCode::ILLEGAL_INPUT;
	}
	[[nodiscard]] ErrorCode SetPubYear(const int yr) { PubYear = yr; return ErrorCode::SUCCESS; }
	[[nodiscard]] ErrorCode SetPubLanguage(const Language in) {
		if (in != Language::Illegal) { PubLanguage = in; return ErrorCode::SUCCESS; }
		else  return ErrorCode::ILLEGAL_INPUT;
	}
	[[nodiscard]] ErrorCode SetIntroduction(const QString& in) {
		if (in.isEmpty())	return ErrorCode::EMPTY_INPUT;
		Introduction = in; return ErrorCode::SUCCESS;
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
	long long int lli_RecordID() const { return RecordID; }
	bool b_IsReturned() const { return IsReturned; }
	bool b_IsOverdue() const { return IsOverdue; }
	const QDate& qd_LoanDate() const { return LoanDate; }
	const QDate& qd_DueDate() const { return DueDate; }
	const QDate& qd_ReturnDate() const { return ReturnDate; }
	//Setter
	[[nodiscard]] ErrorCode SetRecordID(long long int id) {
		if (id <= 0) return ErrorCode::ILLEGAL_INPUT;
		RecordID = id; return ErrorCode::SUCCESS;
	}
	[[nodiscard]] ErrorCode SetBookISBN(const ISBN& in) {
		return BookISBN.SetValue(in.qs_Value());
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
	bool IsReady() const {
		return IsValid && !Name.isEmpty() && !PasswordHash.isEmpty();
	}
	//Getter
	bool b_IsValid() const { return IsValid; }
	const QString& qs_Name() const { return Name; }
	Auth enum_ReaderAuth() const { return ReaderAuth; }
	const QByteArray& qba_PasswordHash() const { return PasswordHash; }
	const QByteArray& qba_Salt() const { return Salt; }
	int i_BorrowLimit() const { return BorrowLimit; }
};
class AdminAccount {
private:
	AdminID ID;//用户ID，AdminID应为5位非零开头数字
	const QString Name = "Admin";//Admin的用户名不可更改
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
	//终态自检，确保准备就绪
	bool IsReady() const {
		return IsValid && !PasswordHash.isEmpty();
	}
	//Getter
	bool b_IsValid() const { return IsValid; }
	const QString& qs_Name() const { return Name; }
	Auth enum_AdminAuth() const { return AdminAuth; }
	const QByteArray& qba_PasswordHash() const { return PasswordHash; }
	const QByteArray& qba_Salt() const { return Salt; }
};
