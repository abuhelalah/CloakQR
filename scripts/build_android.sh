#!/usr/bin/env bash
# Build (and optionally install) a CloakQR Android debug APK for arm64-v8a.
#
# Usage:
#   scripts/build_android.sh                    # build the free APK
#   scripts/build_android.sh --paid             # build the separately sold paid APK
#   scripts/build_android.sh --paid --install   # build, install, and launch paid APK
#
# Requirements: the Qt 6.11.1 Android arm64 kit, the Qt-bundled SDK/NDK and a
# full JDK (17). The host Qt libs must be on LD_LIBRARY_PATH so the code
# generators (qmlimportscanner, moc, rcc) resolve against Qt 6.11 rather than any
# system Qt.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EDITION="FREE"
INSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --free)
            EDITION="FREE"
            ;;
        --paid)
            EDITION="PAID"
            ;;
        --install)
            INSTALL=true
            ;;
        *)
            echo "Error: unknown argument: $1" >&2
            echo "Usage: $0 [--free|--paid] [--install]" >&2
            exit 2
            ;;
    esac
    shift
done

if [[ "${EDITION}" == "PAID" ]]; then
    BUILD_DIR="${ROOT_DIR}/build-android-paid"
    PACKAGE_NAME="com.abuhelalah.cloakqr.pro"
    APP_NAME="CloakQR Pro"
else
    BUILD_DIR="${ROOT_DIR}/build-android"
    PACKAGE_NAME="com.abuhelalah.cloakqr"
    APP_NAME="CloakQR"
fi

QT_HOST_PREFIX="/opt/Qt/6.11.1/gcc_64"
QT_ANDROID_PREFIX="/opt/Qt/6.11.1/android_arm64_v8a"
ANDROID_SDK_ROOT="/opt/Qt/Android"
ANDROID_NDK_ROOT="${ANDROID_SDK_ROOT}/ndk/27.2.12479018"
ANDROID_ABI="arm64-v8a"
PLATFORM_TOOLS="${ANDROID_SDK_ROOT}/platform-tools"

FORBIDDEN_PERMISSIONS=(
    android.permission.INTERNET
    android.permission.ACCESS_NETWORK_STATE
    android.permission.BLUETOOTH
    android.permission.MODIFY_AUDIO_SETTINGS
    android.permission.RECORD_AUDIO
    android.permission.WRITE_EXTERNAL_STORAGE
)

export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export ANDROID_SDK_ROOT ANDROID_NDK_ROOT
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Djava.io.tmpdir=${TMPDIR:-${BUILD_DIR}/tmp}"
# Host Qt libraries first so the build-time code generators load Qt 6.11.
export LD_LIBRARY_PATH="${QT_HOST_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export PATH="${JAVA_HOME}/bin:${PLATFORM_TOOLS}:${PATH}"

for req in "${QT_ANDROID_PREFIX}/bin/qt-cmake" "${ANDROID_SDK_ROOT}" \
           "${ANDROID_NDK_ROOT}" "${JAVA_HOME}/bin/javac"; do
    if [[ ! -e "${req}" ]]; then
        echo "Error: required component not found: ${req}" >&2
        exit 1
    fi
done

echo "==> Configuring ${APP_NAME} (${ANDROID_ABI})"
rm -rf "${BUILD_DIR}"
mkdir -p "${TMPDIR:-${BUILD_DIR}/tmp}"
"${QT_ANDROID_PREFIX}/bin/qt-cmake" -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
    -DBUILD_CLOAKQR_APP=ON \
    -DBUILD_TESTING=OFF \
    -DCLOAKQR_EDITION="${EDITION}" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}" \
    -DANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}" \
    -DQT_ANDROID_ABIS="${ANDROID_ABI}"

echo "==> Cross-compiling native libraries"
cmake --build "${BUILD_DIR}" --target CloakQR -j"$(nproc)"

echo "==> Packaging the APK"
# Build only the app's APK (avoids packaging the unit-test executables).
cmake --build "${BUILD_DIR}" --target CloakQR_make_apk

APK="${BUILD_DIR}/android-build/build/outputs/apk/debug/android-build-debug.apk"
AAPT2="$(find "${ANDROID_SDK_ROOT}/build-tools" -type f -name aapt2 -print | sort -V | tail -n 1)"
if [[ ! -x "${AAPT2}" ]]; then
    echo "Error: aapt2 was not found under ${ANDROID_SDK_ROOT}/build-tools" >&2
    exit 1
fi

APK_PERMISSIONS="$("${AAPT2}" dump permissions "${APK}")"
APK_BADGING="$("${AAPT2}" dump badging "${APK}")"
if ! grep -Fq "package: name='${PACKAGE_NAME}'" <<<"${APK_BADGING}"; then
    echo "Error: packaged APK does not use expected package: ${PACKAGE_NAME}" >&2
    exit 1
fi

if ! grep -Fq "application-label:'${APP_NAME}'" <<<"${APK_BADGING}"; then
    echo "Error: packaged APK does not use expected app name: ${APP_NAME}" >&2
    exit 1
fi

if ! grep -Fq "android.permission.CAMERA" <<<"${APK_PERMISSIONS}"; then
    echo "Error: packaged APK is missing camera permission" >&2
    exit 1
fi

for permission in "${FORBIDDEN_PERMISSIONS[@]}"; do
    if grep -Fq "${permission}" <<<"${APK_PERMISSIONS}"; then
        echo "Error: packaged APK contains forbidden permission: ${permission}" >&2
        exit 1
    fi
done

echo
echo "${APP_NAME} Android debug APK build complete:"
echo "  ${APK}"

if ${INSTALL}; then
    echo "==> Installing on connected device"
    adb install -r "${APK}"
    adb shell monkey -p "${PACKAGE_NAME}" -c android.intent.category.LAUNCHER 1 >/dev/null
    echo "Launched ${PACKAGE_NAME}"
else
    echo "Install with: adb install -r ${APK}"
fi
