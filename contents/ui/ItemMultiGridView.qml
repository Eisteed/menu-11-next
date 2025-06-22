/*
SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>

SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.plasma.plasmoid

PlasmaComponents.ScrollView {
    id: itemMultiGrid

    //anchors {
    //    top: parent.top
    //}

    width: parent.width

    implicitHeight: itemColumn.implicitHeight

    //signal keyNavLeft(int subGridIndex)
    //signal keyNavRight(int subGridIndex)
    signal keyNavUp
    signal keyNavDown

    property bool grabFocus: false

    property alias model: repeater.model
    property alias count: repeater.count
    property alias flickableItem: flickable

    property int itemColumns
    property int cellWidth
    property int cellHeight

    function subGridAt(index) {
        return repeater.itemAt(index).itemGrid;
    }

    function tryActivate(row, col) { // FIXME TODO: Cleanup messy algo.
        if (flickable.contentY > 0) {
            row = 0;
        }

        var target = null;
        var rows = 0;

        for (var i = 0; i < repeater.count; i++) {
            var grid = subGridAt(i);
            if (grid.count > 0) {
                if (rows <= row) {
                    target = grid;
                    rows += grid.lastRow() + 2; // Header counts as one.
                } else {
                    break;
                }
            }
        }

        if (target) {
            rows -= (target.lastRow() + 2);
            target.tryActivate(row - rows, col);
        }
    }

    onFocusChanged: {
        if (!focus) {
            for (var i = 0; i < repeater.count; i++) {
                subGridAt(i).focus = false;
            }
        }
    }

    Flickable {
        id: flickable

        flickableDirection: Flickable.VerticalFlick
        contentHeight: itemColumn.implicitHeight
        //focusPolicy: Qt.NoFocus

        Column {
            id: itemColumn

            width: itemMultiGrid.width - Kirigami.Units.gridUnit

            Repeater {
                id: repeater

                delegate: Item {
                    id: itemTest
                    width: itemColumn.width
                    height: gridView.height + gridViewLabel.height + Kirigami.Units.largeSpacing * 2
                    visible: gridView.count > 0

                    property Item itemGrid: gridView

                    Kirigami.Heading {
                        id: gridViewLabel

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        //height: dummyHeading.height
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        opacity: 0.8
                        color: Kirigami.Theme.textColor
                        level: 3
                        font.bold: true
                        font.weight: Font.DemiBold
                        text: repeater.model.modelForRow(index).description
                        textFormat: Text.PlainText
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.left: gridViewLabel.right
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        anchors.verticalCenter: gridViewLabel.verticalCenter
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.15
                    }

                    MouseArea {
                        width: parent.width
                        height: parent.height
                        onClicked: root.toggle()
                    }

                    ItemGridView {
                        id: gridView

                    Connections {
                        target: gridView

                        onKeyNavDown: {
                            console.log("ItemMultiGridView.qml: ↓")

                            if (gridView.currentIndex < gridView.count - 1) {
                                gridView.currentIndex += 1
                                return
                            }

                            // At end of grid → jump to next grid
                            var i = index
                            for (var j = i + 1; j < repeater.count; j++) {
                                var next = subGridAt(j)
                                if (next.count > 0) {
                                    next.currentIndex = 0
                                    next.focus = true
                                    return
                                }
                            }
                        }

                        onKeyNavUp: {
                            console.log("ItemMultiGridView.qml: ↑")

                            if (gridView.currentIndex > 0) {
                                gridView.currentIndex -= 1
                                return
                            }
                            
                            // At start of grid → jump to previous grid
                            var i = index
                            for (var j = i - 1; j >= 0; j--) {
                                var prev = subGridAt(j)
                                if (prev.count > 0) {
                                    prev.currentIndex = prev.count - 1
                                    prev.focus = true
                                    return
                                }
                            }

                            // If first grid and first item → focus search bar
                            if (i === 0 && gridView.currentIndex === 0) {
                                searchField.forceActiveFocus()
                            }
                            
                        }
                    }

                        anchors {
                            top: gridViewLabel.bottom
                            topMargin: Kirigami.Units.largeSpacing
                        }

                        width: parent.width
                        height: count * itemMultiGrid.cellHeight
                        itemColumns: 2 //itemMultiGrid.itemColumns

                        cellWidth: itemMultiGrid.cellWidth
                        cellHeight: itemMultiGrid.cellHeight
                        iconSize: root.iconSize

                        verticalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
                        bypassArrowNav: true
                        model: repeater.model.modelForRow(index)

                        onFocusChanged: {
                            if (focus) {
                                itemMultiGrid.focus = true;
                            }
                        }

                        onCountChanged: {
                            if (itemMultiGrid.grabFocus && index == 0 && count > 0) {
                                currentIndex = 0;
                                focus = true;
                            }
                        }

                        onCurrentItemChanged: {
                            if (!currentItem) {
                                return;
                            }

                            if (index == 0 && currentRow() === 0) {
                                flickable.contentY = 0;
                                return;
                            }

                            var y = currentItem.y;
                            y = contentItem.mapToItem(flickable.contentItem, 0, y).y;

                            if (y < flickable.contentY) {
                                flickable.contentY = y;
                            } else {
                                y += itemMultiGrid.cellHeight;
                                y -= flickable.contentY;
                                y -= itemMultiGrid.height;

                                if (y > 0) {
                                    flickable.contentY += y;
                                }
                            }
                        }
                    }
                }
            }

            // HACK: Steal wheel events from the nested grid view and forward them to
            // the ScrollView's internal WheelArea.
            Kicker.WheelInterceptor {
                anchors.fill: gridView
                z: 1
                destination: findWheelArea(itemMultiGrid)
            }
        }
    }
}
