// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "ClipboardHelper.hpp"
#include "utils/Logger.hpp"

#include <QApplication>
#include <QStyleHints>
#include <QDesktopServices>
#include <QUrl>


ClipboardHelper::ClipboardHelper(QObject *parent)
    : QObject(parent) {}

void ClipboardHelper::copyTextToClipboard(const QString &text)
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(text);
}

QString ClipboardHelper::loadFileContent(const QString &path) {
    QFile file(path);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream stream(&file);
        return stream.readAll();
    }

    LOG_WARN << "Try to open empty file:" << path;
    return QString();
}

void ClipboardHelper::setColorScheme(const int &scheme) {
    QApplication::styleHints()->setColorScheme(static_cast<Qt::ColorScheme>(scheme));
}

#ifndef Q_OS_IOS
void ClipboardHelper::shareUrl(const QString &url) {
    QDesktopServices::openUrl(QUrl(url));
}
#endif
