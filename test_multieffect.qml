import QtQuick
import QtQuick.Effects

Rectangle {
    width: 400
    height: 300
    color: "lightblue"
    
    MultiEffect {
        anchors.fill: parent
        source: parent
        shadowEnabled: true
        shadowColor: "#20000000"
        shadowBlur: 16
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
    }
    
    Text {
        text: "MultiEffect Test"
        anchors.centerIn: parent
        font.pixelSize: 24
        color: "black"
    }
}
