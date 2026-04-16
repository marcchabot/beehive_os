import QtQuick

Rectangle {
    width: 400
    height: 300
    color: "lightblue"
    
    // Manual shadow using a second rectangle
    Rectangle {
        width: 300
        height: 200
        anchors.centerIn: parent
        anchors.horizontalOffset: 8
        anchors.verticalOffset: 8
        z: -1
        color: "#20000000"
        radius: 12
    }
    
    Rectangle {
        width: 300
        height: 200
        anchors.centerIn: parent
        color: "white"
        radius: 12
        
        Text {
            text: "Manual Shadow Test"
            anchors.centerIn: parent
            font.pixelSize: 24
            color: "black"
        }
    }
}
