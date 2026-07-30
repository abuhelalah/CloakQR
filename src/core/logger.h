#pragma once

#include <QLoggingCategory>

// Shared logging categories for CloakQR. Declared in the base (core) layer so
// every module can log through a consistent, filterable category. Categories
// follow the "cloakqr.<layer>" naming convention and can be toggled at runtime
// via the QT_LOGGING_RULES environment variable.
Q_DECLARE_LOGGING_CATEGORY(cloakqrCore)
Q_DECLARE_LOGGING_CATEGORY(cloakqrServices)
Q_DECLARE_LOGGING_CATEGORY(cloakqrUi)
Q_DECLARE_LOGGING_CATEGORY(cloakqrPlatform)
Q_DECLARE_LOGGING_CATEGORY(cloakqrPlugins)
