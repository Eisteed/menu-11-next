#include "weatherbridgeplugin.h"
#include "weatherbridge.h"
#include <qqml.h>

void WeatherBridgePlugin::registerTypes(const char *uri)
{
    qmlRegisterType<WeatherBridge>(uri, 1, 0, "WeatherBridge");
}
