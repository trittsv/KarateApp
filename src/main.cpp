// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "version.h"
#include "utils/Logger.hpp"
#include "utils/Utils.hpp"

#include "services/ClipboardHelper.hpp"
#include "services/ApplicationHelper.hpp"
#include "services/BackendApiClient.hpp"
#include "services/DjkbGalleryScraper.hpp"
#include "services/DjkbNewsScraper.hpp"
#include "services/PdfDownloadManager.hpp"

#include "models/DojoModel.hpp"
#include "models/DojoSortProxyModel.hpp"
#include "models/GalleryModel.hpp"
#include "models/SeminarModel.hpp"
#include "models/SeminarSortProxyModel.hpp"
#include "models/LicenseListModel.hpp"
#include "models/NewsModel.hpp"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDirIterator>
#include <QQuickWindow>
#include <QtWebView>
#include <QFileDialog>
#include <QStandardPaths>
#include <QSettings>
#include <QSysInfo>
#include <QVariantMap>

#if defined(Q_OS_WIN)
#include <QtWebEngineQuick>
#endif

#include <QtCore/QCoreApplication>

int main(int argc, char *argv[]) {

    setThreadName("karateapp.main");

    setupLogger(defaultLogLevel());

    qputenv("QT_WEBVIEW_PLUGIN", QByteArray("native"));
#if defined(Q_OS_WIN)
    QtWebEngineQuick::initialize();
    // QtWebView::initialize(); // TODO: Check
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
#endif
#if defined(Q_OS_ANDROID)
    qputenv("QT_QUICK_CONTROLS_STYLE", QByteArray("Material"));
    qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", QByteArray("System"));
#endif

    LOG_INFO << "Starting KarateApp Version" << KARATEAPP_VERSION << "...";
    printDeviceInfo();

    QApplication app(argc, argv);
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QApplication::setOrganizationName("trittsv.app");
    QApplication::setApplicationName("karateapp");

    // showAllFilesInResource();

    const QString nativeStyle = getNativeStyle();
    LOG_INFO << "Using style " << nativeStyle;
    QQuickStyle::setStyle(nativeStyle);

    LOG_DEBUG << "Main is running in thread" << QThread::currentThread();


    ClipboardHelper clipboardHelper;
    ApplicationHelper applicationHelper;
    SeminarModel seminarModel;
    SeminarSortProxyModel seminarProxyModel;
    seminarProxyModel.setSourceModel(&seminarModel);
    seminarProxyModel.setSortByDistance(false);

    LicenseListModel licenseListModel;
    NewsModel newsModel;
    GalleryModel galleryYearsModel;
    GalleryModel galleryAlbumsModel;
    GalleryModel galleryPhotosModel;
    DojoModel dojoModel;
    DojoSortProxyModel dojoProxyModel;
    dojoProxyModel.setSourceModel(&dojoModel);
    BackendApiClient backendApiClient;
    PdfDownloadManager pdfDownloadManager;
    DjkbNewsScraper newsScraper;
    DjkbGalleryScraper galleryScraper;
    QObject::connect(&backendApiClient, &BackendApiClient::appointmentsLoaded,
                     &seminarModel,
                     [&seminarModel](const QString &appointments) {
        LOG_INFO << "Load appointments from backend ...";
        seminarModel.loadFromJson(appointments);
    });
    QObject::connect(&newsScraper, &DjkbNewsScraper::pageLoaded,
                     &newsModel, &NewsModel::appendFromJson);
    QObject::connect(&backendApiClient, &BackendApiClient::dojosLoaded,
                     &dojoModel, &DojoModel::loadFromJson);
    QObject::connect(&galleryScraper, &DjkbGalleryScraper::yearsLoaded,
                     &galleryYearsModel, &GalleryModel::appendFromJson);
    QObject::connect(&galleryScraper, &DjkbGalleryScraper::albumsLoaded,
                     &galleryAlbumsModel, &GalleryModel::appendFromJson);
    QObject::connect(&galleryScraper, &DjkbGalleryScraper::photosLoaded,
                     &galleryPhotosModel, &GalleryModel::appendFromJson);
    backendApiClient.loadAppointments();
    newsScraper.loadFirstPage();

    QQmlApplicationEngine engine;
    const QVariantMap systemInfo {
        { "currentCpuArchitecture", QSysInfo::currentCpuArchitecture() },
        { "kernelType", QSysInfo::kernelType() },
        { "kernelVersion", QSysInfo::kernelVersion() },
        { "prettyProductName", QSysInfo::prettyProductName() },
        { "productType", QSysInfo::productType() },
        { "productVersion", QSysInfo::productVersion() }
    };

    engine.rootContext()->setContextProperty("THUNDERFOREST_API_KEY", KARATEAPP_THUNDERFOREST_API_KEY);
    engine.rootContext()->setContextProperty("KARATEAPP_VERSION", KARATEAPP_VERSION);
    engine.rootContext()->setContextProperty("KARATEAPP_BUILD_DATE", KARATEAPP_BUILD_DATE);
    engine.rootContext()->setContextProperty("KARATEAPP_GIT_COMMIT", KARATEAPP_GIT_COMMIT);
    engine.rootContext()->setContextProperty("KARATEAPP_APP_STORE_ID", KARATEAPP_APP_STORE_ID);
    engine.rootContext()->setContextProperty("KARATEAPP_GOOGLE_PLAY_APP_ID", KARATEAPP_GOOGLE_PLAY_APP_ID);
    engine.rootContext()->setContextProperty("KARATEAPP_QT_VERSION", QString::fromLatin1(qVersion()));
    engine.rootContext()->setContextProperty("KARATEAPP_SYSTEM_INFO", systemInfo);
    engine.rootContext()->setContextProperty("seminarModel", &seminarModel);
    engine.rootContext()->setContextProperty("seminarProxyModel", &seminarProxyModel);
    engine.rootContext()->setContextProperty("licenseListModel", &licenseListModel);
    engine.rootContext()->setContextProperty("newsModel", &newsModel);
    engine.rootContext()->setContextProperty("galleryYearsModel", &galleryYearsModel);
    engine.rootContext()->setContextProperty("galleryAlbumsModel", &galleryAlbumsModel);
    engine.rootContext()->setContextProperty("galleryPhotosModel", &galleryPhotosModel);
    engine.rootContext()->setContextProperty("dojoModel", &dojoModel);
    engine.rootContext()->setContextProperty("dojoProxyModel", &dojoProxyModel);
    engine.rootContext()->setContextProperty("backendApiClient", &backendApiClient);
    engine.rootContext()->setContextProperty("djkbNewsScraper", &newsScraper);
    engine.rootContext()->setContextProperty("djkbGalleryScraper", &galleryScraper);
    engine.rootContext()->setContextProperty("ClipboardHelper", &clipboardHelper);
    engine.rootContext()->setContextProperty("ApplicationHelper", &applicationHelper);
    engine.rootContext()->setContextProperty("PdfDownloadManager", &pdfDownloadManager);

    engine.addImportPath("qrc:/KarateApp");

    const QUrl url(QStringLiteral("qrc:/KarateApp/src/views/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
            }
        }, Qt::QueuedConnection);

    LOG_INFO << "Load qml ...";
    engine.load(url);

    LOG_INFO << "Enter main loop ..";
    return app.exec();
}
