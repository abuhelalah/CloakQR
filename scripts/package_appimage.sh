#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${ROOT_DIR}/build-release}"
APP_DIR="${APP_DIR:-${BUILD_DIR}/AppDir}"
TOOLS_DIR="${TOOLS_DIR:-${BUILD_DIR}/tools}"
LINUXDEPLOY="${LINUXDEPLOY:-${TOOLS_DIR}/linuxdeploy-x86_64.AppImage}"
QT_PLUGIN="${QT_PLUGIN:-${TOOLS_DIR}/linuxdeploy-plugin-qt-x86_64.AppImage}"
QMAKE_WRAPPER="${ROOT_DIR}/scripts/qmake_appimage_wrapper.sh"
APP_ICON="${BUILD_DIR}/com.abuhelalah.cloakqr.png"

if [[ ! -x "${BUILD_DIR}/bin/cloakqr" ]]; then
    echo "Error: build the Release application before packaging." >&2
    exit 1
fi

mkdir -p "${TOOLS_DIR}"
if [[ ! -x "${LINUXDEPLOY}" ]]; then
    curl --fail --location --output "${LINUXDEPLOY}" \
        https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x "${LINUXDEPLOY}"
fi
if [[ ! -x "${QT_PLUGIN}" ]]; then
    curl --fail --location --output "${QT_PLUGIN}" \
        https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
    chmod +x "${QT_PLUGIN}"
fi

rm -rf "${APP_DIR}"
cp "${ROOT_DIR}/resources/images/Logo_QR_icon.png" "${APP_ICON}"
mkdir -p "${APP_DIR}/usr/share/metainfo"
cp "${ROOT_DIR}/deploy/linux/com.abuhelalah.cloakqr.metainfo.xml" \
    "${APP_DIR}/usr/share/metainfo/"
export REAL_QMAKE="${QMAKE:-$(command -v qmake6 || command -v qmake)}"
QT_PLUGIN_SOURCE="$(${REAL_QMAKE} -query QT_INSTALL_PLUGINS)"
export CLOAKQR_QT_PLUGIN_PATH="${BUILD_DIR}/qt-plugins"
rm -rf "${CLOAKQR_QT_PLUGIN_PATH}"
mkdir -p "${CLOAKQR_QT_PLUGIN_PATH}"
for plugin_type in platforms platforminputcontexts xcbglintegrations sqldrivers imageformats; do
    if [[ -d "${QT_PLUGIN_SOURCE}/${plugin_type}" ]]; then
        mkdir -p "${CLOAKQR_QT_PLUGIN_PATH}/${plugin_type}"
    fi
done
cp "${QT_PLUGIN_SOURCE}/platforms/libqxcb.so" "${CLOAKQR_QT_PLUGIN_PATH}/platforms/"
cp "${QT_PLUGIN_SOURCE}/platforms/libqoffscreen.so" "${CLOAKQR_QT_PLUGIN_PATH}/platforms/"
mkdir -p "${APP_DIR}/usr/plugins/platforms"
cp "${QT_PLUGIN_SOURCE}/platforms/libqoffscreen.so" "${APP_DIR}/usr/plugins/platforms/"
cp "${QT_PLUGIN_SOURCE}/sqldrivers/libqsqlite.so" "${CLOAKQR_QT_PLUGIN_PATH}/sqldrivers/"
cp "${QT_PLUGIN_SOURCE}/imageformats/libqsvg.so" "${CLOAKQR_QT_PLUGIN_PATH}/imageformats/"
for optional_type in platforminputcontexts xcbglintegrations; do
    if [[ -d "${QT_PLUGIN_SOURCE}/${optional_type}" ]]; then
        cp "${QT_PLUGIN_SOURCE}/${optional_type}/"*.so "${CLOAKQR_QT_PLUGIN_PATH}/${optional_type}/"
    fi
done
export LINUXDEPLOY_PLUGIN_QT_QMAKE="${QMAKE_WRAPPER}"
export QMAKE="${QMAKE_WRAPPER}"
export OUTPUT="${OUTPUT:-${BUILD_DIR}/CloakQR-1.0.0-x86_64.AppImage}"
export QML_SOURCES_PATHS="${ROOT_DIR}/qml"

"${LINUXDEPLOY}" --appdir "${APP_DIR}" \
    --executable "${BUILD_DIR}/bin/cloakqr" \
    --deploy-deps-only "${APP_DIR}/usr/plugins/platforms/libqoffscreen.so" \
    --desktop-file "${ROOT_DIR}/deploy/linux/com.abuhelalah.cloakqr.desktop" \
    --icon-file "${APP_ICON}" \
    --custom-apprun "${ROOT_DIR}/deploy/linux/AppRun" \
    --plugin qt \
    --output appimage

echo "AppImage created: ${OUTPUT}"