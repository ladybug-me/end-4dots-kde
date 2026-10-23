#pragma once

#include <qthread.h>
#include <qtimer.h>

#include <atomic>

#include "service.hpp"

namespace caelestia::services {

class TickingService : public Service {
    Q_OBJECT

    Q_PROPERTY(int updateInterval READ updateInterval NOTIFY updateIntervalChanged)

public:
    explicit TickingService(QObject* parent = nullptr);
    ~TickingService() override;

    [[nodiscard]] int updateInterval() const;

signals:
    void updateIntervalChanged();

protected:
    void start() final;
    void stop() final;

    virtual void tick() = 0;

private:
    void applyInterval(int ms);
    static QThread* sharedWorkerThread();

    QTimer* m_workerTimer = nullptr;
    std::atomic<int> m_interval = 1000;
    std::atomic<bool> m_running = false;
};

} // namespace caelestia::services
