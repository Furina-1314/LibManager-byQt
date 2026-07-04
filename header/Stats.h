#pragma once
// 基础类型与 Qt 容器头文件
#include <QList>
#include <QPair>

// 业务实体与类型定义头文件
#include "header/TypeCode.h"
#include "header/DataTemplates.h"

/**
 * @class Stats
 * @brief 统计服务类 (OLAP Analytical Service)
 *
 * 封装底层的借阅流水聚合查询，向上层 UI 提供多维度的统计与排行视图。
 * 所有接口均为无状态的静态方法（Static Methods）。
 */
class Stats {
public:

    /**
     * @brief 获取前 20 名热门书籍详细榜单
     * @param topList [out] 用于装载 (图书实体, 借阅次数) 键值对的传出列表
     * @return ErrorCode 执行状态码
     */
    [[nodiscard]] static ErrorCode getTop20Books(QList<QPair<Book, int>>& topList);

    /**
     * @brief 获取前 20 名借阅达人详细榜单
     * @param topList [out] 用于装载 (读者实体, 借阅次数) 键值对的传出列表
     * @return ErrorCode 执行状态码
     */
    [[nodiscard]] static ErrorCode getTop20Readers(QList<QPair<ReaderAccount, int>>& topList);

    /**
     * @brief 按月获取读者借阅流水明细
     * @param in 包含目标读者 ID 的装配实体
     * @param year 目标年份
     * @param month 目标月份 (1-12)
     * @param results [out] 命中区间内的借阅流水明细集合
     * @return ErrorCode 执行状态码
     */
    [[nodiscard]] static ErrorCode getReaderHistorybyMonth(const ReaderAccount& in, const int year, const int month, QList<LoanRecord>& results);

    /**
     * @brief 按年获取读者借阅流水明细
     * @param in 包含目标读者 ID 的装配实体
     * @param year 目标年份
     * @param results [out] 命中区间内的借阅流水明细集合
     * @return ErrorCode 执行状态码
     */
    [[nodiscard]] static ErrorCode getReaderHistorybyYear(const ReaderAccount& in, const int year, QList<LoanRecord>& results);

    /**
     * @brief 按月统计读者借阅总数
     * @param in 包含目标读者 ID 的装配实体
     * @param year 目标年份
     * @param month 目标月份 (1-12)
     * @param result [out] 聚合运算后输出的借阅总数
     * @return ErrorCode 执行状态码
     */
    [[nodiscard]] static ErrorCode getReaderCountbyMonth(const ReaderAccount& in, const int year, const int month, int& result);

    /**
     * @brief 按年统计读者借阅总数
     * @param in 包含目标读者 ID 的装配实体
     * @param year 目标年份
     * @param result [out] 聚合运算后输出的借阅总数
     * @return ErrorCode 执行状态码
     */
    [[nodiscard]] static ErrorCode getReaderCountbyYear(const ReaderAccount& in, const int year, int& result);

    /**
     * @brief 统计读者未归还单册数 (基于全局时间极值跨度)
     * @param in 包含目标读者 ID 的装配实体
     * @param result [out] 未归还的单册总数
     * @return ErrorCode 执行状态码
     */
    [[nodiscard]] static ErrorCode getReaderCountbyNotReturned(const ReaderAccount& in, int& result);

    /**
     * @brief 统计读者当前违约 (逾期且未还) 的单册数
     * @param in 包含目标读者 ID 的装配实体
     * @param result [out] 逾期未还的单册总数
     * @return ErrorCode 执行状态码
     */
    [[nodiscard]] static ErrorCode getReaderCountbyOverdue(const ReaderAccount& in, int& result);

};