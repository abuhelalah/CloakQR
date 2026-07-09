cmake_minimum_required(VERSION 3.21)
project(CloakQR LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

option(ENABLE_PLAY_BILLING "Enable Google Play Billing integration" OFF)
option(BUILD_CLOAKQR_APP "Build the main CloakQR application target" ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia Widgets Sql Test LinguistTools)

qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

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

if(BUILD_CLOAKQR_APP)
    qt_add_executable(CloakQR
        src/main.cpp
        src/core/qrdecoder.cpp
        src/core/qrgenerator.cpp
        src/services/appengine.cpp
        src/services/fileexporter.cpp
        src/services/cryptohelper.cpp
        src/services/billingbridge.cpp
        src/ui/qmlbindings.cpp
        resources/qml.qrc
    )

    target_include_directories(CloakQR PRIVATE
        ${CMAKE_SOURCE_DIR}/src
        ${CMAKE_SOURCE_DIR}/src/core
        ${CMAKE_SOURCE_DIR}/src/services
        ${CMAKE_SOURCE_DIR}/src/ui
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
        Qt6::Multimedia
        Qt6::Widgets
        Qt6::Sql
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

enable_testing()

qt_add_executable(tst_cryptohelper
    tests/unit/tst_cryptohelper.cpp
    src/services/cryptohelper.cpp
)

target_include_directories(tst_cryptohelper PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/services
)

target_link_libraries(tst_cryptohelper PRIVATE
    Qt6::Core
    Qt6::Test
)

add_test(NAME tst_cryptohelper COMMAND tst_cryptohelper)

qt_add_executable(tst_qrgenerator
    tests/unit/tst_qrgenerator.cpp
    src/core/qrgenerator.cpp
)

target_include_directories(tst_qrgenerator PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/core
)

target_link_libraries(tst_qrgenerator PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
)

add_test(NAME tst_qrgenerator COMMAND tst_qrgenerator)
