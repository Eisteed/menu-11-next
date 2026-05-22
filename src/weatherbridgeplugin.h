#ifndef WEATHERBRIDGEPLUGIN_H
#define WEATHERBRIDGEPLUGIN_H

#include <QQmlExtensionPlugin>

class WeatherBridgePlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override;
};

#endif // WEATHERBRIDGEPLUGIN_H
