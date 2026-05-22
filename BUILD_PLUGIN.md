# Building the Weather Bridge Plugin

This plugin bridges D-Bus weather data to QML, enabling dynamic weather display in the weather widget.

## Requirements

- Qt6 (Core, Gui, Qml, DBus modules)
- KDE Frameworks 6 (Plasma)
- CMake 3.16+
- C++17 compiler

## Build Instructions

```bash
mkdir build
cd build
cmake ..
make
sudo make install
```

## Installation

The plugin will be installed to the KDE QML directory (typically `/usr/lib/x86_64-linux-gnu/qt6/qml/Menu11Next/Weather/` on Ubuntu).

## Verify Installation

After building, the weather widget should display dynamic temperature and weather conditions from the D-Bus service.

Check that the plugin loads:
```bash
qmlscene -I /usr/lib/x86_64-linux-gnu/qt6/qml -e "import Menu11Next.Weather 1.0; WeatherBridge { onAvailableChanged: console.log('Available:', available) }"
```

## Troubleshooting

If the plugin doesn't load:

1. Verify the D-Bus service is running:
   ```bash
   systemctl --user status menu11-weather.service
   ```

2. Check plugin installation path:
   ```bash
   find /usr -name "libweatherbridge.so" 2>/dev/null
   ```

3. View QML import paths:
   ```bash
   qmlinfo -plugins
   ```

## Uninstall

```bash
cd build
sudo make uninstall
```
