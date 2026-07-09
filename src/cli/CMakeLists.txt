add_executable(cloakqr_cli
    main.cpp
)

target_link_libraries(cloakqr_cli PRIVATE
    Qt6::Core
)