// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include "StreamingOperators.hpp"

#include <atomic>
#include <string>
#include <sstream>
#include <iostream>

#include <QMutexLocker>
#include <QMutex>
#include <QDateTime>
#include <QFileInfo>
#include <QString>

#if defined(Q_OS_ANDROID)
#include <android/log.h>
#endif

enum class LogLevel {
    Critical = 0,
    Error = 1,
    Warning = 2,
    Info = 3,
    Debug = 4,
    Trace = 5,
    All = 100
};

inline int toLogLevelValue(LogLevel level) {
    return static_cast<int>(level);
}

inline std::atomic<int> configuredLogLevel {
    toLogLevelValue(LogLevel::Warning)
};

class LogStream {

public:
    LogStream(int level, const QString& file, const QString& function, const int& line)
        : m_level(level)
        , m_file(std::move(file))
        , m_function(std::move(function))
        , m_line(line) {}

    ~LogStream() {
        if (m_level > configuredLogLevel.load(std::memory_order_relaxed))
            return;

        const std::string fileName = m_file.startsWith("qrc:")
            ? m_file.toStdString()
            : QFileInfo(m_file).fileName().toStdString();
        const std::string timestamp = QDateTime::currentDateTime()
            .toString("yyyy-MM-dd HH:mm:ss.zzz")
            .toStdString();

        std::ostringstream logMessage;
        logMessage << "[" << timestamp << "] "
                   << "(" << logLevelName(m_level) << ") "
                   << "[" << fileName << ":" << m_line << "] "
                   << "[" << m_function << "] "
                   << m_stream.str();

#if defined(Q_OS_ANDROID)
        __android_log_print(
            androidPriority(m_level),
            "KarateApp",
            "%s",
            logMessage.str().c_str()
            );
#else
        std::cout << logMessage.str() << std::endl;
#endif
    }

    template <typename T>
    LogStream& operator<<(const T& value) {
        m_stream << value;
        return *this;
    }

    std::string logLevelName(int level) {
        if (level == 0) {
            return "Critical";
        } else if (level == 1) {
            return "Error";
        } else if (level == 2) {
            return "Warning";
        } else if (level == 3) {
            return "Info";
        } else if (level == 4) {
            return "Debug";
        } else if (level == 5) {
            return "Trace";
        } else {
            return "Unknown";
        }
    }

#if defined(Q_OS_ANDROID)
    static int androidPriority(int level) {
        switch (level) {
        case 0: return ANDROID_LOG_FATAL;
        case 1: return ANDROID_LOG_ERROR;
        case 2: return ANDROID_LOG_WARN;
        case 3: return ANDROID_LOG_INFO;
        case 4: return ANDROID_LOG_DEBUG;
        case 5: return ANDROID_LOG_VERBOSE;
        default: return ANDROID_LOG_UNKNOWN;
        }
    }
#endif

private:
    int m_level;
    std::ostringstream m_stream;
    QString m_file;
    QString m_function;
    int m_line;
};


inline void qtlogMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    static QMutex mutex;
    QMutexLocker lock(&mutex);
    switch (type) {
    case QtDebugMsg:
        LogStream(4, context.file, context.function, context.line) << msg;
        break;
    case QtInfoMsg:
        LogStream(3, context.file, context.function, context.line) << msg;
        break;
    case QtWarningMsg:
        LogStream(2, context.file, context.function, context.line) << msg;
        break;
    case QtCriticalMsg:
        LogStream(1, context.file, context.function, context.line) << msg;
        break;
    case QtFatalMsg:
        LogStream(0, context.file, context.function, context.line) << msg;
    }
}

inline void setupLogger(LogLevel level) {
    configuredLogLevel.store(
        toLogLevelValue(level),
        std::memory_order_relaxed
    );
    qInstallMessageHandler(qtlogMessageHandler);
}

inline LogLevel defaultLogLevel() {
#if defined(KARATEAPP_DEBUG_LOGGING)
    const LogLevel buildDefault = LogLevel::Debug;
#else
    const LogLevel buildDefault = LogLevel::Warning;
#endif

    const QString configuredLevel = qEnvironmentVariable("KARATEAPP_LOG_LEVEL")
        .trimmed()
        .toLower();

    if (configuredLevel == "critical")
        return LogLevel::Critical;
    if (configuredLevel == "error")
        return LogLevel::Error;
    if (configuredLevel == "warning" || configuredLevel == "warn")
        return LogLevel::Warning;
    if (configuredLevel == "info")
        return LogLevel::Info;
    if (configuredLevel == "debug")
        return LogLevel::Debug;
    if (configuredLevel == "trace")
        return LogLevel::Trace;
    if (configuredLevel == "all")
        return LogLevel::All;

    return buildDefault;
}

inline void setupLogger(int level) {
    setupLogger(static_cast<LogLevel>(level));
}


#define LOG_TRACE LogStream(toLogLevelValue(LogLevel::Trace), QString::fromStdString(__FILE__), QString::fromStdString(__FUNCTION__), __LINE__)
#define LOG_DEBUG LogStream(toLogLevelValue(LogLevel::Debug), QString::fromStdString(__FILE__), QString::fromStdString(__FUNCTION__), __LINE__)
#define LOG_INFO LogStream(toLogLevelValue(LogLevel::Info), QString::fromStdString(__FILE__), QString::fromStdString(__FUNCTION__), __LINE__)
#define LOG_WARN LogStream(toLogLevelValue(LogLevel::Warning), QString::fromStdString(__FILE__), QString::fromStdString(__FUNCTION__), __LINE__)
#define LOG_ERROR LogStream(toLogLevelValue(LogLevel::Error), QString::fromStdString(__FILE__), QString::fromStdString(__FUNCTION__), __LINE__)
#define LOG_CRITICAL LogStream(toLogLevelValue(LogLevel::Critical), QString::fromStdString(__FILE__), QString::fromStdString(__FUNCTION__), __LINE__)
