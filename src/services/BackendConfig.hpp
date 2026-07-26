// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QNetworkRequest>
#include <QString>

namespace BackendConfig {
inline const QString BaseUrl = QStringLiteral("https://karate-api.ddns.net");
//inline const QString BaseUrl = QStringLiteral("http://192.168.178.22:5042");
inline constexpr int TimeoutMs = 60000;

inline QString platformName() {
#if defined(Q_OS_ANDROID)
    return QStringLiteral("android");
#elif defined(Q_OS_IOS)
    return QStringLiteral("ios");
#elif defined(Q_OS_MACOS)
    return QStringLiteral("macos");
#elif defined(Q_OS_WINDOWS)
    return QStringLiteral("windows");
#elif defined(Q_OS_LINUX)
    return QStringLiteral("linux");
#else
    return QStringLiteral("unknown");
#endif
}

inline void applyDefaultHeaders(QNetworkRequest &request) {
    request.setTransferTimeout(TimeoutMs);
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("X-KarateApp-Platform", platformName().toUtf8());
    request.setHeader(
        QNetworkRequest::UserAgentHeader,
        QStringLiteral("KarateApp/1.0 (%1)").arg(platformName())
    );
}
}
