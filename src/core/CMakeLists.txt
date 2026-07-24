add_library(cloakqr_core STATIC)

target_sources(cloakqr_core PRIVATE
    logger.cpp
    qrdata.cpp
    qrdecoder.cpp
    qrencoder.cpp
    qrgenerator.cpp
)

target_include_directories(cloakqr_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(cloakqr_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Concurrent
)

if(CLOAKQR_HAVE_LIBQRENCODE)
    target_compile_definitions(cloakqr_core PUBLIC HAVE_LIBQRENCODE)
    if(QRENCODE_FOUND)
        target_include_directories(cloakqr_core PRIVATE ${QRENCODE_INCLUDE_DIRS})
        target_link_libraries(cloakqr_core PRIVATE ${QRENCODE_LIBRARIES})
    else()
        # vcpkg target
        target_link_libraries(cloakqr_core PRIVATE qrencode)
    endif()
endif()