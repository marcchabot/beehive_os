import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import "."

// ═══════════════════════════════════════════════════════════════
// WallpaperTab.qml — 🖼️ Wallpaper Settings
// ═══════════════════════════════════════════════════════════════

Item {
    id: wallpaperTab

    property string wallpaperFolder: BeeConfig.wallpaperFolder || "/home/marc/Pictures/Wallpapers"

    // ─── WallCard Component ───
    component WallCard: Item {
        property string src: ""
        property string label: ""
        property string mode: ""
        width: 156; height: 106

        property bool active: {
            if (!src) return false;
            let resolved = src.startsWith("..") ? Qt.resolvedUrl(src).toString() : "file://" + src;
            return resolved === BeeTheme.wallpaperOverride || BeeTheme.wallpaper === src;
        }

        Rectangle {
            anchors { fill: parent; margins: 4 }
            radius: 10; clip: true
            color: BeeTheme.secondary
            border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, active ? 1.0 : 0.18)
            border.width: active ? 2 : 1
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Image {
                anchors.fill: parent; anchors.margins: 1
                source: parent.parent.src.startsWith("..") ? parent.parent.src : "file://" + parent.parent.src
                fillMode: Image.PreserveAspectCrop
                asynchronous: true; smooth: true
                opacity: parent.parent.active ? 1.0 : 0.8
            }

            // Selected badge
            Rectangle {
                visible: parent.parent.active
                anchors { right: parent.right; top: parent.top; margins: 6 }
                width: 20; height: 20; radius: 10
                color: BeeTheme.accent
                Text { text: "✓"; anchors.centerIn: parent; color: BeeTheme.textPrimary; font.pixelSize: 10; font.bold: true }
            }

            // Hover overlay
            Rectangle {
                id: wallHover; anchors.fill: parent; color: "transparent"; radius: parent.radius
                property bool hov: false
                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onEntered: wallHover.hov = true
                    onExited:  wallHover.hov = false
                    onClicked: {
                        BeeTheme.wallpaperOverride = parent.parent.parent.src
                        if (BeeTheme.nectarSync && parent.parent.parent.mode !== "")
                            BeeTheme.setMode(parent.parent.parent.mode)
                        var name = parent.parent.parent.label || parent.parent.parent.src.split("/").pop()
                        BeeBarState.logAction("Design", "Wallpaper : " + name, "🖼")
                        BeeConfig.applyAutoThemeFromWallpaper(parent.parent.parent.src, false)
                    }
                }
                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 28; radius: parent.radius
                    color: Qt.rgba(0, 0, 0, wallHover.hov ? 0.55 : 0)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; margins: 8 }
                        text: wallHover.parent.label || ""
                        color: "white"; font.pixelSize: 9
                        elide: Text.ElideMiddle
                        opacity: wallHover.hov ? 0.90 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }
    }

    // ─── Main Layout ───
    ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: wallpaperTab.width - 32
            spacing: 16

            // ─── Folder Path ───
            Text {
                text: "📁 " + (BeeConfig.uiLang === "fr" ? "Dossier personnel" : "Personal folder")
                color: BeeTheme.accent
                font.bold: true; font.pixelSize: 14; font.letterSpacing: 1.2
            }
            Rectangle { height: 1; Layout.fillWidth: true; color: BeeTheme.separator }

            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Rectangle {
                    Layout.fillWidth: true; height: 28; radius: 8
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.18); border.width: 1
                    TextInput {
                        id: folderInput
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: Text.AlignVCenter
                        text: wallpaperTab.wallpaperFolder
                        color: BeeTheme.textPrimary; font.pixelSize: 11
                        selectByMouse: true
                        onEditingFinished: {
                            wallpaperTab.wallpaperFolder = text
                            BeeConfig.wallpaperFolder = text
                            BeeConfig.saveConfig()
                        }
                        Text {
                            visible: parent.text.length === 0
                            anchors { fill: parent }
                            verticalAlignment: Text.AlignVCenter
                            text: "~/Pictures/Wallpapers"
                            color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.30)
                            font.pixelSize: 11
                        }
                    }
                }
                Text {
                    visible: wallpaperModel.count > 0
                    text: wallpaperModel.count + (BeeConfig.uiLang === "fr" ? " image" : " image") + (wallpaperModel.count !== 1 ? (BeeConfig.uiLang === "fr" ? "s" : "s") : "")
                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.40)
                    font.pixelSize: 9
                }
            }

            Item { height: 4 }

            // ─── Bee-Hive Originals ───
            Text {
                text: (BeeConfig.uiLang === "fr" ? "🍯 ORIGINAUX BEE-HIVE" : "🍯 BEE-HIVE ORIGINALS")
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.45)
                font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5
            }

            Flow {
                Layout.fillWidth: true; spacing: 10
                WallCard { src: "../assets/wallpaper.png";               label: qsTr("Mysterious");      mode: "HoneyDark" }
                WallCard { src: "../assets/wallpaper_dark_bee.png";      label: qsTr("Dark Bee");        mode: "HoneyDark" }
                WallCard { src: "../assets/wallpaper_light_bee.png";     label: qsTr("Light Bee");       mode: "HoneyLight" }
                WallCard { src: "../assets/wallpaper_light.png";          label: qsTr("Soft Light");      mode: "HoneyLight" }
            }

            Rectangle { height: 1; Layout.fillWidth: true; color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08) }

            // ─── My Library ───
            Text {
                text: (BeeConfig.uiLang === "fr" ? "🖼 MA BIBLIOTHÈQUE" : "🖼 MY LIBRARY")
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.45)
                font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5
            }

            Text {
                visible: wallpaperModel.count === 0
                text: (BeeConfig.uiLang === "fr"
                    ? "Aucun fond d'écran trouvé dans " + wallpaperTab.wallpaperFolder
                    : "No wallpapers found in " + wallpaperTab.wallpaperFolder)
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.25)
                font.pixelSize: 11; font.italic: true
                Layout.leftMargin: 10
            }

            Flow {
                Layout.fillWidth: true; spacing: 10
                Repeater {
                    model: wallpaperModel
                    delegate: WallCard {
                        src: filePath
                        label: fileName
                    }
                }
            }
        }
    }

    // ─── Folder List Model ───
    FolderListModel {
        id: wallpaperModel
        folder: wallpaperTab.wallpaperFolder.length > 0
            ? Qt.resolvedUrl("file://" + wallpaperTab.wallpaperFolder)
            : Qt.resolvedUrl("file:///home/marc/Pictures/Wallpapers")
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        sortField: FolderListModel.Name
    }
}