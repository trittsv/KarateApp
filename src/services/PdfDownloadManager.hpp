// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrl>

class PdfDownloadManager : public QObject {
    Q_OBJECT

public:
    explicit PdfDownloadManager(QObject* parent = nullptr);

    Q_INVOKABLE void download(const QUrl& url);
    Q_INVOKABLE void cleanupOldFiles();

signals:
    void downloadFinished(QUrl localFileUrl);
    void downloadFailed(QString error);

private:
    QNetworkAccessManager m_network;
    QString cacheDirPath() const;
    QString filePathForUrl(const QUrl& url) const;
    bool validatePdfFile(const QString& path, QString* error) const;
};
