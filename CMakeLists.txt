cmake_minimum_required(VERSION 3.21)
project(CloakQR LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

option(ENABLE_PLAY_BILLING "Enable Google Play Billing integration" OFF)
option(BUILD_CLOAKQR_APP "Build the main CloakQR application target" ON)

set(CLOAKQR_QT_COMPONENTS Core Gui Sql Test)

if(BUILD_CLOAKQR_APP)
    list(APPEND CLOAKQR_QT_COMPONENTS Quick Qml Widgets LinguistTools)
endif()

find_package(Qt6 REQUIRED COMPONENTS ${CLOAKQR_QT_COMPONENTS})

if(BUILD_CLOAKQR_APP)
    qt_policy(SET QTP0001 NEW)
    if(QT_VERSION VERSION_GREATER_EQUAL "6.7.0")
        qt_policy(SET QTP0004 NEW)
    endif()
endif()

include(cmake/dependencies.cmake)

if(ENABLE_PLAY_BILLING AND ANDROID)
    find_package(Qt6 REQUIRED COMPONENTS AndroidExtras)
endif()

include(FetchContent)
FetchContent_Declare(
    zxing
    GIT_REPOSITORY https://github.com/nu-book/zxing-cpp.git
    GIT_TAG v2.0.0
)

# Keep off by default for initial scaffold speed. Enable when implementing decoder.
# FetchContent_MakeAvailable(zxing)

include_directories(thirdparty/tiny-AES-c)

add_subdirectory(src/core)
add_subdirectory(src/services)
if(BUILD_CLOAKQR_APP)
    add_subdirectory(src/ui)
endif()
add_subdirectory(src/platform)
add_subdirectory(src/plugins)
add_subdirectory(src/plugins/stub)
add_subdirectory(src/cli)

enable_testing()

add_subdirectory(tests/unit)

if(BUILD_CLOAKQR_APP)
    qt_add_executable(CloakQR
        src/main.cpp
        resources/qml.qrc
    )

    # Avoid collision with the generated QML module output directory named "CloakQR".
    set_target_properties(CloakQR PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    )

    qt_add_qml_module(CloakQR
        URI CloakQR
        VERSION 1.0
        QML_FILES
            qml/main.qml
            qml/common/Header.qml
            qml/common/Footer.qml
            qml/views/SafePreviewDialog.qml
            qml/views/ScannerPage.qml
            qml/views/HistoryPage.qml
            qml/views/GeneratorPage.qml
            qml/views/DesignStudioPanel.qml
            qml/views/BatchScanPage.qml
            qml/views/PaywallSheet.qml
    )

    target_link_libraries(CloakQR PRIVATE
        Qt6::Quick
        Qt6::Widgets
        Qt6::Sql
        cloakqr_core
        cloakqr_services
        cloakqr_ui
    )

    qt_add_translations(CloakQR
        TS_FILES
            resources/i18n/en.ts
            resources/i18n/es.ts
            resources/i18n/fr.ts
            resources/i18n/ar.ts
    )

    if(ANDROID)
        set_target_properties(CloakQR PROPERTIES
            QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/deploy/android"
        )

        if(ENABLE_PLAY_BILLING)
            target_compile_definitions(CloakQR PRIVATE ENABLE_PLAY_BILLING)
        endif()
    endif()
endif()
