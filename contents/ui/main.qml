/***************************************************************************
 *   Copyright (C) 2014-2015 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.plasmoid

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.kitemmodels 1.0 as KItemModels

PlasmoidItem {

    id: kicker

    anchors.fill: parent

    signal reset

    preferredRepresentation: compactRepresentation
    compactRepresentation: compactRepresentation
    fullRepresentation: compactRepresentation

    property Item dragSource: null
    property string searchRunnerFilter: "all"

    // Keep settings identical when this widget is on multiple panels.
    SharedConfig {
        id: sharedConfig
        syncEnabled: Plasmoid.configuration.syncConfigAcrossPanels !== false
    }

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    Component {
        id: compactRepresentation
        CompactRepresentation {}
    }

    property QtObject globalFavorites: rootModel.favoritesModel
    property QtObject systemFavorites: rootModel.systemFavoritesModel

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon

    onSystemFavoritesChanged: {
        if (systemFavorites) {
            systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }
    }

    Kicker.RootModel {
        id: rootModel

        autoPopulate: false

        appNameFormat: 0
        flat: true
        sorted: true
        showAllAppsCategorized: false // true
        showSeparators: false
        appletInterface: kicker
        showAllApps: true
        showRecentApps: true
        showRecentDocs: Plasmoid.configuration.showRecentDocs
        showPowerSession: false

        onShowRecentAppsChanged: {
            Plasmoid.configuration.showRecentApps = showRecentApps;
        }

        onShowRecentDocsChanged: {
            Plasmoid.configuration.showRecentDocs = showRecentDocs;
        }

        onRecentOrderingChanged: {
            Plasmoid.configuration.recentOrdering = recentOrdering;
        }

        Component.onCompleted: {
            // Keep the per-instance client id; favoriteApps is mirrored by SharedConfig.
            favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)

            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favoriteApps);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }
        }
    }

    Connections {
        target: globalFavorites

        function onFavoritesChanged() {
            Plasmoid.configuration.favoriteApps = target.favorites;
        }
    }

    Connections {
        target: systemFavorites

        function onFavoritesChanged() {
            if (Plasmoid.configuration && target)
                Plasmoid.configuration.favoriteSystemActions = target.favorites;
        }
    }

    Kicker.RootModel {
        id: categoryRootModel

        autoPopulate: false
        appNameFormat: 0
        flat: false
        sorted: true
        showSeparators: false
        showAllApps: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
    }

    Connections {
        target: Plasmoid.configuration

        function onFavoriteAppsChanged () {
            if (globalFavorites)
                globalFavorites.favorites = Plasmoid.configuration.favoriteApps;
        }

        function onFavoriteSystemActionsChanged () {
            if (systemFavorites)
                systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }

        function onHiddenApplicationsChanged(){
            rootModel.refresh();
            categoryRootModel.refresh();
        }
    }

    Kicker.RunnerModel {
         id: runnerModel

         appletInterface: kicker

         favoritesModel: globalFavorites

         runners: {
             const blacklist = ["krunner_webshortcuts", "webshortcuts"];
             function clean(list) {
                 return list.filter(function(r) { return blacklist.indexOf(r) === -1; });
             }
             if (kicker.searchRunnerFilter === "apps")
                 return ["krunner_services"];
             if (kicker.searchRunnerFilter === "files")
                 return ["baloosearch", "bookmarks"];
             if (kicker.searchRunnerFilter === "settings")
                 return ["krunner_systemsettings"];
             if (kicker.searchRunnerFilter === "actions")
                 return ["krunner_sessions", "krunner_powerdevil", "calculator", "unitconverter"];

             const results = ["krunner_services",
                              "krunner_systemsettings",
                              "krunner_sessions",
                              "krunner_powerdevil",
                              "calculator",
                              "unitconverter"];
             if (Plasmoid.configuration.enableShellRunner)
                 results.push("krunner_shell");
             if (Plasmoid.configuration.useExtraRunners)
                 results.push(...clean(Plasmoid.configuration.extraRunners));
             return results;
         }
     }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner;
    }

    Kicker.WindowSystem {
        id: windowSystem
    }

    KSvg.FrameSvgItem {
        id : highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    KSvg.FrameSvgItem {
        id : panelSvg

        visible: false

        imagePath: "widgets/panel-background"
    }

    KSvg.FrameSvgItem {
        id : scrollbarSvg

        visible: false

        imagePath: "widgets/scrollbar"
    }

    KSvg.FrameSvgItem {
        id : backgroundSvg

        visible: false

        imagePath: "dialogs/background"
    }

    PC3.Label {
        id: toolTipDelegate

        width: contentWidth
        height: undefined

        property Item toolTip

        text: toolTip ? toolTip.text : ""
        textFormat: Text.PlainText
    }

    function resetDragSource() {
        dragSource = null;
    }

    function enableHideOnWindowDeactivate() {
        kicker.hideOnWindowDeactivate = true;
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: {
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = !kicker.isDash
        }

        windowSystem.focusIn.connect(enableHideOnWindowDeactivate);
        kicker.hideOnWindowDeactivate = true;

        dragHelper.dropped.connect(resetDragSource);
    }
}