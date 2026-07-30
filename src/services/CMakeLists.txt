add_library(cloakqr_services STATIC)

target_sources(cloakqr_services PRIVATE
    appengine.cpp
    cryptohelper.cpp
    fileexporter.cpp
    scanhistorymodel.cpp
    settings.cpp
)

target_include_directories(cloakqr_services PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_BINARY_DIR}/generated
)

if(CLOAKQR_PAID_EDITION)
    target_compile_definitions(cloakqr_services PUBLIC CLOAKQR_PAID_EDITION=1)
else()
    target_compile_definitions(cloakqr_services PUBLIC CLOAKQR_PAID_EDITION=0)
endif()

target_link_libraries(cloakqr_services PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Sql
)