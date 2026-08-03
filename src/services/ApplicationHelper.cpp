// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "ApplicationHelper.hpp"

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniObject>
#endif

#ifdef Q_OS_IOS
void requestNativeAppReview();
#endif

ApplicationHelper::ApplicationHelper(QObject *parent)
    : QObject(parent) {
}

void ApplicationHelper::moveToBackground() {
#ifdef Q_OS_ANDROID
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([] {
        const QJniObject activity =
            QNativeInterface::QAndroidApplication::context();

        if (activity.isValid())
            activity.callMethod<jboolean>("moveTaskToBack", jboolean(true));
    });
#endif
}

void ApplicationHelper::requestAppReview() {
#ifdef Q_OS_IOS
    requestNativeAppReview();
#endif
}
