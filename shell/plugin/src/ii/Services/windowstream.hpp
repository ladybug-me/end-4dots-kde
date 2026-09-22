#pragma once

// One consumer's claim on a live screencast of a single window.
//
// Replaces ScreencastManager.qml, which kept the same bookkeeping -- a
// dictionary of refcounted WindowScreencastRequest objects, an LRU order and a
// concurrency cap -- in JavaScript, and handed it out through a function that
// callers invoked from Component.onCompleted. That last part is what crashed:
// creating a screencast object and mutating the singleton's dictionary while
// QML was still building the caller ran the write inside
// QQmlObjectCreator::finalize, and V4 segfaulted in insertMember under
// StoreElement. It needed a busy dock popout and a handful of windows to hit,
// but then it was reliable -- four times in five on a stress that swapped the
// hovered icon repeatedly. The mitigation was to wrap every call site in
// Qt.callLater, which worked but left the hazard one forgotten call away.
//
// Here there is no function to call at the wrong time. A consumer declares which
// window it wants and binds to objectSerial; acquiring and releasing follow
// property changes and object lifetime, and the shared state is a QHash in C++
// that QML cannot reach into at all.

#include <QObject>
#include <QQmlEngine>
#include <QString>

namespace caelestia::services {

class WindowStream : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(quint32 nodeId READ nodeId NOTIFY streamChanged)
    Q_PROPERTY(quint64 objectSerial READ objectSerial NOTIFY streamChanged)
    Q_PROPERTY(bool available READ available NOTIFY streamChanged)
    QML_ELEMENT

public:
    explicit WindowStream(QObject* parent = nullptr);
    ~WindowStream() override;

    QString address() const;
    void setAddress(const QString& address);

    /**
     * Whether this consumer currently wants pixels.
     *
     * Streams are a finite resource -- KWin will only hand out so many, and
     * exhausting them makes other clients' captures fail, which is how this
     * shell used to break Vesktop's screen share. A consumer that is scrolled
     * out of view or on a workspace nobody is looking at should say so rather
     * than hold one open.
     */
    bool active() const;
    void setActive(bool active);

    quint32 nodeId() const;
    quint64 objectSerial() const;
    bool available() const;

Q_SIGNALS:
    void addressChanged();
    void activeChanged();
    void streamChanged();

private:
    void acquire();
    void release();

    QString m_address;
    QString m_held;
    bool m_active = true;
};

} // namespace caelestia::services
