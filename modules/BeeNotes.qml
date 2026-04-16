import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════
// BeeNotes.qml — Quick Notes Widget for MayaDash 🐝
// v2.0 : Simple text file persistence — no JSON, no timers
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeNotesRoot
    
    width: 320
    height: 400

    // ─── Signal pour fermer le PanelWindow parent ────────────────
    signal closeRequested()

    // ─── Visuel principal (le "corps" des notes) ─────────────────
    Rectangle {
        id: mainBkg
        anchors.centerIn: parent
        width: 320
        height: 400
        radius: 12
        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.85)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
        border.width: 1
    }

    // ─── Logique de données ──────────────────────────────────────
    property string notesFile: "file:///home/marc/beehive_os/data/notes.txt"

    // Predefined note colors (hex strings)
    property var noteColors: ["#FFC107", "#4CAF50", "#2196F3", "#E91E63", "#9C27B0", "#FF5722"]

    // Helper: parse hex color to {r,g,b} for delegate
    function colorToRgb(c) {
        if (typeof c === "object" && c !== null && c.r !== undefined)
            return { r: c.r, g: c.g, b: c.b }
        if (typeof c === "string" && c.charAt(0) === "#" && c.length === 7) {
            var rr = parseInt(c.substring(1,3), 16) / 255
            var gg = parseInt(c.substring(3,5), 16) / 255
            var bb = parseInt(c.substring(5,7), 16) / 255
            return { r: rr, g: gg, b: bb }
        }
        return { r: BeeTheme.accent.r, g: BeeTheme.accent.g, b: BeeTheme.accent.b }
    }

    Component.onCompleted: {
        loadNotes()
    }

    // ─── Load: read text file, one note per line ─────────────────
    // Format: timestamp|color|text
    function loadNotes() {
        var request = new XMLHttpRequest()
        request.open("GET", notesFile)
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                notesModel.clear()
                if (request.status === 200 && request.responseText.trim() !== "") {
                    var lines = request.responseText.split("\n")
                    var count = 0
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim()
                        if (line === "") continue
                        // Split on first 2 pipes: timestamp|color|text
                        var firstPipe = line.indexOf("|")
                        if (firstPipe === -1) continue
                        var secondPipe = line.indexOf("|", firstPipe + 1)
                        if (secondPipe === -1) continue
                        var ts = line.substring(0, firstPipe)
                        var col = line.substring(firstPipe + 1, secondPipe)
                        var txt = line.substring(secondPipe + 1)
                        notesModel.append({
                            "text": txt,
                            "timestamp": ts,
                            "color": col
                        })
                        count++
                    }
                    console.log("BeeNotes: Loaded " + count + " notes from text file")
                } else {
                    // No file yet → create default notes
                    console.log("BeeNotes: No notes file found, creating defaults")
                    var defaults = [
                        { text: "Welcome to Bee-Hive OS Quick Notes!", timestamp: Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm"), color: noteColors[0] },
                        { text: "Type your notes here and they'll be saved automatically.", timestamp: Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm"), color: noteColors[1] },
                        { text: "Click on a note to edit it, hover to see the delete button.", timestamp: Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm"), color: noteColors[2] }
                    ]
                    for (var j = 0; j < defaults.length; j++) {
                        notesModel.append(defaults[j])
                    }
                    saveNotes()
                }
            }
        }
        request.send()
    }

    // ─── Save: write entire model to text file immediately ───────
    // Format: timestamp|color|text  (one line per note)
    function saveNotes() {
        var lines = []
        for (var i = 0; i < notesModel.count; i++) {
            var item = notesModel.get(i)
            var noteColor = item.color
            // Ensure color is a hex string
            if (typeof noteColor === "object" && noteColor !== null) {
                noteColor = "#" + ((1 << 24) + (Math.round(noteColor.r * 255) << 16) + (Math.round(noteColor.g * 255) << 8) + Math.round(noteColor.b * 255)).toString(16).slice(1).toUpperCase()
            }
            lines.push(item.timestamp + "|" + noteColor + "|" + item.text)
        }
        var content = lines.join("\n")
        var request = new XMLHttpRequest()
        request.open("PUT", notesFile)
        request.setRequestHeader("Content-Type", "text/plain")
        request.send(content)
        console.log("BeeNotes: Saved " + notesModel.count + " notes to text file")
        saveAnimation.start()
    }

    function addNote() {
        if (newNoteText.text.trim() !== "") {
            var colorIdx = notesModel.count % noteColors.length
            notesModel.insert(0, {
                "text": newNoteText.text,
                "timestamp": Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm"),
                "color": noteColors[colorIdx]
            })
            newNoteText.text = ""
            newNoteText.focus = false
            saveNotes()
        }
    }

    function deleteNote(index) {
        notesModel.remove(index)
        saveNotes()
    }

    // ─── Contenu UI ──────────────────────────────────────────────
    Item {
        anchors.fill: mainBkg
        z: 1

        Rectangle {
            id: header
            width: parent.width
            height: 50
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 8
                
                Text {
                    text: "📝 Quick Notes"
                    font.bold: true
                    font.pixelSize: 16
                    color: BeeTheme.textPrimary
                    Layout.alignment: Qt.AlignVCenter
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: notesModel.count + " note" + (notesModel.count !== 1 ? "s" : "")
                    font.pixelSize: 12
                    color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.7)
                    Layout.alignment: Qt.AlignVCenter
                }
                
                // ─── Close Button (✕) ────────────────────────────
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeBtnMA.containsMouse
                        ? Qt.rgba(1, 0.3, 0.3, 0.9)
                        : Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.15)
                    border.color: closeBtnMA.containsMouse
                        ? "#ff6666"
                        : Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.3)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        text: "✕"
                        font.bold: true
                        font.pixelSize: 14
                        color: closeBtnMA.containsMouse ? "white" : BeeTheme.textPrimary
                        anchors.centerIn: parent
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    MouseArea {
                        id: closeBtnMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            beeNotesRoot.closeRequested()
                        }
                    }
                }
            }
            
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
                anchors.bottom: parent.bottom
            }
        }
        
        ListView {
            id: notesList
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: inputArea.top
            anchors.margins: 12
            clip: true
            spacing: 8
            
            model: ListModel { id: notesModel }
            
            delegate: Rectangle {
                id: noteDelegate
                width: notesList.width
                height: noteContent.height + 32
                radius: 8
                property color noteColor: {
                    var rgb = colorToRgb(model.color)
                    return Qt.rgba(rgb.r, rgb.g, rgb.b, 1)
                }
                color: Qt.rgba(noteColor.r, noteColor.g, noteColor.b, 0.1)
                border.color: Qt.rgba(noteColor.r, noteColor.g, noteColor.b, 0.3)
                border.width: 1
                
                states: State {
                    name: "hovered"
                    when: mouseArea.containsMouse
                    PropertyChanges { target: noteDelegate; scale: 1.02; z: 1 }
                }
                
                transitions: Transition {
                    NumberAnimation { properties: "scale"; duration: 200 }
                }
                
                Column {
                    id: noteContent
                    width: parent.width - 24
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Text {
                        width: parent.width
                        text: model.text
                        wrapMode: Text.Wrap
                        font.pixelSize: 13
                        color: BeeTheme.textPrimary
                    }
                    
                    Text {
                        width: parent.width
                        text: model.timestamp
                        font.pixelSize: 10
                        color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5)
                        horizontalAlignment: Text.AlignRight
                    }
                }
                
                Rectangle {
                    id: deleteButton
                    width: 24
                    height: 24
                    radius: 12
                    color: Qt.rgba(1, 0.3, 0.3, 0.8)
                    border.color: "#ff4444"
                    border.width: 1
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    opacity: mouseArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
                    Text { text: "×"; font.bold: true; font.pixelSize: 16; color: "white"; anchors.centerIn: parent }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deleteNote(index)
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointersHandCursor
                    onClicked: {
                        newNoteText.text = model.text
                        newNoteText.focus = true
                        deleteNote(index)
                    }
                }
            }
            
            Text {
                visible: notesModel.count === 0
                text: "No notes yet\nType below to add your first note!"
                font.pixelSize: 14
                color: Qt.rgba(BeeTheme.textPrimary.r, BeeTheme.textPrimary.g, BeeTheme.textPrimary.b, 0.5)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent
                wrapMode: Text.Wrap
                lineHeight: 1.4
            }
        }
        
        Rectangle {
            id: inputArea
            width: parent.width
            height: 80
            color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.5)
            anchors.bottom: parent.bottom
            
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.2)
            }
            
            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                
                TextField {
                    id: newNoteText
                    width: parent.width
                    height: 36
                    placeholderText: "Type your note here..."
                    font.pixelSize: 13
                    color: BeeTheme.textPrimary
                    background: Rectangle {
                        radius: 6
                        color: Qt.rgba(BeeTheme.secondary.r, BeeTheme.secondary.g, BeeTheme.secondary.b, 0.7)
                        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.4)
                        border.width: 1
                    }
                    onAccepted: addNote()
                }
                
                RowLayout {
                    width: parent.width
                    Button {
                        text: "Add Note"
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 32
                        background: Rectangle {
                            radius: 6
                            color: parent.pressed ? Qt.darker(BeeTheme.accent, 1.2) : BeeTheme.accent
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 12
                            font.bold: true
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: addNote()
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "💾 Saved"
                        font.pixelSize: 11
                        color: Qt.rgba(0, 0.7, 0, 0.8)
                        opacity: saveAnimation.running ? 1 : 0
                        SequentialAnimation on opacity {
                            id: saveAnimation
                            running: false
                            NumberAnimation { to: 1; duration: 200 }
                            PauseAnimation { duration: 1000 }
                            NumberAnimation { to: 0; duration: 200 }
                        }
                    }
                }
            }
        }
    }
}