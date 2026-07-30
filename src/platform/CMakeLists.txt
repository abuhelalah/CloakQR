add_library(cloakqr_platform STATIC)

target_sources(cloakqr_platform PRIVATE
    platformbridge.cpp
)

target_include_directories(cloakqr_platform PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(cloakqr_platform PUBLIC
    Qt6::Core
)
