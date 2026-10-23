#include "tickingservice.hpp"

#include <qcoreapplication.h>

#include "../Config/dashboardconfig.hpp"
#include "../Config/rootnodes.hpp"

namespace caelestia::services {

QThread* TickingService::sharedWorkerThread() {
    static auto* thread = [] {
        auto* t = new QThread();
        t->setObjectName(QStringLiteral("caelestia:ticking"));
        t->start(QThread::LowPriority);
        if (qApp) {
            QObject::connect(qApp, &QCoreApplication::aboutToQuit, t, [t] {
                t->quit();
                t->wait(1000);
            });
        }
        return t;
    }();
    return thread;
}

TickingService::TickingService(QObject* parent)
    : Service(parent) {
    auto* dash = caelestia::config::ConfigSingleton::instance()->dashboard();
    applyInterval(dash->resourceUpdateInterval());
    QObject::connect(dash, &caelestia::config::DashboardConfig::resourceUpdateIntervalChanged, this, [this, dash] {
        applyInterval(dash->resourceUpdateInterval());
    });
}

TickingService::~TickingService() {
    m_running = false;
    if (sharedWorkerThread()->isRunning()) {
        QMetaObject::invokeMethod(
            sharedWorkerThread(),
            [this] {
                if (m_workerTimer) {
                    delete m_workerTimer;
                    m_workerTimer = nullptr;
                }
            },
            Qt::BlockingQueuedConnection);
    }
}

int TickingService::updateInterval() const {
    return m_interval.load();
}

void TickingService::start() {
    m_running = true;
    QMetaObject::invokeMethod(
        sharedWorkerThread(),
        [this] {
            if (!m_running) {
                return;
            }
            if (!m_workerTimer) {
                m_workerTimer = new QTimer();
                m_workerTimer->setSingleShot(false);
                QObject::connect(m_workerTimer, &QTimer::timeout, [this] {
                    if (m_running) {
                        tick();
                    }
                });
            }
            tick();
            const int ms = m_interval.load();
            if (ms > 0) {
                m_workerTimer->start(ms);
            }
        },
        Qt::QueuedConnection);
}

void TickingService::stop() {
    m_running = false;
    QMetaObject::invokeMethod(
        sharedWorkerThread(),
        [this] {
            if (m_workerTimer) {
                m_workerTimer->stop();
            }
        },
        Qt::QueuedConnection);
}

void TickingService::applyInterval(int ms) {
    if (ms <= 0 || ms == m_interval.load()) {
        return;
    }
    m_interval.store(ms);
    QMetaObject::invokeMethod(
        sharedWorkerThread(),
        [this, ms] {
            if (m_running && m_workerTimer) {
                m_workerTimer->start(ms);
            }
        },
        Qt::QueuedConnection);
    Q_EMIT updateIntervalChanged();
}

} // namespace caelestia::services
