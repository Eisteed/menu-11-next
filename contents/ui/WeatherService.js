// Weather Service - reads from D-Bus weather service

// Open-Meteo uses the WMO weather interpretation codes.
// Keep icon and description in sync with the same ranges.
function getWeatherIcon(code) {
    code = parseInt(code);
    if (code === 0) return "weather-clear";
    if (code <= 2) return "weather-few-clouds";
    if (code === 3) return "weather-overcast";
    if (code === 45 || code === 48) return "weather-fog";
    if (code >= 51 && code <= 57) return "weather-showers-scattered";
    if (code >= 61 && code <= 67) return "weather-rain";
    if (code >= 71 && code <= 77) return "weather-snow";
    if (code >= 80 && code <= 82) return "weather-showers";
    if (code >= 85 && code <= 86) return "weather-snow";
    if (code >= 95) return "weather-storm";
    return "weather-clouds";
}

function getWeatherDescription(code) {
    code = parseInt(code);
    if (code === 0) return "Clear";
    if (code <= 2) return "Partly cloudy";
    if (code === 3) return "Overcast";
    if (code === 45 || code === 48) return "Fog";
    if (code >= 51 && code <= 57) return "Drizzle";
    if (code >= 61 && code <= 67) return "Rain";
    if (code >= 71 && code <= 77) return "Snow";
    if (code >= 80 && code <= 82) return "Rain showers";
    if (code >= 85 && code <= 86) return "Snow showers";
    if (code >= 95) return "Thunderstorm";
    return "Unknown";
}
