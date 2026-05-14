// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QNetworkAccessManager>
#include <QObject>
#include <QString>

class DjkbGalleryScraper : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool yearsLoading READ yearsLoading NOTIFY yearsLoadingChanged)
    Q_PROPERTY(bool albumsLoading READ albumsLoading NOTIFY albumsLoadingChanged)
    Q_PROPERTY(bool photosLoading READ photosLoading NOTIFY photosLoadingChanged)
    Q_PROPERTY(bool photosHasMore READ photosHasMore NOTIFY photosHasMoreChanged)
    Q_PROPERTY(QString yearsErrorString READ yearsErrorString NOTIFY yearsErrorStringChanged)
    Q_PROPERTY(QString albumsErrorString READ albumsErrorString NOTIFY albumsErrorStringChanged)
    Q_PROPERTY(QString photosErrorString READ photosErrorString NOTIFY photosErrorStringChanged)

public:
    explicit DjkbGalleryScraper(QObject *parent = nullptr);

    bool yearsLoading() const;
    bool albumsLoading() const;
    bool photosLoading() const;
    bool photosHasMore() const;
    QString yearsErrorString() const;
    QString albumsErrorString() const;
    QString photosErrorString() const;

    Q_INVOKABLE void loadYears();
    Q_INVOKABLE void loadAlbums(const QString &url);
    Q_INVOKABLE void loadFirstPhotoPage(const QString &url);
    Q_INVOKABLE void loadMorePhotos();

signals:
    void yearsLoaded(const QString &json);
    void albumsLoaded(const QString &json);
    void photosLoaded(const QString &json);
    void yearsLoadingChanged();
    void albumsLoadingChanged();
    void photosLoadingChanged();
    void photosHasMoreChanged();
    void yearsErrorStringChanged();
    void albumsErrorStringChanged();
    void photosErrorStringChanged();

private:
    QNetworkAccessManager m_manager;
    QString m_nextPhotoPageUrl;
    quint64 m_albumRequestId = 0;
    quint64 m_photoRequestId = 0;
    bool m_yearsLoading = false;
    bool m_albumsLoading = false;
    bool m_photosLoading = false;
    bool m_photosHasMore = false;
    QString m_yearsErrorString;
    QString m_albumsErrorString;
    QString m_photosErrorString;

    void fetchPhotos(const QString &url, quint64 requestId);
    void setYearsLoading(bool loading);
    void setAlbumsLoading(bool loading);
    void setPhotosLoading(bool loading);
    void setPhotosHasMore(bool hasMore);
    void setYearsErrorString(const QString &error);
    void setAlbumsErrorString(const QString &error);
    void setPhotosErrorString(const QString &error);
};
