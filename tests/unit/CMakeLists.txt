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

qt_add_executable(tst_scanhistory
    tst_scanhistory.cpp
)

target_link_libraries(tst_scanhistory PRIVATE
    Qt6::Test
    Qt6::Sql
    cloakqr_services
)

add_test(NAME tst_scanhistory COMMAND tst_scanhistory)