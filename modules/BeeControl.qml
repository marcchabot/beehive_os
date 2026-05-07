import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtCore
import "."
// import "BeeControl"  // tabs removed for testing

// ═══════════════════════════════════════════════════════════════
// BeeControl.qml — "The Hive" Control Center v2 🐝🍯
// Refonte complète : Shell principal + tabs modulaires
// Navigation latérale avec labels + recherche
// ═══════════════════════════════════════════════════════════════

Rectangle {
    id: controlRoot
    width:  820
    height: 620
    radius: 28
    visible: false
    anchors.centerIn: parent
    clip: true

    // ─── Entry / Exit animation ───────────────────────────
    property real panelScale: visible ? 1.0 : 0.92
    property real panelOpacity: visible ? 1.0 : 0.0
    Behavior on panelScale   { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on panelOpacity { NumberAnimation { duration: 200 } }
    scale: panelScale
    opacity: panelOpacity

    // ─── State ──────────────────────────────────────────────
    property int currentTab: 0   // 0=General 1=Appearance 2=Wallpaper 3=Bar&Widgets 4=Productivity 5=Shortcuts 6=Extensions 7=Accessibility 8=Journal

    property string _activePaletteKey: "honey_gold"
    property var _s: BeeConfig.tr.settings || {}

    // ─── Styles ─────────────────────────────────────────────
    color: BeeTheme.mode === "HoneyDark"
        ? Qt.rgba(0.06, 0.05, 0.08, 1.0)
        : Qt.rgba(0.96, 0.94, 0.90, 1.0)
    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.35)
    border.width: 1

    Behavior on color        { ColorAnimation { duration: 600 } }
    Behavior on border.color { ColorAnimation { duration: 600 } }

    // Drop shadow + frosted blur
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0,0,0, BeeTheme.mode === "HoneyDark" ? 0.45 : 0.12)
        shadowBlur: 1.0
        shadowVerticalOffset: 6
        blurEnabled: false
    }

    // ─── Reusable Components ───────────────────────────────
    // SectionHeader.qml and SettingRow.qml are in BeeControl/ directory
    // and imported via "BeeControl" import

    // ─── Close button ───────────────────────────────────────
    Rectangle {
        anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 10 }
        width: 34; height: 34; radius: 17; z: 100
        color: closeHov.containsMouse
            ? Qt.rgba(1.0, 0.3, 0.3, 0.25)
            : (BeeTheme.mode === "HoneyDark" ? Qt.rgba(0.06, 0.05, 0.08, 1.0) : Qt.rgba(0.96, 0.94, 0.90, 1.0))
        border.color: closeHov.containsMouse ? Qt.rgba(1.0, 0.3, 0.3, 0.6) : BeeTheme.accent
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Text { text: "✕"; anchors.centerIn: parent; color: closeHov.containsMouse ? "#ff5555" : BeeTheme.accent; font.bold: true; font.pixelSize: 14 }
        MouseArea { id: closeHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { controlRoot.visible = false } }
    }

    // ─── Sidebar + Content ──────────────────────────────────
    RowLayout {
        anchors.fill: parent; spacing: 0
        anchors.margins: 1

        // ─── Sidebar (Navigation v2 — icons + labels + search) ───
        Rectangle {
            id: sidebar
            Layout.fillHeight: true
            width: 130
            color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.05)
            
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: BeeTheme.separator }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 12
                spacing: 0

                // Logo
                Text { text: "🐝"; font.pixelSize: 28; Layout.alignment: Qt.AlignHCenter; bottomPadding: 4 }
                Text { text: "The Hive"; color: BeeTheme.accent; font.bold: true; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter; bottomPadding: 8 }

                // Search bar
                Rectangle {
                    Layout.fillWidth: true; Layout.leftMargin: 8; Layout.rightMargin: 8
                    height: 28; radius: 14
                    color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.08)
                    border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                    border.width: 1
                    
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 4
                        Text { text: "🔍"; font.pixelSize: 11; opacity: 0.5 }
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: BeeTheme.textPrimary; font.pixelSize: 11
                            verticalAlignment: Text.AlignVCenter
                            selectByMouse: true
                            onTextChanged: controlRoot.filterTabs(text)
                            onAccepted: controlRoot.jumpToFirstMatch()
                            Keys.onEscapePressed: { text = ""; controlRoot.filterTabs("") }

                            // Placeholder overlay (placeholderText not available on TextInput)
                            Text {
                                anchors.fill: parent
                                text: controlRoot._s.searchPlaceholder || "Search..."
                                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.3)
                                font.pixelSize: 11
                                verticalAlignment: Text.AlignVCenter
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }
                    }
                }

                Item { height: 6 } // spacer

                // Navigation items
                ListView {
                    id: navList
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.leftMargin: 4; Layout.rightMargin: 4
                    clip: true
                    spacing: 2
                    model: ListModel { id: navModel }
                    delegate: navDelegate
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                }

                Item { height: 8 } // bottom spacer
            }
        }

        // ─── Main Content (Tabs) ───
        Loader {
            id: contentLoader
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            source: {
                switch (controlRoot.currentTab) {
                    case 0: return "GeneralTab.qml"
                    // case 1: return "AppearanceTab.qml"
                    // case 2: return "WallpaperTab.qml"
                    // case 3: return "BarWidgetsTab.qml"
                    // case 4: return "ProductivityTab.qml"
                    // case 5: return "ShortcutsTab.qml"
                    // case 6: return "ExtensionsTab.qml"
                    // case 7: return "AccessibilityTab.qml"
                    // case 8: return "HistoryTab.qml"
                    default: return "GeneralTab.qml"
                }
            }
        }
    }

    // ─── Navigation Data & Logic ─────────────────────────────
    property var tabData: [
        { icon: "🏠", label: qsTr("General"),       idx: 0 },
        { icon: "🎨", label: qsTr("Appearance"),    idx: 1 },
        { icon: "🖼️", label: qsTr("Wallpaper"),     idx: 2 },
        { icon: "📊", label: qsTr("Bar & Widgets"),  idx: 3 },
        { icon: "📅", label: qsTr("Productivity"),   idx: 4 },
        { icon: "⌨️", label: qsTr("Shortcuts"),     idx: 5 },
        { icon: "🧩", label: qsTr("Extensions"),    idx: 6 },
        { icon: "♿", label: qsTr("Accessibility"),  idx: 7 },
        { icon: "📜", label: qsTr("Journal"),       idx: 8 }
    ]

    Component.onCompleted: rebuildNav()

    function rebuildNav() {
        navModel.clear()
        for (var i = 0; i < tabData.length; i++) {
            navModel.append(tabData[i])
        }
    }

    function filterTabs(query) {
        navModel.clear()
        var q = query.toLowerCase()
        for (var i = 0; i < tabData.length; i++) {
            if (q === "" || tabData[i].label.toLowerCase().indexOf(q) >= 0) {
                navModel.append(tabData[i])
            }
        }
    }

    function jumpToFirstMatch() {
        if (navModel.count > 0) {
            var first = navModel.get(0)
            controlRoot.currentTab = first.idx
            searchInput.text = ""
            filterTabs("")
        }
    }

    // ─── Nav Item Delegate ───────────────────────────────────
    Component {
        id: navDelegate
        
        Item {
            width: navList.width
            height: 40
            
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: controlRoot.currentTab === model.idx
                    ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.15)
                    : (navHover.containsMouse ? Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.06) : "transparent")
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: model.icon
                    font.pixelSize: 18
                    opacity: controlRoot.currentTab === model.idx ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Text {
                    text: model.label
                    color: controlRoot.currentTab === model.idx ? BeeTheme.accent : BeeTheme.textPrimary
                    font.pixelSize: 12; font.bold: controlRoot.currentTab === model.idx
                    opacity: controlRoot.currentTab === model.idx ? 1.0 : 0.7
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                id: navHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (controlRoot.currentTab !== model.idx) {
                        controlRoot.currentTab = model.idx
                        BeeSound.playEvent("ui.cell.click", {})
                    }
                }
            }
        }
    }

    // ─── Sound ───────────────────────────────────────────────
    onVisibleChanged: {
        // Sound is handled by IPC triggers or button clicks
    }
}