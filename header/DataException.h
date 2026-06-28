#pragma once
#include <exception>
#include <QString>
#include <QByteArray>
#include <QSqlError>
#include "TypeCode.h"

class DatabaseException : public std::exception {
public:
    // 构造函数，强制要求传入 ErrorCode，绑定业务语义与底层错误
    explicit DatabaseException(ErrorCode code, const QString& message, const QSqlError& error = QSqlError())
        : m_code(code),
        m_qMessage(message)
    {
        if (error.isValid()) {
            m_qMessage += " | 追踪: " + error.text();
        }
        // 核心防御机制：在对象构造时，预先将 QString 转为 QByteArray 并存储
        // 保证底层 char 数组与 Exception 对象拥有相同的生命周期
        m_byteMessage = m_qMessage.toUtf8();
    }

    // C++
    const char* what() const noexcept override {
        return m_byteMessage.constData(); // 安全：指针指向生命周期受控的 m_byteMessage
    }

    // 扩展接口：为 Qt 内部日志系统或 UI 提供原生 QString 支持
    QString qWhat() const {
        return m_qMessage;
    }

    // 扩展接口：为控制器的 return 提供强类型的 ErrorCode
    ErrorCode code() const {
        return m_code;
    }

private:
    ErrorCode m_code;
    QString m_qMessage;
    QByteArray m_byteMessage; // 锚点变量，防止 C 风格指针悬挂
}; 