#ifndef WEATHERBRIDGE_H
#define WEATHERBRIDGE_H

#include <QObject>
#include <QDBusInterface>
#include <QDBusConnection>

class WeatherBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double temperature READ temperature NOTIFY temperatureChanged)
    Q_PROPERTY(int weatherCode READ weatherCode NOTIFY weatherCodeChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

public:
    explicit WeatherBridge(QObject *parent = nullptr);
    ~WeatherBridge();

    double temperature() const { return m_temperature; }
    int weatherCode() const { return m_weatherCode; }
    bool available() const { return m_available; }

    Q_INVOKABLE void refresh();

signals:
    void temperatureChanged();
    void weatherCodeChanged();
    void availableChanged();

private slots:
    void onWeatherChanged(double temperature, int code);
    void onDBusError(const QDBusError &error);

private:
    void connectToDBus();
    void updateWeather();

    QDBusInterface *m_interface;
    QDBusConnection m_connection;
    double m_temperature;
    int m_weatherCode;
    bool m_available;
};

#endif // WEATHERBRIDGE_H
