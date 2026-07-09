add_library(cloakqr_core STATIC)

target_sources(cloakqr_core PRIVATE
    qrdecoder.cpp
    qrgenerator.cpp
)

target_include_directories(cloakqr_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(cloakqr_core PUBLIC
    Qt6::Core
    Qt6::Gui
)