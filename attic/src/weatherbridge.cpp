#include "weatherbridge.h"
#include <QDBusReply>
#include <QDebug>
#include <QTimer>

WeatherBridge::WeatherBridge(QObject *parent)
    : QObject(parent)
    , m_interface(nullptr)
    , m_connection(QDBusConnection::sessionBus())
    , m_temperature(0.0)
    , m_weatherCode(0)
    , m_available(false)
{
    connectToDBus();

    // Refresh weather every 5 minutes
    QTimer *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &WeatherBridge::refresh);
    timer->start(300000); // 5 minutes

    // Initial update
    QTimer::singleShot(500, this, &WeatherBridge::refresh);
}

WeatherBridge::~WeatherBridge()
{
    delete m_interface;
}

void WeatherBridge::connectToDBus()
{
    m_interface = new QDBusInterface(
        "org.kde.menu11next.weather",
        "/weather",
        "org.kde.menu11next.weather",
        m_connection,
        this
    );

    if (!m_interface->isValid()) {
        qWarning() << "Failed to connect to D-Bus weather service";
        m_available = false;
        emit availableChanged();
        return;
    }

    m_available = true;
    emit availableChanged();

    // Connect to the WeatherChanged signal
    m_connection.connect(
        "org.kde.menu11next.weather",
        "/weather",
        "org.kde.menu11next.weather",
        "WeatherChanged",
        this,
        SLOT(onWeatherChanged(double, int))
    );

    qDebug() << "Connected to D-Bus weather service";
}

void WeatherBridge::refresh()
{
    if (!m_interface || !m_interface->isValid()) {
        connectToDBus();
        return;
    }

    updateWeather();
}

void WeatherBridge::updateWeather()
{
    if (!m_interface) return;

    QDBusReply<double> tempReply = m_interface->call("GetTemperature");
    if (!tempReply.isValid()) {
        qWarning() << "Failed to get temperature:" << tempReply.error().message();
        return;
    }

    QDBusReply<int> codeReply = m_interface->call("GetWeatherCode");
    if (!codeReply.isValid()) {
        qWarning() << "Failed to get weather code:" << codeReply.error().message();
        return;
    }

    if (m_temperature != tempReply.value()) {
        m_temperature = tempReply.value();
        emit temperatureChanged();
    }

    if (m_weatherCode != codeReply.value()) {
        m_weatherCode = codeReply.value();
        emit weatherCodeChanged();
    }
}

void WeatherBridge::onWeatherChanged(double temperature, int code)
{
    qDebug() << "Weather changed:" << temperature << "°C, code:" << code;

    if (m_temperature != temperature) {
        m_temperature = temperature;
        emit temperatureChanged();
    }

    if (m_weatherCode != code) {
        m_weatherCode = code;
        emit weatherCodeChanged();
    }
}

void WeatherBridge::onDBusError(const QDBusError &error)
{
    qWarning() << "D-Bus error:" << error.message();
}
