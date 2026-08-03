# Copyright (c) 2026 Sven Trittler and contributors
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.16)

set(QT_CREATOR_SKIP_CONAN_SETUP ON)

project(KarateApp VERSION 1.2.0 LANGUAGES CXX)
set(KARATEAPP_ANDROID_VERSION_CODE 7) # Increment for each version
set(KARATEAPP_ANDROID_VERSION_NAME "${CMAKE_PROJECT_VERSION}")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})
list(APPEND CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

message(STATUS "Cross-compiling? ${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR} on host: ${CMAKE_HOST_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")

# ------------------------
# ----- Dependencies -----
# ------------------------

# Qt replace with qt_LIB_DIRS (and find_package(qt REQURIED))
if(WIN32)
    set(PLATFORM_SPECIFIC_QT_COMPONENTS WebEngineQuick)
endif()

find_package(Qt6 6.11.1
    COMPONENTS
        Quick QuickControls2 WebView Widgets ${PLATFORM_SPECIFIC_QT_COMPONENTS} Positioning Location Pdf PdfQuick
    REQUIRED
)
message(STATUS "Found Qt6 version: ${Qt6_VERSION}")
qt_standard_project_setup()
qt_policy(SET QTP0002 NEW)

execute_process(
    COMMAND git rev-parse --short=10 HEAD
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE KARATEAPP_GIT_COMMIT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)

if(NOT KARATEAPP_GIT_COMMIT)
    set(KARATEAPP_GIT_COMMIT "unknown")
endif()

string(TIMESTAMP KARATEAPP_BUILD_DATE "%Y-%m-%d %H:%M UTC" UTC)

set(KARATEAPP_THUNDERFOREST_API_KEY "$ENV{THUNDERFOREST_API_KEY}")
if(NOT KARATEAPP_THUNDERFOREST_API_KEY)
    message(WARNING "THUNDERFOREST_API_KEY is not set. Map tiles may not load.")
endif()

set(KARATEAPP_APP_STORE_ID "$ENV{APP_STORE_ID}")
if(NOT KARATEAPP_APP_STORE_ID)
    message(FATAL_ERROR "APP_STORE_ID is not set. Set it to the numeric Apple App Store ID.")
endif()

set(KARATEAPP_GOOGLE_PLAY_APP_ID "$ENV{GOOGLE_PLAY_APP_ID}")
if(NOT KARATEAPP_GOOGLE_PLAY_APP_ID)
    message(FATAL_ERROR "GOOGLE_PLAY_APP_ID is not set. Set it to the Android application ID.")
endif()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/res/version.h.in ${CMAKE_BINARY_DIR}/version.h)

set(SOURCES
    src/main.cpp
    src/services/DjkbNewsScraper.hpp
    src/services/DjkbNewsScraper.cpp
    src/services/DjkbGalleryScraper.hpp
    src/services/DjkbGalleryScraper.cpp
    src/services/BackendConfig.hpp
    src/services/BackendApiClient.hpp
    src/services/BackendApiClient.cpp
    src/models/SeminarModel.hpp
    src/models/SeminarModel.cpp
    src/models/SeminarSortProxyModel.hpp
    src/models/SeminarSortProxyModel.cpp
    src/models/NewsModel.hpp
    src/models/NewsModel.cpp
    src/models/GalleryModel.hpp
    src/models/GalleryModel.cpp
    src/models/DojoModel.hpp
    src/models/DojoModel.cpp
    src/models/DojoSortProxyModel.hpp
    src/models/DojoSortProxyModel.cpp
    src/models/LicenseListModel.hpp
    src/models/LicenseListModel.cpp
    src/services/ClipboardHelper.hpp
    src/services/ClipboardHelper.cpp
    src/services/ApplicationHelper.hpp
    src/services/ApplicationHelper.cpp
    src/services/PdfDownloadManager.hpp
    src/services/PdfDownloadManager.cpp
)

