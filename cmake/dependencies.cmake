set(CLOAKQR_ENABLE_VCPKG_DEPENDENCIES OFF CACHE BOOL "Enable optional vcpkg dependency discovery for the public scaffold")

if(CLOAKQR_ENABLE_VCPKG_DEPENDENCIES)
    find_package(libqrencode CONFIG REQUIRED)
    find_package(ZXing CONFIG REQUIRED)
endif()

# System libqrencode (available on Linux CI without vcpkg)
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(QRENCODE QUIET libqrencode)
endif()

if(QRENCODE_FOUND)
    message(STATUS "Found system libqrencode ${QRENCODE_VERSION}")
    set(CLOAKQR_HAVE_LIBQRENCODE ON)
elseif(CLOAKQR_ENABLE_VCPKG_DEPENDENCIES)
    # vcpkg provides the target directly
    set(CLOAKQR_HAVE_LIBQRENCODE ON)
else()
    message(STATUS "libqrencode not found — QrEncoder will use the built-in stub")
    set(CLOAKQR_HAVE_LIBQRENCODE OFF)
endif()
