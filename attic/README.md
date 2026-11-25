# Attic — kept for reference, not part of the running applet

These files are preserved byte-for-byte (see tiv history) because they
represent real work, but they are **not built, installed or used** by the
current widget.

## Weather bridge plugin (`src/`, `CMakeLists.txt`, `BUILD_PLUGIN.md`)

The plugin talks to a D-Bus service `org.kde.menu11next.weather` that is not
shipped with this package, and no QML file imports `Menu11Next.Weather`.
The working weather card uses Open-Meteo directly in
`contents/ui/WeatherCard.qml`. `BUILD_PLUGIN.md` also contains commands that
are invalid with Qt 6 (`qmlscene -e` / `qml6 -e`).

If you ever want to revive it: restore these files to the repo root, add the
D-Bus service and icon, then import `Menu11Next.Weather 1.0` from QML.

## `superpowers/` planning documents

AI-generated design/planning notes from the weather/plugin work. The shipped
implementation diverged from them, so they are documentation of intent, not
current behavior.

Nothing in this directory is required to install or run Swin-11.
