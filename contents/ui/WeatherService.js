// Weather Service - reads from D-Bus weather service

function getWeatherIcon(code) {
    code = parseInt(code);
    if (code < 3) return "weather-few-clouds";
    if (code < 50) return "weather-overcast";
    if (code < 70) return "weather-rain";
    if (code < 85) return "weather-snow";
    return "weather-thunderstorm";
}

function getWeatherDescription(code) {
    code = parseInt(code);
    if (code < 3) return "Clear";
    if (code < 5) return "Cloudy";
    if (code < 50) return "Fog";
    if (code < 70) return "Rainy";
    if (code < 85) return "Snow";
    return "Storm";
}

function readWeatherFile(callback) {
    // Reads weather data from D-Bus service
    console.log("[WeatherService] Attempting to read from D-Bus...");
    callback({
        temperature: "Loading...",
        condition: "Loading...",
        icon: "weather-clouds",
        success: false,
        useDBus: true
    });
}
