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