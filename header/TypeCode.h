//错误码
#pragma once
enum class Availability {
	Illegal = -1,//不合法的单册数据：默认初始化的对象
	Available = 1,//可外借
	Unavailable_OnLoan = 2,//不可外借：外借中
	Unavailable_Lost = 3,//不可外借：单册丢失
	Unavailable_Processing = 4//不可外借：文献加工中
};//可用状态
enum class Library {
	Illegal = -1,//初始化默认值
	LIB_North = 1,
	LIB_West = 2,
	LIB_Economic = 3,
	LIB_Literature = 4,
	LIB_Law = 5
};//分馆信息
enum class Area {
	Illegal = -1,//初始化默认值
	AREA_E = 1, AREA_W = 2, AREA_S = 3, AREA_N = 4
};//图书区信息：东/西/南/北区
enum  class ErrorCode {
	SUCCESS = 0,//成功
	//用户相关错误
	WRONG_USERNAME = 1000,//用户名不存在
	WRONG_PASSWORD = 1001,//密码错误
	EXISTING_ACCOUNT = 1002,//账户已存在
	NO_ACCESS = 1004,//无权限
	INVALID = 1005,//不可用的账户
	EMPTY_USERNAME = 1006,//空用户名
	PASSWORD_TOO_SHORT = 1007,//密码过短
	//业务相关错误
	EMPTY_INPUT = 2002,//空输入
	ILLEGAL_INPUT = 2003,//非法输入：输入不合格式或赋值意图违反逻辑
	NO_RESULT = 2005,//未找到结果
	VOLUME_NOT_AVAILABLE = 2006,//单册不可获取
	VOLUME_OVERDUE = 2007,//存在单册逾期
	MAX_BORROW_LIMIT = 2008,//达到借阅上限
	//系统相关错误
	SYSTEM_ERROR = 3001,//意外的系统错误
	FAILED_SEARCH = 3006,//搜寻失败
	FAILED_TO_READ = 3007,//读入失败
	FAILED_TO_WRITE = 3008,//写出失败
	DATABASE_ERROR = 3009,//数据库错误
	DATA_ERROR = 3010,//数据错误（存在ID重复或非法等情况）
	//预留项
	OTHER_ERROR = 9999//其他（可能的）错误
};//错误代码
enum class Language {
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
};//出版文种
enum class Category {
	Illegal = -1,//初始化默认值
	Literature = 1,
	Philosophy = 2,
	Linguistics = 3,
	Art = 4,
	Technology = 5
};//图书分类
enum class Auth {
	Illegal = -1,
	Reader = 1,//读者
	Admin = 2//管理员
};//用户身份