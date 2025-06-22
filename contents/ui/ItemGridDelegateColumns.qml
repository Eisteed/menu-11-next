/*
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import QtQuick.Layouts 1.1
import "code/tools.js" as Tools

Item {
    id: item

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    enabled: !model.disabled

    property int iconSize
    property bool showLabel: true
    property int itemIndex: model.index
    property string favoriteId: model.favoriteId !== undefined ? model.favoriteId : ""
    property url url: model.url !== undefined ? model.url : ""
    property variant icon: model.decoration !== undefined ? model.decoration : ""
    property var m: model
    property bool hasActionList: ((model.favoriteId !== null)
                                  || (("hasActionList" in model) && (model.hasActionList === true)))

    property int itemColumns
    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display

    function openActionMenu(x, y) {
        var actionList = hasActionList ? model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, GridView.view.model.favoritesModel, model.favoriteId);
        actionMenu.visualParent = item;
        actionMenu.open(x, y);
    }

    function actionTriggered(actionId, actionArgument) {
        var close = (Tools.triggerAction(GridView.view.model, model.index, actionId, actionArgument) === true);

        if (close) {
            root.toggle();
        }
    }


    Kirigami.Icon {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Kirigami.Units.largeSpacing

        width: iconSize
        height: width

        animated: false

        source: model.decoration
    }


    PlasmaComponents3.Label {
        id: label
        visible: item.showLabel
        anchors {
            left: icon.right
            leftMargin: Kirigami.Units.largeSpacing
            right: itemColumns == 2 ?  parent.right : desc.left
            rightMargin: Kirigami.Units.largeSpacing
            verticalCenter: icon.verticalCenter

        }
        anchors.verticalCenterOffset: itemColumns == 2 ? -Kirigami.Units.largeSpacing : 0
        horizontalAlignment: Text.AlignLeft
        maximumLineCount: 1
        elide: Text.ElideMiddle
        //wrapMode: Text.Wrap
        color: Kirigami.Theme.textColor
        font.pointSize: Kirigami.Theme.defaultFont.pointSize
        text: ("name" in model ? model.name : model.display)
        textFormat: Text.PlainText
    }

    PlasmaComponents3.Label {
        id: desc
        anchors {
                top: itemColumns == 2 ? label.bottom: undefined
                left: itemColumns == 2 ? icon.right : undefined
                leftMargin: Kirigami.Units.largeSpacing
                right: parent.right
                rightMargin: Kirigami.Units.largeSpacing
                verticalCenter: itemColumns == 2 ? undefined : icon.verticalCenter
        }
        horizontalAlignment: itemColumns == 2 ? Text.AlignLeft : Text.AlignRight
        maximumLineCount: 1
        elide: Text.ElideMiddle
        //wrapMode: Text.Wrap

        color: colorWithAlpha(Kirigami.Theme.textColor,0.4)
        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
        text: ("description" in model ? model.description : "")
        textFormat: Text.PlainText
    }

    PlasmaCore.ToolTipArea {
        id: toolTip

        property string text: model.display

        anchors.fill: parent
        active: root.visible && label.truncated
        mainItem: toolTipDelegate

        onContainsMouseChanged: item.GridView.view.itemContainsMouseChanged(containsMouse)
    }

    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Menu && hasActionList) {
                            event.accepted = true;
                            openActionMenu(item);
                        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                            event.accepted = true;

                            if ("trigger" in GridView.view.model) {
                                GridView.view.model.trigger(index, "", null);
                                root.toggle();
                            }

                            itemGrid.itemActivated(index, "", null);
                        }
                    }
}
