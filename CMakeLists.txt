cmake_minimum_required(VERSION 3.21)
project(CloakQR VERSION 1.0.0 LANGUAGES CXX)

include(GNUInstallDirs)

if(WIN32)
    # Ship MSVC/UCRT runtime DLLs with the installer so it runs on clean VMs.
    set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION ${CMAKE_INSTALL_BINDIR})
    set(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)
    include(InstallRequiredSystemLibraries)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

option(BUILD_CLOAKQR_APP "Build the main CloakQR application target" ON)
set(CLOAKQR_EDITION "FREE" CACHE STRING "Application edition: FREE or PAID")
set_property(CACHE CLOAKQR_EDITION PROPERTY STRINGS FREE PAID)
string(TOUPPER "${CLOAKQR_EDITION}" CLOAKQR_EDITION)

if(NOT CLOAKQR_EDITION STREQUAL "FREE" AND NOT CLOAKQR_EDITION STREQUAL "PAID")
    message(FATAL_ERROR "CLOAKQR_EDITION must be FREE or PAID")
endif()

if(CLOAKQR_EDITION STREQUAL "PAID")
    set(CLOAKQR_PAID_EDITION ON)
    set(CLOAKQR_PRODUCT_NAME "CloakQR Pro")
    set(CLOAKQR_ANDROID_PACKAGE_NAME "com.abuhelalah.cloakqr.pro")
else()
    set(CLOAKQR_PAID_EDITION OFF)
    set(CLOAKQR_PRODUCT_NAME "CloakQR")
    set(CLOAKQR_ANDROID_PACKAGE_NAME "com.abuhelalah.cloakqr")
endif()

if(CLOAKQR_PAID_EDITION AND BUILD_CLOAKQR_APP AND NOT ANDROID)
    message(FATAL_ERROR "The PAID edition is currently supported only on Android")
endif()

configure_file(
    cmake/cloakqr_version.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/generated/cloakqr_version.h
    @ONLY
)

set(CLOAKQR_QT_COMPONENTS Core Gui Sql Test Concurrent Multimedia)

if(BUILD_CLOAKQR_APP)
    list(APPEND CLOAKQR_QT_COMPONENTS Quick Qml QuickControls2 Widgets LinguistTools)
endif()

find_package(Qt6 REQUIRED COMPONENTS ${CLOAKQR_QT_COMPONENTS})

if(BUILD_CLOAKQR_APP)
    qt_policy(SET QTP0001 NEW)
    qt_policy(SET QTP0002 NEW)
    qt_policy(SET QTP0004 NEW)
endif()

include(cmake/dependencies.cmake)

include(FetchContent)
FetchContent_Declare(
    zxing
    GIT_REPOSITORY https://github.com/nu-book/zxing-cpp.git
    GIT_TAG v2.0.0
)

