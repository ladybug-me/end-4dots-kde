// SPDX-License-Identifier: GPL-3.0-only
#include "pipewirestreamwatcher.hpp"

#include <pipewire/pipewire.h>
#include <spa/utils/result.h>

#include <QHash>
#include <QLoggingCategory>
#include <QMetaObject>
#include <QMutex>
#include <QMutexLocker>
#include <QTimer>

Q_LOGGING_CATEGORY(lcPipewireStreamWatcher, "caelestia.services.pipewirestreamwatcher", QtInfoMsg)

namespace caelestia::services {

namespace {

bool isStreamingNode(const char* mediaClass, const char* nodeName, const char* mediaName, const char* mediaRole) {
    if (!mediaClass) {
        return false;
    }

    if (strcmp(mediaClass, "Stream/Input/Video") == 0) {
        // Exclude internal quickshell / caelestia-shell previews and KDE screencast helpers
        if (nodeName && (strcmp(nodeName, "quickshell") == 0 || strcmp(nodeName, "caelestia-shell") == 0)) {
            return false;
        }
        if (mediaName && strncmp(mediaName, "plasma-screencast-", 18) == 0) {
            return false;
        }
        return true;
    }

    if (strcmp(mediaClass, "Video/Source") == 0) {
        // Exclude hardware webcams and V4L2 devices
        if (mediaRole && strcmp(mediaRole, "Camera") == 0) {
            return false;
        }
        if (nodeName && strncmp(nodeName, "v4l2_input", 10) == 0) {
            return false;
        }
        return true;
    }

    return false;
}

} // namespace

struct TrackedNode {
    QString mediaClass;
    QString nodeName;
    QString mediaName;
    QString mediaRole;
    bool isStreaming = false;
};

class PipewireStreamWatcherPrivate {
public:
    explicit PipewireStreamWatcherPrivate(PipewireStreamWatcher* parent)
        : q(parent) {}

    PipewireStreamWatcher* q = nullptr;
    pw_thread_loop* threadLoop = nullptr;
    pw_context* context = nullptr;
    pw_core* core = nullptr;
    pw_registry* registry = nullptr;
    spa_hook registryListener{};
    spa_hook coreListener{};
    QTimer* reconnectTimer = nullptr;

    mutable QMutex mutex;
    QHash<uint32_t, TrackedNode> trackedNodes;

    bool m_streaming = false;
    int m_streamCount = 0;
    QStringList m_activeStreams;

    void init();
    void cleanup();
    void tryConnect();
    void scheduleReconnect();
    void notifyStateChangedFromThread();
    void updateState(bool streaming, int count, const QStringList& streams);

