import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtCore

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.coreaddons 1.0 as KCoreAddons
import org.kde.plasma.private.shell

import org.kde.kwindowsystem
import org.kde.kquickcontrolsaddons

import org.kde.plasma.components as PlasmaComponents3


import org.kde.kirigami as Kirigami
import org.kde.plasma.private.sessions

RowLayout{

    spacing: Kirigami.Units.largeSpacing

    KCoreAddons.KUser {   id: kuser  }
    //Logic {   id: logic }

    SessionManagement {
        id: sessionManager
    }

    RowLayout{
        MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: Qt.openUrlExternally("file:///usr/share/applications/kcm_users.desktop")
        }
        Image {
            id: iconUser
            source: {
                var faceUrl = kuser.faceIconUrl.toString()
                if (faceUrl !== "") {
                    return faceUrl
                }
                // Use proper icon path or theme icon
                return "file://usr/share/icons/breeze/apps/48/kuser.svg"
            }
            cache: false
            visible: source !== ""
            sourceSize.height: parent.height * 0.7
            sourceSize.width: parent.height * 0.7
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
        }

        PlasmaExtras.Heading {
            wrapMode: Text.NoWrap
            color: Kirigami.Theme.textColor
            level: 3
            font.bold: true
            //font.weight: Font.Bold
            text: qsTr(kuser.fullName)
        }   
    }


    PlasmaComponents3.ToolButton {
        MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: Qt.openUrlExternally("file:///home/" + qsTr(kuser.loginName))
        }
        icon.width: 24
        icon.height: 24
        icon.name:  "user-home"
        
        Layout.leftMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("User Home")
    }

    PlasmaComponents3.ToolButton {
        MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent 
                onClicked: Qt.openUrlExternally("file:///usr/share/applications/systemsettings.desktop")
                }
        icon.width: 24
        icon.height: 24
        icon.name:  "configure"
        Layout.leftMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("System Preferences")
    }

    Item{
        Layout.fillWidth: true
    }



    PlasmaComponents3.ToolButton {
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: sessionManager.requestLogout()  
                }
        icon.width: 24
        icon.height: 24
        icon.name: "system-lock-screen"
        
        Layout.rightMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Logout")
        visible: sessionManager.canLock
    }
    
    PlasmaComponents3.ToolButton {
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: sessionManager.suspend() 
                }
        icon.width: 24
        icon.height: 24
        icon.name:  "system-suspend"
        Layout.rightMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Sleep")
    }

    PlasmaComponents3.ToolButton {
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: sessionManager.requestReboot()
                }
        icon.width: 24
        icon.height: 24
        icon.name:  "system-reboot"
        Layout.rightMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Restart")
    }
    PlasmaComponents3.ToolButton {
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: sessionManager.requestShutdown()
                }
        icon.width: 24
        icon.height: 24
        icon.name:  "system-shutdown"
        Layout.rightMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Shutdown")
    }

    
}
