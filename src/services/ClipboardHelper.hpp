// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>
#include <QFile>
#include <QCryptographicHash>


class ClipboardHelper : public QObject {

    Q_OBJECT

public:
    ClipboardHelper(QObject *parent = nullptr);

    Q_INVOKABLE void copyTextToClipboard(const QString &text);

    Q_INVOKABLE QString loadFileContent(const QString &path);

    Q_INVOKABLE void setColorScheme(const int &scheme);

    Q_INVOKABLE QString hashStringSha256(const QString &input) {
        return QCryptographicHash::hash(
                   input.toUtf8(),
                   QCryptographicHash::Sha256
                   ).toHex();
    }

    Q_INVOKABLE void shareUrl(const QString &url);
};
