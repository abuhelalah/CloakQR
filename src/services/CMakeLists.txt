add_library(cloakqr_services STATIC)

target_sources(cloakqr_services PRIVATE
    appengine.cpp
    billingbridge.cpp
    cryptohelper.cpp
    fileexporter.cpp
    scanhistorymodel.cpp
)

target_include_directories(cloakqr_services PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(cloakqr_services PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Sql
)