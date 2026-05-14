// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "PdfDownloadManager.hpp"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QPdfDocument>
#include <QSaveFile>
#include <QStandardPaths>
#include <QDateTime>

namespace {
constexpr qint64 MinimumPdfSize = 8;
constexpr qint64 MaximumPdfSize = 100 * 1024 * 1024;
}

PdfDownloadManager::PdfDownloadManager(QObject* parent)
    : QObject(parent) {
    cleanupOldFiles();
}

QString PdfDownloadManager::cacheDirPath() const {
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/pdf";
}

QString PdfDownloadManager::filePathForUrl(const QUrl& url) const {
    const QByteArray hash = QCryptographicHash::hash(
        url.toString().toUtf8(),
        QCryptographicHash::Sha256
    ).toHex();

    return cacheDirPath() + "/" + QString::fromLatin1(hash) + ".pdf";
}

void PdfDownloadManager::download(const QUrl& url) {
    if (!url.isValid() || url.scheme().isEmpty()) {
        emit downloadFailed("Ungültige PDF-Adresse.");
        return;
    }

    QDir().mkpath(cacheDirPath());

    const QString localPath = filePathForUrl(url);

    if (QFileInfo::exists(localPath)) {
        QString validationError;
        if (validatePdfFile(localPath, &validationError)) {
            emit downloadFinished(QUrl::fromLocalFile(localPath));
            return;
        }

        QFile::remove(localPath);
    }

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply* reply = m_network.get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, localPath]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit downloadFailed(reply->errorString());
            return;
        }

        const int statusCode =
            reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (statusCode < 200 || statusCode >= 300) {
            emit downloadFailed(
                QString("PDF-Download fehlgeschlagen (HTTP %1).").arg(statusCode)
            );
            return;
        }

        const QByteArray data = reply->readAll();
        if (data.size() < MinimumPdfSize || data.size() > MaximumPdfSize) {
            emit downloadFailed("Die PDF-Datei hat eine ungültige Größe.");
            return;
        }

        const qsizetype pdfHeader = data.indexOf("%PDF-");
        if (pdfHeader < 0 || pdfHeader > 1024) {
            emit downloadFailed("Die heruntergeladene Datei ist keine gültige PDF-Datei.");
            return;
        }

        QSaveFile file(localPath);
        if (!file.open(QIODevice::WriteOnly)) {
            emit downloadFailed("Could not write PDF cache file.");
            return;
        }

        if (file.write(data) != data.size() || !file.commit()) {
            emit downloadFailed("Die PDF-Datei konnte nicht vollständig gespeichert werden.");
            return;
        }

        QString validationError;
        if (!validatePdfFile(localPath, &validationError)) {
            QFile::remove(localPath);
            emit downloadFailed(validationError);
            return;
        }

        emit downloadFinished(QUrl::fromLocalFile(localPath));
    });
}

bool PdfDownloadManager::validatePdfFile(const QString& path, QString* error) const {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        if (error)
            *error = "Die PDF-Datei konnte nicht geöffnet werden.";
        return false;
    }

    if (file.size() < MinimumPdfSize || file.size() > MaximumPdfSize) {
        if (error)
            *error = "Die PDF-Datei hat eine ungültige Größe.";
        return false;
    }

    const QByteArray header = file.read(1024);
    if (!header.contains("%PDF-")) {
        if (error)
            *error = "Die Datei enthält kein gültiges PDF.";
        return false;
    }

#ifdef Q_OS_IOS
    // Bug in Qt PDF rendering on iOS
    const QByteArray bytes = file.readAll();
    if (bytes.contains("/ICCBased")) {
        if (error)
            *error = "PDF contains ICCBased colorspace";
        return false;
    }
#endif

    file.close();

    QPdfDocument document;
    const QPdfDocument::Error pdfError = document.load(path);
    if (pdfError != QPdfDocument::Error::None || document.pageCount() <= 0) {
        if (error) {
            *error = pdfError == QPdfDocument::Error::IncorrectPassword
                         ? "Die PDF-Datei ist passwortgeschützt."
                         : "Die PDF-Datei konnte nicht gelesen werden.";
        }
        return false;
    }

    return true;
}

void PdfDownloadManager::cleanupOldFiles() {
    QDir dir(cacheDirPath());

    if (!dir.exists())
        return;

    const auto files = dir.entryInfoList(QStringList() << "*.pdf", QDir::Files);
    const QDateTime cutoff = QDateTime::currentDateTime().addDays(-3);

    for (const QFileInfo& file : files) {
        if (file.lastModified() < cutoff)
            QFile::remove(file.absoluteFilePath());
    }
}
