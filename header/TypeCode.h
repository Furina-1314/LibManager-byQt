//状态码
#pragma once
enum class Availability //可用状态
{
	Illegal = -1,//不合法的单册数据：默认初始化的对象
	Available = 1,//可外借
	Unavailable_OnLoan = 2,//不可外借：外借中
	Unavailable_Lost = 3,//不可外借：单册丢失
	Unavailable_Processing = 4//不可外借：文献加工中
};
enum class Library //分馆信息
{
	Illegal = -1,//初始化默认值
	LIB_North = 1,
	LIB_West = 2,
	LIB_Economic = 3,
	LIB_Literature = 4,
	LIB_Law = 5
};
enum class Area //图书区信息：东/西/南/北区
{
	Illegal = -1,//初始化默认值
	AREA_E = 1, AREA_W = 2, AREA_S = 3, AREA_N = 4
};
enum  class ErrorCode //错误代码
{
	SUCCESS = 0,//成功
	//用户相关错误
	USERID_NOT_EXIST = 1000,//用户名不存在
	WRONG_PASSWORD = 1001,//密码错误
	WRONG_USERID = 1002,//ID错误
	ACCOUNT_ALREADY_EXIST = 1003,//账户已存在
	NO_ACCESS = 1004,//无权限
	ACCOUNT_INVALID = 1005,//不可用的账户
	EMPTY_USERNAME = 1006,//空用户名
	PASSWORD_TOO_SHORT = 1007,//密码过短
	PASSWORD_MISMATCH = 1008,//两次密码不一致（注册时）
	//业务相关错误
	EMPTY_INPUT = 2001,//空输入
	ILLEGAL_INPUT = 2002,//非法输入：输入不合格式或赋值意图违反逻辑
	NO_RESULT = 2003,//未找到结果
	VOLUME_ALREADY_BORROWED = 2004,//单册已借阅（针对同一账户对同一单册的重复借阅操作）
	VOLUME_ONLOAN = 2005,//单册已外借
	VOLUME_RESERVED = 2006,//单册不可获取：已被预约
	VOLUME_NOT_AVAILABLE = 2007,//单册不可获取：其他情况
	VOLUME_OVERDUE = 2008,//存在单册逾期
	VOLUME_NOT_BORROWED = 2009,//单册未处于外借状态
	MAX_BORROW_LIMIT = 2010,//账户达到借阅上限
	VOLUME_ALREADY_EXIST = 2011,//创建的单册已存在（对于Admin）
	BOOK_ALREADY_EXIST = 2012,//创建的图书已存在（对于Admin）
	NOT_EXIST = 2013,//删改的单册/图书不存在（对于Admin）
	LOCATION_INVALID = 2014,// 馆藏位置无效
	//系统相关错误
	SYSTEM_ERROR = 3001,//意外的系统错误
	//3002-3005暂时空缺
	FAILED_SEARCH = 3006,//搜寻失败
	FAILED_TO_READ = 3007,//读失败
	FAILED_TO_WRITE = 3008,//写失败
	DATABASE_BUSY = 3009,//数据库忙
	DATABASE_ERROR = 3010,//数据库错误
	DATABASE_OPEN_FAILED = 3011,//数据库打开错误
	TRANSACTION_START_FAILED = 3012,//事务开始错误
	DATA_ERROR = 3013,//数据错误（存在ID重复或非法等情况）
	//预留项
	OTHER_ERROR = 9999//其他（可能的）错误
};
enum class Language //出版文种
{
	Illegal = -1,//初始化默认值
	Chinese = 1,
	English = 2,
	Russian = 3,
	French = 4,
	Spanish = 5,
	Arabic = 6,
	Japanese = 7,
	Korean = 8,
	Other = 9
};
enum class Category //图书分类
{
	Illegal = -1,//初始化默认值
	Literature = 1,
	Philosophy = 2,
	Linguistics = 3,
	Art = 4,
	Technology = 5
};
enum class Auth //用户身份
{
	Illegal = -1,
	Reader = 1,//读者
	Admin = 2//管理员
};
enum class Filter //借阅流水的搜寻条件
{
	ISBN = 1,
	VolID = 2,
	Title = 3,
	BorrowerID = 4,
	IsReturned = 5,
	IsOverdue = 6,
	BorrowDate = 7,
	DueDate = 8,
	ReturnDate = 9
};