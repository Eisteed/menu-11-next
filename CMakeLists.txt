cmake_minimum_required(VERSION 3.16)
project(Menu11NextWeatherPlugin)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 COMPONENTS Core Qml DBus REQUIRED)

set(WEATHER_PLUGIN_SOURCES
    src/weatherbridge.h
    src/weatherbridge.cpp
    src/weatherbridgeplugin.h
    src/weatherbridgeplugin.cpp
)

add_library(weatherbridge MODULE ${WEATHER_PLUGIN_SOURCES})

target_link_libraries(weatherbridge
    Qt6::Core
    Qt6::Qml
    Qt6::DBus
)

# Install to Qt6 QML directory
get_target_property(QT_QMAKE_EXECUTABLE Qt6::qmake IMPORTED_LOCATION)
execute_process(COMMAND ${QT_QMAKE_EXECUTABLE} -query QT_INSTALL_QML
    OUTPUT_VARIABLE QT_QML_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE)

install(TARGETS weatherbridge
    DESTINATION ${QT_QML_DIR}/Menu11Next/Weather)

install(FILES src/qmldir
    DESTINATION ${QT_QML_DIR}/Menu11Next/Weather)
