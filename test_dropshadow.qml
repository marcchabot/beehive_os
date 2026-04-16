import QtQuick
import QtQuick.Controls

Rectangle {
    width: 400
    height: 300
    color: "lightblue"
    
    Rectangle {
        width: 300
        height: 200
        anchors.centerIn: parent
        color: "white"
        radius: 12
        
        DropShadow {
            anchors.fill: parent
            source: parent
            color: "#20000000"
            blur: 16
            verticalOffset: 4
            horizontalOffset: 0
        }
        
        Text {
            text: "DropShadow Test"
            anchors.centerIn: parent
            font.pixelSize: 24
            color: "black"
        }
    }
}
