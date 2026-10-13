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

    signal tabOut

    Keys.onTabPressed: event => {
        event.accepted = true;
        tabOut();
    }

    KCoreAddons.KUser {   id: kuser  }
    //Logic {   id: logic }

    SessionManagement {
        id: sessionManager
    }

    // The menu is a stay-on-top window; while it is open, Plasma refuses to
    // show the logout/shutdown prompt. Close the menu first, then run the action.
    function runSessionAction(action) {
        root.visible = false;
        sessionActionTimer.action = action;
        sessionActionTimer.restart();
    }

    Timer {
        id: sessionActionTimer
        interval: 250
        property string action: ""
        onTriggered: {
            switch (action) {
            case "logout":   sessionManager.requestLogout();   break;
            case "reboot":   sessionManager.requestReboot();   break;
            case "shutdown": sessionManager.requestShutdown(); break;
            case "suspend":  sessionManager.suspend();         break;
            }
        }
    }

    Item {
        implicitWidth: userInfoRow.implicitWidth
        implicitHeight: userInfoRow.implicitHeight
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            id: userInfoRow
            anchors.fill: parent

            Image {
                id: iconUser
                source: {
                    var faceUrl = kuser.faceIconUrl.toString()
                    if (faceUrl !== "") {
                        return faceUrl
                    }
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
                text: qsTr(kuser.fullName)
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally("file:///usr/share/applications/kcm_users.desktop")
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
            onClicked: executable.exec("systemsettings")
        }
        icon.width: 24
        icon.height: 24
        icon.name: "configure"
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
                onClicked: runSessionAction("logout")
                }
        icon.width: 24
        icon.height: 24
        icon.name: "system-log-out"

        Layout.rightMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Logout")
        visible: sessionManager.canLogout
    }
    
    PlasmaComponents3.ToolButton {
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: runSessionAction("suspend")
                }
        icon.width: 24
        icon.height: 24
        icon.name:  "system-suspend"
        Layout.rightMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Sleep")
        visible: sessionManager.canSuspend && Plasmoid.configuration.showSleepButton
    }

    PlasmaComponents3.ToolButton {
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: runSessionAction("reboot")
                }
        icon.width: 24
        icon.height: 24
        icon.name:  "system-reboot"
        Layout.rightMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Restart")
        visible: sessionManager.canReboot && Plasmoid.configuration.showRestartButton
    }
    PlasmaComponents3.ToolButton {
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: runSessionAction("shutdown")
                }
        icon.width: 24
        icon.height: 24
        icon.name:  "system-shutdown"
        Layout.rightMargin: 10
        PlasmaComponents3.ToolTip.delay: 1000
        PlasmaComponents3.ToolTip.timeout: 1000
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.text: i18n("Shutdown")
        visible: sessionManager.canShutdown && Plasmoid.configuration.showShutdownButton
    }

    
}
