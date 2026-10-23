#include "common.hpp"

#include <qstandardpaths.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcConfig, "caelestia.config", QtInfoMsg)

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/caelestia"_s;
}

QString configFile(const QString& name) {
    return configDir() + QLatin1Char('/') + name;
}

QString monitorConfigDir() {
    return configDir() + u"/monitors"_s;
}

} // namespace caelestia::config
