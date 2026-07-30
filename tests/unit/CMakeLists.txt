qt_add_executable(tst_cryptohelper
    tst_cryptohelper.cpp
)

target_link_libraries(tst_cryptohelper PRIVATE
    Qt6::Test
    cloakqr_services
)

add_test(NAME tst_cryptohelper COMMAND tst_cryptohelper)

qt_add_executable(tst_qrgenerator
    tst_qrgenerator.cpp
)

target_link_libraries(tst_qrgenerator PRIVATE
    Qt6::Test
    cloakqr_core
)

add_test(NAME tst_qrgenerator COMMAND tst_qrgenerator)

qt_add_executable(tst_qrdecoder
    tst_qrdecoder.cpp
)

target_link_libraries(tst_qrdecoder PRIVATE
    Qt6::Test
    cloakqr_core
)

add_test(NAME tst_qrdecoder COMMAND tst_qrdecoder)

qt_add_executable(tst_scanhistory
    tst_scanhistory.cpp
)

target_link_libraries(tst_scanhistory PRIVATE
    Qt6::Test
    Qt6::Sql
    cloakqr_services
)

add_test(NAME tst_scanhistory COMMAND tst_scanhistory)

qt_add_executable(tst_settings
    tst_settings.cpp
)

target_link_libraries(tst_settings PRIVATE
    Qt6::Test
    Qt6::Gui
    cloakqr_services
)

add_test(NAME tst_settings COMMAND tst_settings)

qt_add_executable(tst_appengine
    tst_appengine.cpp
)

target_link_libraries(tst_appengine PRIVATE
    Qt6::Test
    cloakqr_services
)

add_test(NAME tst_appengine COMMAND tst_appengine)
set_tests_properties(tst_appengine PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
)

if(TARGET cloakqr_paid)
    qt_add_executable(tst_batchgenerator
        ${CMAKE_SOURCE_DIR}/src/paid/tst_batchgenerator.cpp
    )

    target_link_libraries(tst_batchgenerator PRIVATE
        Qt6::Test
        cloakqr_paid
    )

    add_test(NAME tst_batchgenerator COMMAND tst_batchgenerator)
    set_tests_properties(tst_batchgenerator PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
        TIMEOUT 20
    )

    qt_add_executable(tst_logooverlay
        ${CMAKE_SOURCE_DIR}/src/paid/tst_logooverlay.cpp
    )

    target_link_libraries(tst_logooverlay PRIVATE
        Qt6::Test
        cloakqr_paid
    )

    add_test(NAME tst_logooverlay COMMAND tst_logooverlay)
    set_tests_properties(tst_logooverlay PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
        TIMEOUT 10
    )
endif()

qt_add_executable(tst_cli
    tst_cli.cpp
)

target_link_libraries(tst_cli PRIVATE
    Qt6::Test
    Qt6::Gui
)

target_compile_definitions(tst_cli PRIVATE
    CLOAKQR_CLI_EXECUTABLE="$<TARGET_FILE:cloakqr_cli>"
)

add_test(NAME tst_cli COMMAND tst_cli)

if(BUILD_CLOAKQR_APP)
    qt_add_executable(tst_releaseassets
        tst_releaseassets.cpp
    )

    target_link_libraries(tst_releaseassets PRIVATE
        Qt6::Test
        Qt6::Gui
    )

    target_compile_definitions(tst_releaseassets PRIVATE
        CLOAKQR_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
        CLOAKQR_LRELEASE_EXECUTABLE="$<TARGET_FILE:Qt6::lrelease>"
    )

    add_test(NAME tst_releaseassets COMMAND tst_releaseassets)

    qt_add_executable(tst_appsmoke
        tst_appsmoke.cpp
    )

    target_link_libraries(tst_appsmoke PRIVATE
        Qt6::Test
        Qt6::Core
    )

    target_compile_definitions(tst_appsmoke PRIVATE
        CLOAKQR_APP_EXECUTABLE="$<TARGET_FILE:CloakQR>"
    )

    add_test(NAME tst_appsmoke COMMAND tst_appsmoke)
    set_tests_properties(tst_appsmoke PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software"
        TIMEOUT 20
    )
endif()