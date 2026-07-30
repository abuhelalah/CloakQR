#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-query" && -z "${2:-}" ]]; then
    "${REAL_QMAKE}" -query | sed \
        "s|^QT_INSTALL_PLUGINS:.*|QT_INSTALL_PLUGINS:${CLOAKQR_QT_PLUGIN_PATH}|"
elif [[ "${1:-}" == "-query" && "${2:-}" == "QT_INSTALL_PLUGINS" ]]; then
    printf '%s\n' "${CLOAKQR_QT_PLUGIN_PATH}"
else
    exec "${REAL_QMAKE}" "$@"
fi