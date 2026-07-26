pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Pdf

import ".."

Page {
    id: pdfView

    required property string pdfUrl
    required property var mainContentStackView

    property string titleText: "Ausschreibung"
    property url localPdfUrl: ""
    property string loadingDots: "."
    property bool pdfReady: false
    property bool useWebView: Qt.platform.os === "ios"
    property string errorMessage: ""

    Component.onCompleted: {
        if (useWebView)
            createIosWebView()
        else
            startDownload()
    }

    function startDownload() {
        if (useWebView)
            return

        errorMessage = ""
        pdfReady = false
        localPdfUrl = ""
        PdfDownloadManager.download(pdfUrl)
        loadingTimer.restart()
    }

    Connections {
        target: PdfDownloadManager

        function onDownloadFinished(localFileUrl) {
            console.log("Downloaded PDF:", localFileUrl)
            pdfView.localPdfUrl = localFileUrl
        }

        function onDownloadFailed(error) {
            console.error("PDF download failed:", error)
            loadingTimer.stop()
            pdfView.errorMessage = error
        }
    }

    Timer {
        id: loadingTimer
        interval: 450
        repeat: true

        onTriggered: {
            if (loadingDots === ".")
                loadingDots = ".."
            else if (loadingDots === "..")
                loadingDots = "..."
            else
                loadingDots = "."
        }
    }

    function popMainContent() {
        if (mainContentStackView.depth !== undefined) {
            if (mainContentStackView.depth > 1)
                mainContentStackView.pop()
        } else if (mainContentStackView.canPop()) {
            mainContentStackView.pop()
        }
    }

    function createIosWebView() {
        var webView = Qt.createQmlObject(
            "import QtQuick\n"
            + "import QtWebView\n"
            + "WebView {\n"
            + "    anchors.fill: parent\n"
            + "}\n",
            iosWebViewContainer,
            "IosSeminarPdfWebView"
        )

        webView.url = pdfView.pdfUrl
    }

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent
            spacing: 6

            ToolButton {
                text: "‹ Zurück"
                Layout.alignment: Qt.AlignVCenter
                onClicked: pdfView.popMainContent()
            }

            Label {
                text: titleText
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            ToolButton {
                text: "Teilen"
                Layout.alignment: Qt.AlignVCenter
                visible: pdfUrl !== ""
                onClicked: ClipboardHelper.shareUrl(pdfUrl)
            }
        }
    }

    Item {
        anchors.fill: parent

        Item {
            id: iosWebViewContainer
            anchors.fill: parent
            visible: pdfView.useWebView
            enabled: pdfView.useWebView
        }

        Loader {
            anchors.fill: parent
            active: !pdfView.useWebView
            sourceComponent: qtPdfContentComponent
        }

        SourceAttribution {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            sourceName: "Originaldokument beim DJKB"
            sourceUrl: pdfView.pdfUrl
            z: 10
        }
    }

    Component {
        id: qtPdfContentComponent

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: Constants.backgroundColor(rootWindow.isDarkMode)
            }

            PdfDocument {
                id: pdfDocument
                source: pdfView.localPdfUrl

                onStatusChanged: {
                    pdfView.pdfReady = pdfDocument.status === PdfDocument.Ready

                    if (pdfView.pdfReady) {
                        loadingTimer.stop()
                        return
                    }

                    if (pdfDocument.status === PdfDocument.Error) {
                        loadingTimer.stop()
                        pdfView.errorMessage = "Diese PDF-Datei konnte nicht dargestellt werden."
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: pdfView.pdfReady

                sourceComponent: PdfMultiPageView {
                    document: pdfDocument
                    renderScale: 0.35
                    clip: true
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: pdfView.errorMessage !== ""
                color: Constants.backgroundColor(rootWindow.isDarkMode)

                ColumnLayout {
                    width: Math.min(parent.width - 40, 420)
                    anchors.centerIn: parent
                    spacing: 14

                    Label {
                        text: pdfView.errorMessage
                        font.pixelSize: 16
                        font.bold: true
                        color: Constants.primaryTextColor(rootWindow.isDarkMode)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Erneut versuchen"
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: pdfView.startDownload()
                    }

                    Button {
                        text: "Extern öffnen"
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: Qt.openUrlExternally(pdfView.pdfUrl)
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: !pdfView.pdfReady && pdfView.errorMessage === ""
                color: Constants.backgroundColor(rootWindow.isDarkMode)

                Label {
                    anchors.centerIn: parent

                    text: pdfView.localPdfUrl === ""
                          ? "PDF wird heruntergeladen" + loadingDots
                          : "PDF wird geöffnet" + loadingDots

                    font.pixelSize: 18
                    font.bold: true
                    color: Constants.primaryTextColor(rootWindow.isDarkMode)

                    SequentialAnimation on opacity {
                        running: !pdfView.pdfReady
                        loops: Animation.Infinite

                        NumberAnimation {
                            from: 1.0
                            to: 0.45
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }

                        NumberAnimation {
                            from: 0.45
                            to: 1.0
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }
}
