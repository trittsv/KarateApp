// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include "utils/Logger.hpp"

#include <QDirIterator>
#include <QString>
#include <QStandardPaths>

#if defined(Q_OS_WIN)
#include <windows.h>
#else
#include <pthread.h>
#endif


QString getNativeStyle() {
    QString style = "Universal";
#if defined(Q_OS_ANDROID)
    style = "Material";
#elif defined(Q_OS_IOS)
    style = "iOS";
#elif defined(Q_OS_MACOS)
    style = "macOS";
#elif defined(Q_OS_LINUX)
    style = "Fusion";
#elif defined(Q_OS_WIN)
    style = "Windows";
#endif
    return style;
}

void showAllFilesInResource() {
    QDirIterator it(":", QDirIterator::Subdirectories);
    while (it.hasNext()) {
        LOG_DEBUG << it.next();
    }
}

void setThreadName(const std::string& name) {
#if defined(Q_OS_MAC)
    pthread_setname_np(name.c_str());
#elif defined(Q_OS_WIN)
    std::wstring wname = QString::fromStdString(name).toStdWString();
    SetThreadDescription(GetCurrentThread(), wname.c_str());
#else
    pthread_setname_np(pthread_self(), name.c_str());
#endif
}

void printDeviceInfo() {
    QSysInfo systemInfo;
    LOG_DEBUG << "Running Qt Version:" << qVersion();
    LOG_DEBUG << "Current Cpu Architecture: " << systemInfo.currentCpuArchitecture();
    LOG_DEBUG << "Kernel Type: " << systemInfo.kernelType();
    LOG_DEBUG << "Kernel Version: " << systemInfo.kernelVersion();
    LOG_DEBUG << "Product Type: " << systemInfo.productType();
    LOG_DEBUG << "Product Version: " << systemInfo.productVersion();
    LOG_DEBUG << "Pretty ProductName: " << systemInfo.prettyProductName();
}