set(BUILD_READERS ON CACHE BOOL "Build ZXing readers" FORCE)
set(BUILD_WRITERS OFF CACHE BOOL "Build ZXing writers" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "Build ZXing examples" FORCE)
set(BUILD_BLACKBOX_TESTS OFF CACHE BOOL "Build ZXing black-box tests" FORCE)
set(BUILD_UNIT_TESTS OFF CACHE BOOL "Build ZXing unit tests" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build dependencies as static libraries" FORCE)
FetchContent_MakeAvailable(zxing)

include_directories(thirdparty/tiny-AES-c)

add_subdirectory(src/core)
add_subdirectory(src/services)
if(BUILD_CLOAKQR_APP)
    add_subdirectory(src/ui)
endif()
add_subdirectory(src/platform)
add_subdirectory(src/plugins)
add_subdirectory(src/plugins/stub)
if(CLOAKQR_PAID_EDITION)
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/src/paid/CMakeLists.txt")
        message(FATAL_ERROR "PAID edition source is missing from src/paid")
    endif()
    add_subdirectory(src/paid)
endif()
add_subdirectory(src/cli)

include(CTest)
if(BUILD_TESTING)
    add_subdirectory(tests/unit)
endif()

if(BUILD_CLOAKQR_APP)
    qt_add_executable(CloakQR
        src/main.cpp
    )

    set_target_properties(CloakQR PROPERTIES
        OUTPUT_NAME "cloakqr"
        WIN32_EXECUTABLE TRUE
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "CloakQR"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.abuhelalah.cloakqr"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
    )

    qt_add_resources(CloakQR cloakqr_images
        PREFIX "/images"
        BASE "${CMAKE_CURRENT_SOURCE_DIR}/resources/images"
        FILES
            resources/images/Logo_QR_icon.png
    )

    set(CLOAKQR_QML_FILES
            qml/main.qml
            qml/common/Header.qml
            qml/common/Footer.qml
            qml/common/FilePickerDialog.qml
            qml/views/SafePreviewDialog.qml
            qml/views/ScannerPage.qml
            qml/views/HistoryPage.qml
            qml/views/GeneratorPage.qml
            qml/views/SettingsPage.qml
            qml/views/AboutPage.qml
            qml/views/BatchScanPage.qml
    )

    if(CLOAKQR_PAID_EDITION)
        set(CLOAKQR_PAID_DESIGN_QML "${CMAKE_SOURCE_DIR}/src/paid/qml/DesignStudioPanel.qml")
        set(CLOAKQR_PAID_BATCH_QML "${CMAKE_SOURCE_DIR}/src/paid/qml/BatchStudioPanel.qml")
        set_source_files_properties("${CLOAKQR_PAID_DESIGN_QML}" PROPERTIES
            QT_RESOURCE_ALIAS "qml/views/DesignStudioPanel.qml"
        )
        set_source_files_properties("${CLOAKQR_PAID_BATCH_QML}" PROPERTIES
            QT_RESOURCE_ALIAS "qml/views/BatchStudioPanel.qml"
        )
        list(APPEND CLOAKQR_QML_FILES
            "${CLOAKQR_PAID_DESIGN_QML}"
            "${CLOAKQR_PAID_BATCH_QML}"
        )
    endif()

    qt_add_qml_module(CloakQR
        URI CloakQR
        VERSION 1.0
        QML_FILES ${CLOAKQR_QML_FILES}
    )

    target_link_libraries(CloakQR PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Widgets
        Qt6::Sql
        cloakqr_core
        cloakqr_services
        cloakqr_ui
        cloakqr_platform
    )

    if(CLOAKQR_PAID_EDITION)
        target_link_libraries(CloakQR PRIVATE cloakqr_paid)
    endif()

    target_include_directories(CloakQR PRIVATE
        ${CMAKE_CURRENT_BINARY_DIR}/generated
    )

    # The QML module places its generated content in a "CloakQR" directory under
    # the build root, so route the executable to a separate bin/ folder to avoid
    # a name collision with that directory.
    set_target_properties(CloakQR PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    )

    if(WIN32)
        target_sources(CloakQR PRIVATE deploy/windows/cloakqr.rc)
    endif()

    qt_add_translations(CloakQR
        TS_FILES
            resources/i18n/en.ts
            resources/i18n/es.ts
            resources/i18n/fr.ts
            resources/i18n/ar.ts
        RESOURCE_PREFIX "/i18n"
    )

    if(ANDROID)
        set_target_properties(CloakQR PROPERTIES
            QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/deploy/android"
            QT_ANDROID_PACKAGE_NAME "${CLOAKQR_ANDROID_PACKAGE_NAME}"
            QT_ANDROID_APP_NAME "${CLOAKQR_PRODUCT_NAME}"
            QT_ANDROID_VERSION_CODE 10000
            QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}"
            QT_ANDROID_COMPILE_SDK_VERSION 36
        )
    endif()

    install(TARGETS CloakQR
        BUNDLE DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )

    if(LINUX AND NOT ANDROID)
        install(FILES deploy/linux/com.abuhelalah.cloakqr.desktop
            DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
        install(FILES deploy/linux/com.abuhelalah.cloakqr.metainfo.xml
            DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
        install(FILES resources/images/Logo_QR_icon.png
            DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/1024x1024/apps
            RENAME com.abuhelalah.cloakqr.png)
    endif()

    if(NOT ANDROID)
        qt_generate_deploy_app_script(
            TARGET CloakQR
            OUTPUT_SCRIPT cloakqr_deploy_script
            NO_UNSUPPORTED_PLATFORM_ERROR
        )
        install(SCRIPT ${cloakqr_deploy_script})
    endif()
endif()

install(TARGETS cloakqr_cli
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

target_include_directories(cloakqr_cli PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/generated
)

set(CPACK_PACKAGE_NAME "CloakQR")
set(CPACK_PACKAGE_VENDOR "CloakQR")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Offline, privacy-first QR scanner and generator")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/abuhelalah/CloakQR")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "CloakQR")
set(CPACK_NSIS_DISPLAY_NAME "CloakQR")
set(CPACK_NSIS_PACKAGE_NAME "CloakQR")
set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/deploy/windows/cloakqr.ico")
set(CPACK_NSIS_MUI_UNIICON "${CMAKE_SOURCE_DIR}/deploy/windows/cloakqr.ico")
set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
set(CPACK_NSIS_MODIFY_PATH ON)
set(CPACK_PACKAGE_EXECUTABLES "cloakqr" "CloakQR")
set(CPACK_CREATE_DESKTOP_LINKS "cloakqr")
set(CPACK_GENERATOR "TGZ")
if(WIN32)
    set(CPACK_NSIS_EXECUTABLES_DIRECTORY "bin")
    set(CPACK_NSIS_INSTALLED_ICON_NAME "bin\\cloakqr.exe")
    set(CPACK_GENERATOR "NSIS;ZIP")
endif()
include(CPack)
