cmake_minimum_required(VERSION 3.16)

project(AthleteManager VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Positioning Location Sql OpenGL Bluetooth)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appAthleteManager
    main.cpp
)

qt_add_qml_module(appAthleteManager
    URI AthleteManager
    VERSION 1.0
    QML_FILES
        Main.qml
        RESOURCES android/AndroidManifest.xml android/build.gradle android/res/values/libs.xml android/res/xml/qtprovider_paths.xml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appAthleteManager PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appAthleteManager
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appAthleteManager PRIVATE
    Qt6::Quick
    Qt6::Location
    Qt6::Positioning
    Qt6::Sql
    Qt6::OpenGL
	Qt6::Bluetooth
)

include(GNUInstallDirs)
install(TARGETS appAthleteManager
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
