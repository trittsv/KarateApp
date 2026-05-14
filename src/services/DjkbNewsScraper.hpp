// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QNetworkAccessManager>
#include <QObject>
#include <QString>

class DjkbNewsScraper : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool hasMore READ hasMore NOTIFY hasMoreChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorStringChanged)
    Q_PROPERTY(bool detailLoading READ detailLoading NOTIFY detailLoadingChanged)
    Q_PROPERTY(QString detailErrorString READ detailErrorString NOTIFY detailErrorStringChanged)

public:
    explicit DjkbNewsScraper(QObject *parent = nullptr);

    bool loading() const;
    bool hasMore() const;
    QString errorString() const;
    bool detailLoading() const;
    QString detailErrorString() const;

    Q_INVOKABLE void loadFirstPage();
    Q_INVOKABLE void loadSection(const QString &section);
    Q_INVOKABLE void loadMore();
    Q_INVOKABLE void loadDetail(const QString &url);

signals:
    void pageLoaded(const QString &newsJson);
    void detailLoaded(const QString &url, const QString &detailJson);
    void loadingChanged();
    void hasMoreChanged();
    void errorStringChanged();
    void detailLoadingChanged();
    void detailErrorStringChanged();

private:
    QNetworkAccessManager m_manager;
    QString m_section = QStringLiteral("news");
    QString m_nextToken;
    quint64 m_requestId = 0;
    bool m_loading = false;
    bool m_hasMore = true;
    QString m_errorString;
    bool m_detailLoading = false;
    QString m_detailErrorString;

    void fetchPage(quint64 requestId);
    void setLoading(bool loading);
    void setHasMore(bool hasMore);
    void setErrorString(const QString &errorString);
    void setDetailLoading(bool loading);
    void setDetailErrorString(const QString &errorString);
};
