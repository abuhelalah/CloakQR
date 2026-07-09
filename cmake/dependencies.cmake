set(CLOAKQR_ENABLE_VCPKG_DEPENDENCIES OFF CACHE BOOL "Enable optional vcpkg dependency discovery for the public scaffold")

if(CLOAKQR_ENABLE_VCPKG_DEPENDENCIES)
    find_package(libqrencode CONFIG REQUIRED)
    find_package(ZXing CONFIG REQUIRED)
endif()
