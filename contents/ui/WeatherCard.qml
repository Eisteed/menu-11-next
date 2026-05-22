import QtQuick
import QtCore
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "WeatherService.js" as Weather

Rectangle {
    id: weatherCard

    visible: Plasmoid.configuration.showWeather === true
    height: visible ? 60 : 0
    width: parent.width
    color: Kirigami.Theme.backgroundColor
    radius: 4
    border.color: Kirigami.Theme.textColor
    border.width: 1

    property string temperature: "Loading..."
    property string condition: "Loading..."
    property string weatherIcon: "weather-clouds"

    Timer {
        id: weatherUpdateTimer
        interval: 600000
        running: true
        repeat: true
        onTriggered: {
            weatherCard.fetchWeatherFromAPI();
        }
    }


    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        Kirigami.Icon {
            source: weatherCard.weatherIcon
            implicitWidth: 40
            implicitHeight: 40
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            PlasmaComponents.Label {
                text: weatherCard.temperature
                font.pixelSize: 18
                font.bold: true
            }

            PlasmaComponents.Label {
                text: weatherCard.condition
                font.pixelSize: 12
                opacity: 0.7
            }
        }
    }

    function getWeatherIcon(code) {
        return Weather.getWeatherIcon(code);
    }

    function getWeatherDescription(code) {
        return Weather.getWeatherDescription(code);
    }


    function fetchWeatherFromAPI() {
        var xhr = new XMLHttpRequest();
        var lat = Plasmoid.configuration.weatherLatitude || 48.8566;
        var lon = Plasmoid.configuration.weatherLongitude || 2.3522;
        var apiUrl = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,weather_code&timezone=auto";

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        var current = data.current;

                        weatherCard.temperature = Math.round(current.temperature_2m) + "°C";
                        weatherCard.condition = weatherCard.getWeatherDescription(current.weather_code);
                        weatherCard.weatherIcon = weatherCard.getWeatherIcon(current.weather_code);

                        console.log("[Weather] Updated: " + weatherCard.temperature + ", " + weatherCard.condition);
                    } catch (e) {
                        console.error("[Weather] JSON parse error: " + e);
                        weatherCard.temperature = "Error";
                        weatherCard.condition = "Parse failed";
                    }
                } else {
                    console.error("[Weather] API request failed with status: " + xhr.status);
                    weatherCard.temperature = "Error";
                    weatherCard.condition = "Network error";
                }
            }
        };

        xhr.onerror = function() {
            console.error("[Weather] Network error");
            weatherCard.temperature = "Error";
            weatherCard.condition = "Network error";
        };

        xhr.open("GET", apiUrl, true);
        xhr.send();
    }

    Component.onCompleted: {
        fetchWeatherFromAPI();
    }

}