# Obj-C vs C++ code
if(APPLE)
    # All Apple Platform
    list(APPEND SOURCES

    )
    # iOS specific
    if(IOS)
        list(APPEND SOURCES
            src/services/ClipboardHelper.mm
            src/services/ApplicationHelper.mm
        )
    # Non-iOS but Apple
    else()
        list(APPEND SOURCES

        )
        if (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
           set(MACOSX_BUNDLE_ICON_FILE karateapp.icns)
           set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/res/icons/KarateApp.icns")
           set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
           list(APPEND SOURCES ${app_icon_macos})
        endif()
    endif()
else()
    list(APPEND SOURCES

    )
endif()
message(STATUS "CMAKE_SYSTEM_NAME: ${CMAKE_SYSTEM_NAME}")
message(STATUS "Source files: ${SOURCES}")

qt_add_executable(KarateApp ${SOURCES})

target_compile_definitions(KarateApp PRIVATE
    $<$<CONFIG:Debug>:KARATEAPP_DEBUG_LOGGING>
)

set_source_files_properties(src/views/Constants.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
qt_add_resources(KarateApp "KarateApp"
    PREFIX "/KarateApp"
    FILES
        # Qml
        src/views/main.qml
        src/views/MainContentViewMobile.qml
        src/views/MainContentViewDesktop.qml
        src/views/Constants.qml
        src/views/AppToolBar.qml
        src/views/AppBusyIndicator.qml
        src/views/SourceAttribution.qml
        src/views/qmldir
        src/views/seminars/SeminarView.qml
        src/views/seminars/SeminarToolbar.qml
        src/views/seminars/SeminarMap.qml
        src/views/seminars/SeminarMapCard.qml
        src/views/seminars/SeminarMarker.qml
        src/views/seminars/SeminarList.qml
        src/views/seminars/SeminarDetailView.qml
        src/views/about/LegalView.qml
        src/views/about/AppInfoView.qml
        src/views/about/SettingsView.qml
        src/views/about/LicenceView.qml
        src/views/seminars/SeminarPdfView.qml
        src/views/news/NewsView.qml
        src/views/news/NewsDetailView.qml
        src/views/dojos/DojoView.qml
        src/views/dojos/DojoDetailView.qml
        src/views/dojos/DojoMap.qml
        src/views/dojos/DojoMarker.qml
        src/views/dojos/DojoMapCard.qml
        src/views/more/MoreView.qml
        src/views/gallery/GalleryYearsView.qml
        src/views/gallery/GalleryAlbumsView.qml
        src/views/gallery/GalleryPhotosView.qml
        src/views/utils/NavigationController.qml

        # Icons
        res/icons/calendar.svg
        res/icons/info.svg
        res/icons/news.svg
        res/icons/dojo.svg
        res/icons/more.svg
        res/icons/gallery.svg
        res/icons/feedback.svg
        res/icons/rating.svg
        res/apple/iOS/iPhone_180.png

        # Json
        ThirdpartyLicenses.json
)

set(PLIST_PATH "${CMAKE_CURRENT_SOURCE_DIR}/res/apple/Info.ios.plist.in")
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    message(STATUS "macOS Build")
    set(PLIST_PATH "${CMAKE_CURRENT_SOURCE_DIR}/res/apple/Info.macos.plist.in")
    find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
    list(APPEND PLATFORM_LINK_LIBS
        "${COCOA_FRAMEWORK}"
    )
elseif(ANDROID)
    set(QT_ANDROID_SIGN_APK ON) # make sure the env variables are set!

    # Add Android-Qt OpenSSL Support
    # https://doc.qt.io/qt-6/android-openssl-support.html#using-openssl-libraries-with-qt-for-android
    include(FetchContent)
    FetchContent_Declare(
      android_openssl
      DOWNLOAD_EXTRACT_TIMESTAMP true
      URL      https://github.com/KDAB/android_openssl/archive/b71f1470962019bd89534a2919f5925f93bc5779.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(KarateApp)

    # Setup Android Project
    set_property(TARGET KarateApp APPEND PROPERTY
        QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/res/android
    )
    set_property(TARGET KarateApp PROPERTY
        QT_ANDROID_PACKAGE_NAME ${KARATEAPP_GOOGLE_PLAY_APP_ID}
    )
endif()

set_target_properties(KarateApp PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER trittsv.app.karateapp
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE_INFO_PLIST ${PLIST_PATH}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    QT_IOS_LAUNCH_SCREEN "${CMAKE_CURRENT_SOURCE_DIR}/res/apple/LaunchScreen.storyboard"
    XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Release] "dwarf-with-dsym"
    XCODE_ATTRIBUTE_GCC_GENERATE_DEBUGGING_SYMBOLS[variant=Release] "YES"
    XCODE_ATTRIBUTE_DEPLOYMENT_POSTPROCESSING[variant=Release] "YES"
    XCODE_ATTRIBUTE_STRIP_INSTALLED_PRODUCT[variant=Release] "YES"
    XCODE_ATTRIBUTE_CONFIGURATION_BUILD_DIR "$(inherited)"
)

# Add platform specific target link lib
if(ANDROID)
    list(APPEND PLATFORM_LINK_LIBS
        ${log-lib}
    )
elseif(APPLE)
    if(IOS)
        find_library(STOREKIT_FRAMEWORK StoreKit REQUIRED)
        list(APPEND PLATFORM_LINK_LIBS
            "${STOREKIT_FRAMEWORK}"
        )
    endif()
    list(APPEND PLATFORM_LINK_LIBS
    )
elseif(WIN32)
    list(APPEND PLATFORM_LINK_LIBS
        Qt6::WebEngineQuick
    )
endif()


message(STATUS "Add Platform specific link libs: ${PLATFORM_LINK_LIBS}")

target_link_libraries(KarateApp
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Network
        Qt6::WebView
        Qt6::Widgets
        Qt6::Location
        Qt6::Positioning
        Qt6::Pdf
        Qt6::PdfQuick
        ${PLATFORM_LINK_LIBS}
)

target_include_directories(KarateApp PRIVATE ${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Set the iOS App Icon
if(IOS)
    set(THE_IOS_XCASSET_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}/res/apple")
    set(IOS_ASSET_CATALOGS
        "${THE_IOS_XCASSET_FOLDER}/MyAppIcons.xcassets"
        "${THE_IOS_XCASSET_FOLDER}/LaunchAssets.xcassets"
    )
    target_sources(KarateApp PRIVATE ${IOS_ASSET_CATALOGS})
    set_source_files_properties(${IOS_ASSET_CATALOGS} PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources
    )

    # Asset catalog app icon set
    list(APPEND app_icon_set "${THE_IOS_XCASSET_FOLDER}/MyAppIcons.xcassets/AppIcon.appiconset")
    list(APPEND app_icon_set "${THE_IOS_XCASSET_FOLDER}/MyAppIcons.xcassets/Contents.json")
    set_source_files_properties(${app_icon_set} PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources/MyAppIcons.xcassets
    )

    # Asset catalog icon files
    file(GLOB app_icon_files CONFIGURE_DEPENDS "${THE_IOS_XCASSET_FOLDER}/MyAppIcons.xcassets/AppIcon.appiconset/*.png")
    list(APPEND app_icon_files "${THE_IOS_XCASSET_FOLDER}/MyAppIcons.xcassets/AppIcon.appiconset/Contents.json")
    set_source_files_properties(${app_icon_set} PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources/MyAppIcons.xcassets/AppIcon.appiconset
    )

    macro(qt_ios_set_xcode_property TARGET XCODE_PROPERTY XCODE_VALUE XCODE_RELVERSION)
      set(XCODE_RELVERSION_I "${XCODE_RELVERSION}")
      if(XCODE_RELVERSION_I STREQUAL "All")
        set_property(TARGET ${TARGET} PROPERTY XCODE_ATTRIBUTE_${XCODE_PROPERTY} "${XCODE_VALUE}")
      else()
        set_property(TARGET ${TARGET} PROPERTY XCODE_ATTRIBUTE_${XCODE_PROPERTY}[variant=${XCODE_RELVERSION_I}] "${XCODE_VALUE}")
      endif()
    endmacro() # qt_ios_set_xcode_property

    # Now call it on your target for the app icon property.
    qt_ios_set_xcode_property (KarateApp ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon" "All")

    # Development Team
    set(IOS_DEVELOPMENT_TEAM "YL484LJV4J" CACHE STRING "iOS development team ID")
    set_property(GLOBAL PROPERTY XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${IOS_DEVELOPMENT_TEAM})
endif()
if(ANDROID)
    set_property(TARGET KarateApp PROPERTY QT_ANDROID_VERSION_CODE ${KARATEAPP_ANDROID_VERSION_CODE})
    set_property(TARGET KarateApp PROPERTY QT_ANDROID_VERSION_NAME ${KARATEAPP_ANDROID_VERSION_NAME})
endif()

if(APPLE)
    qt_import_plugins(KarateApp
        INCLUDE Qt6::QDarwinLocationPermissionPlugin
    )
endif()

# ------------------------
# ----- Installation -----
# ------------------------
include(GNUInstallDirs)
install(TARGETS KarateApp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
qt_generate_deploy_app_script(
    TARGET KarateApp
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_TOOL_OPTIONS
        -qmldir=${CMAKE_CURRENT_SOURCE_DIR}/src/views
)
install(SCRIPT ${deploy_script})


# ------------------------
# -------- CPack ---------
# ------------------------

string(TOLOWER "${CMAKE_SYSTEM_NAME}" CPACK_SYSTEM_NAME)

if(CMAKE_OSX_ARCHITECTURES)
    string(REPLACE ";" "-" CPACK_ARCH_NAME "${CMAKE_OSX_ARCHITECTURES}")
elseif(CMAKE_SYSTEM_PROCESSOR)
    set(CPACK_ARCH_NAME "${CMAKE_SYSTEM_PROCESSOR}")
else()
    set(CPACK_ARCH_NAME "unknown")
endif()

set(CPACK_PACKAGE_NAME "KarateApp")
set(CPACK_PACKAGE_VENDOR "Sven Trittler")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_FILE_NAME
    "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_SYSTEM_NAME}-${CPACK_ARCH_NAME}"
)
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}/package")

if(APPLE)
    set(CPACK_GENERATOR "ZIP")
elseif(WIN32)
    set(CPACK_GENERATOR "ZIP")
elseif(ANDROID)
    set(CPACK_GENERATOR "ZIP")
else()
    set(CPACK_GENERATOR "TGZ")
endif()

include(CPack)
