import QtQuick 2.4
import QtQuick.Controls
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami as Kirigami

Rectangle{

    id:item


    property int buttonHeight: Math.floor(Kirigami.Units.gridUnit * 2)
    implicitHeight: buttonHeight
    implicitWidth: row.implicitWidth + (Kirigami.Units.mediumSpacing * 2)

    border.width: mouseItem.containsMouse || focus || activeFocus  ? 2 : 1
    border.color: Qt.rgba(0.5, 0.5, 0.5, 0.6) // Gray border always

    radius: 5
    color: mouseItem.containsMouse ? Qt.rgba(0.7, 0.7, 0.7, 0.3) : Kirigami.Theme.backgroundColor
    
    smooth: true // Plasmoid.configuration.iconSmooth
    focus: true

    property alias text: lb.text
    property bool flat: false
    property alias iconName: icon.source
    property bool mirror: false

    signal clicked

    //Keys.onEnterPressed: item.clicked()
    Keys.onSpacePressed: item.clicked()

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        anchors.topMargin: Kirigami.Units.smallSpacing / 2
        anchors.bottomMargin: Kirigami.Units.smallSpacing / 2
        spacing: Kirigami.Units.smallSpacing
        LayoutMirroring.enabled: mirror

        Label {
            id: lb
            color: Kirigami.Theme.textColor
            Layout.leftMargin: Kirigami.Units.smallSpacing
        }

        Kirigami.Icon {
            id: icon
            implicitHeight: Kirigami.Units.gridUnit
            implicitWidth: implicitHeight
            smooth: true
        }
    }

    MouseArea {
        id: mouseItem
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
    }

}
