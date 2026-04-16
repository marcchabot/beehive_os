import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

// ═══════════════════════════════════════════════════════════════
// BeeNotes.qml — Quick Notes Widget for MayaDash 🐝
// v1.6 : Absolute Zero-Semicolon Version (Surgical Clean)
// ═══════════════════════════════════════════════════════════════

Item {
    id: beeNotesRoot
    
    width: 320
    height: 400

    // ─── Visuel principal (le "corps" des notes) ─────────────────
    Rectangle {
        id: mainBkg
        anchors.centerIn: parent
        width: 320
        height: 400
        radius: 12
        color: Qt.rgba(BeeTheme.surface.r, BeeTheme.surface.g, BeeTheme.surface.b, 0.85)
        border.color: Qt.rgba(BeeTheme.accent.r, BeeTheme.accent.g, BeeTheme.accent.b, 0.3)
        border.width: 1
    }

    // ─── Ombre et Effets (Qt 6 Modern Approach) ──────────────────
    MultiEffect {
        id: shadowEffect
        anchors.fill: mainBkg
        source: mainBkg
        
        shadowEnabled: true
        shadowColor: "#40000000"
        shadowBlur: 1.0
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
    }

    // ─── Bouclier Souris (Anti Click-Through) ────────────────────
    // Capture les clics sur le fond, mais les enfants (TextField, boutons) 
    // sont au-dessus (z:1) et reçoivent les événements normalement
    MouseArea {
        id: mouseShield
        anchors.fill: parent
        z: 0
        propagateComposedEvents: false
        onPressed: {
            // Capture le clic sur le fond mais permet aux enfants de recevoir
            mouse.accepted = true
            // Donne le focus au TextField si on clique dans la zone input
            if (inputArea.contains(mapToItem(inputArea, mouse.x, mouse.y))) {
                newNoteText.forceActiveFocus()
                mouse.accepted = false
            }
        }
    }

    // ─── Logique de données ──────────────────────────────────────
    property var notesData: []
    property string notesFile: "file://" + Qt.resolvedUrl("../data/quick_notes.json")
    
    Component.onCompleted: {
        loadNotes()
    }
    
    function loadNotes() {
        var request = new XMLHttpRequest()
        request.open("GET", notesFile)
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    try {
                        notesData = JSON.parse(request.responseText)
                        notesModel.clear()
                        for (var i = 0; i < notesData.length; i++) {
                            notesModel.append(notesData[i])
                        }
                    } catch (e) {
                        console.log("BeeNotes: Could not parse notes file, starting fresh")
                        notesData = []
                    }
                } else {
                    notesData = []
                }
            }
        }
        request.send()
    }
    
    function saveNotes() {
        notesData = []
        for (var i = 0; i < notesModel.count; i++) {
            notesData.push(notesModel.get(i))
        }
        
        var request = new XMLHttpRequest()
        request.open("PUT", notesFile)
        request.setRequestHeader("Content-Type", "application/json")
        request.send(JSON.stringify(notesData, null, 2))
        
        saveAnimation.start()
    }
    
    function addNote() {
        if (newNoteText.text.trim() !== "") {
            var newNote = {
                "id": Date.now(),
                "text": newNoteText.text,
                "timestamp": new Date().toLocaleString(),
                "color": BeeTheme.accent
            }
            
            notesModel.insert(0, newNote)
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
                anchors.rightMargin: 16
                
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
                color: Qt.rgba(model.color.r, model.color.g, model.color.b, 0.1)
                border.color: Qt.rgba(model.color.r, model.color.g, model.color.b, 0.3)
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
                    cursorShape: Qt.PointingHandCursor
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
            color: Qt.rgba(BeeTheme.surface.r, BeeTheme.surface.g, BeeTheme.surface.b, 0.5)
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
                        color: Qt.rgba(BeeTheme.surface.r, BeeTheme.surface.g, BeeTheme.surface.b, 0.7)
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