add_library(cloakqr_ui STATIC)

target_sources(cloakqr_ui PRIVATE
    qmlbindings.cpp
)

target_include_directories(cloakqr_ui PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/core
    ${CMAKE_SOURCE_DIR}/src/services
)

target_link_libraries(cloakqr_ui PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
)