    static void onGlobal(
        void* data, uint32_t id, uint32_t permissions, const char* type, uint32_t version, const spa_dict* props);
    static void onGlobalRemove(void* data, uint32_t id);
    static void onCoreError(void* data, uint32_t id, int seq, int res, const char* message);
};

void PipewireStreamWatcherPrivate::init() {
    pw_init(nullptr, nullptr);

    reconnectTimer = new QTimer(q);
    reconnectTimer->setInterval(3000);
    reconnectTimer->setSingleShot(true);
    QObject::connect(reconnectTimer, &QTimer::timeout, q, [this]() {
        tryConnect();
    });

    tryConnect();
}

void PipewireStreamWatcherPrivate::cleanup() {
    if (reconnectTimer) {
        reconnectTimer->stop();
    }

    if (threadLoop) {
        pw_thread_loop_stop(threadLoop);
        pw_thread_loop_lock(threadLoop);
    }

    if (registry) {
        spa_hook_remove(&registryListener);
        pw_proxy_destroy(reinterpret_cast<pw_proxy*>(registry));
        registry = nullptr;
    }

    if (core) {
        spa_hook_remove(&coreListener);
        pw_core_disconnect(core);
        core = nullptr;
    }

    if (context) {
        pw_context_destroy(context);
        context = nullptr;
    }

    if (threadLoop) {
        pw_thread_loop_unlock(threadLoop);
        pw_thread_loop_destroy(threadLoop);
        threadLoop = nullptr;
    }

    pw_deinit();

    {
        QMutexLocker locker(&mutex);
        trackedNodes.clear();
    }
}

void PipewireStreamWatcherPrivate::tryConnect() {
    if (threadLoop) {
        cleanup();
        pw_init(nullptr, nullptr);
    }

    threadLoop = pw_thread_loop_new("caelestia-stream-watcher", nullptr);
    if (!threadLoop) {
        qCWarning(lcPipewireStreamWatcher) << "Failed to create PipeWire thread loop";
        scheduleReconnect();
        return;
    }

    if (pw_thread_loop_start(threadLoop) < 0) {
        qCWarning(lcPipewireStreamWatcher) << "Failed to start PipeWire thread loop";
        pw_thread_loop_destroy(threadLoop);
        threadLoop = nullptr;
        scheduleReconnect();
        return;
    }

    pw_thread_loop_lock(threadLoop);

    context = pw_context_new(pw_thread_loop_get_loop(threadLoop), nullptr, 0);
    if (!context) {
        qCWarning(lcPipewireStreamWatcher) << "Failed to create PipeWire context";
        pw_thread_loop_unlock(threadLoop);
        scheduleReconnect();
        return;
    }

    core = pw_context_connect(context, nullptr, 0);
    if (!core) {
        qCWarning(lcPipewireStreamWatcher) << "Failed to connect to PipeWire core";
        pw_context_destroy(context);
        context = nullptr;
        pw_thread_loop_unlock(threadLoop);
        scheduleReconnect();
        return;
    }

    static const pw_core_events coreEvents = {
        .version = PW_VERSION_CORE_EVENTS,
        .error = onCoreError,
    };
    spa_zero(coreListener);
    pw_core_add_listener(core, &coreListener, &coreEvents, this);

    registry = pw_core_get_registry(core, PW_VERSION_REGISTRY, 0);
    if (!registry) {
        qCWarning(lcPipewireStreamWatcher) << "Failed to get PipeWire registry";
        pw_thread_loop_unlock(threadLoop);
        scheduleReconnect();
        return;
    }

    static const pw_registry_events registryEvents = {
        .version = PW_VERSION_REGISTRY_EVENTS,
        .global = onGlobal,
        .global_remove = onGlobalRemove,
    };
    spa_zero(registryListener);
    pw_registry_add_listener(registry, &registryListener, &registryEvents, this);

    pw_thread_loop_unlock(threadLoop);
    qCInfo(lcPipewireStreamWatcher) << "Connected to PipeWire registry";
}

void PipewireStreamWatcherPrivate::scheduleReconnect() {
    if (reconnectTimer && !reconnectTimer->isActive()) {
        reconnectTimer->start();
    }
}

void PipewireStreamWatcherPrivate::notifyStateChangedFromThread() {
    bool streaming = false;
    int count = 0;
    QStringList streams;

    {
        QMutexLocker locker(&mutex);
        for (const auto& node : trackedNodes) {
            if (node.isStreaming) {
                ++count;
                streams.append(!node.mediaName.isEmpty() ? node.mediaName : node.nodeName);
            }
        }
        streaming = (count > 0);
    }

    QMetaObject::invokeMethod(
        q,
        [this, streaming, count, streams]() {
            updateState(streaming, count, streams);
        },
        Qt::QueuedConnection);
}

void PipewireStreamWatcherPrivate::updateState(bool streaming, int count, const QStringList& streams) {
    const bool streamingChanged = (m_streaming != streaming);
    const bool countChanged = (m_streamCount != count);
    const bool streamsChanged = (m_activeStreams != streams);

    m_streaming = streaming;
    m_streamCount = count;
    m_activeStreams = streams;

    if (streamingChanged) {
        qCInfo(lcPipewireStreamWatcher) << "Streaming state changed to" << m_streaming
                                        << "(active count:" << m_streamCount << ")";
        emit q->streamingChanged(m_streaming);
    }
    if (countChanged) {
        emit q->streamCountChanged(m_streamCount);
    }
    if (streamsChanged) {
        emit q->activeStreamsChanged();
    }
}

void PipewireStreamWatcherPrivate::onGlobal(
    void* data, uint32_t id, uint32_t /*permissions*/, const char* type, uint32_t /*version*/, const spa_dict* props) {
    if (!type || strcmp(type, PW_TYPE_INTERFACE_Node) != 0 || !props) {
        return;
    }

    auto* d = static_cast<PipewireStreamWatcherPrivate*>(data);

    const char* mediaClass = spa_dict_lookup(props, PW_KEY_MEDIA_CLASS);
    const char* nodeName = spa_dict_lookup(props, PW_KEY_NODE_NAME);
    const char* mediaName = spa_dict_lookup(props, PW_KEY_MEDIA_NAME);
    const char* mediaRole = spa_dict_lookup(props, PW_KEY_MEDIA_ROLE);

    const bool streaming = isStreamingNode(mediaClass, nodeName, mediaName, mediaRole);

    {
        QMutexLocker locker(&d->mutex);
        d->trackedNodes.insert(id, { mediaClass ? QString::fromUtf8(mediaClass) : QString(),
                                       nodeName ? QString::fromUtf8(nodeName) : QString(),
                                       mediaName ? QString::fromUtf8(mediaName) : QString(),
                                       mediaRole ? QString::fromUtf8(mediaRole) : QString(), streaming });
    }

    if (streaming) {
        qCInfo(lcPipewireStreamWatcher) << "Detected video streaming node:" << (nodeName ? nodeName : "<unknown>")
                                        << "id:" << id << "class:" << (mediaClass ? mediaClass : "<unknown>");
    }

    d->notifyStateChangedFromThread();
}

void PipewireStreamWatcherPrivate::onGlobalRemove(void* data, uint32_t id) {
    auto* d = static_cast<PipewireStreamWatcherPrivate*>(data);
    bool wasStreaming = false;

    {
        QMutexLocker locker(&d->mutex);
        auto it = d->trackedNodes.find(id);
        if (it != d->trackedNodes.end()) {
            wasStreaming = it->isStreaming;
            d->trackedNodes.erase(it);
        }
    }

    if (wasStreaming) {
        qCInfo(lcPipewireStreamWatcher) << "Video streaming node removed, id:" << id;
    }

    d->notifyStateChangedFromThread();
}

void PipewireStreamWatcherPrivate::onCoreError(void* data, uint32_t id, int seq, int res, const char* message) {
    auto* d = static_cast<PipewireStreamWatcherPrivate*>(data);
    qCWarning(lcPipewireStreamWatcher) << "PipeWire core error:" << message << "id:" << id << "seq:" << seq
                                       << "res:" << res;
    if (id == PW_ID_CORE) {
        QMetaObject::invokeMethod(
            d->q,
            [d]() {
                d->scheduleReconnect();
            },
            Qt::QueuedConnection);
    }
}

PipewireStreamWatcher::PipewireStreamWatcher(QObject* parent)
    : QObject(parent)
    , d(std::make_unique<PipewireStreamWatcherPrivate>(this)) {
    d->init();
}

PipewireStreamWatcher::~PipewireStreamWatcher() {
    d->cleanup();
}

bool PipewireStreamWatcher::isStreaming() const {
    return d->m_streaming;
}

int PipewireStreamWatcher::streamCount() const {
    return d->m_streamCount;
}

QStringList PipewireStreamWatcher::activeStreams() const {
    return d->m_activeStreams;
}

void PipewireStreamWatcher::rescan() {
    d->notifyStateChangedFromThread();
}

} // namespace caelestia::services
