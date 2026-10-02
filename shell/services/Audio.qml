pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia.Services
import qs.modules.common

/**
 * High-performance audio service backed by Quickshell Pipewire and Caelestia C++ AudioBackend.
 */
Singleton {
    id: root

    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00
    property string audioTheme: Config.options?.sounds?.theme ?? "ocean"
    property real value: sink?.audio?.volume ?? 0

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    property bool showInactiveDevices: false
    property var cards: AudioBackend.cards

    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> streams: []
    property list<PwNode> appStreams: []

    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    property var cava: null
    readonly property alias beatTracker: beatTracker

    property var _sfxCache: ({})

    signal sinkProtectionTriggered(string reason)

    function friendlyDeviceName(node: var): string {
        if (!node)
            return Translation.tr("Unknown");
        return (node.nickname || node.description || node.name || Translation.tr("Unknown"));
    }

    function appNodeDisplayName(node: var): string {
        if (!node)
            return Translation.tr("Unknown Application");
        return (node.properties?.["application.name"] || node.description || node.name || Translation.tr("Unknown Application"));
    }

    function correctType(node: var, isSink: bool): bool {
        return (node?.isSink === isSink) && (node?.audio !== null && node?.audio !== undefined);
    }

    function appNodes(isSink: bool): list<var> {
        return Pipewire.nodes.values.filter((node) => {
            return root.correctType(node, isSink) && node.isStream;
        });
    }

    function devices(isSink: bool): list<var> {
        return Pipewire.nodes.values.filter(node => {
            if (!root.correctType(node, isSink) || node.isStream)
                return false;
            if (root.showInactiveDevices)
                return true;
            return isSink ? !AudioBackend.isSinkInactive(node.name) : !AudioBackend.isSourceInactive(node.name);
        });
    }

    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute(): void {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(root.hardMaxValue, newVolume));
        }
    }

    function incrementVolume(): void {
        const currentVolume = root.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02;
        setVolume(Math.min(1.0, currentVolume + step));
    }

    function decrementVolume(): void {
        const currentVolume = root.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02;
        setVolume(Math.max(0.0, currentVolume - step));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(root.hardMaxValue, newVolume));
        }
    }

    function incrementSourceVolume(amount: real = 0.02): void {
        setSourceVolume(sourceVolume + (amount || 0.02));
    }

    function decrementSourceVolume(amount: real = 0.02): void {
        setSourceVolume(sourceVolume - (amount || 0.02));
    }

    function setDefaultSink(node: var): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node: var): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;
        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setDefaultSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(root.hardMaxValue, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, mutedState: bool): void {
        if (stream?.ready && stream?.audio)
            stream.audio.muted = mutedState;
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return Translation.tr("Unknown");
        return stream.properties?.["application.name"] || stream.description || stream.name || Translation.tr("Unknown Application");
    }

    function playSystemSound(soundName: string): void {
        const theme = root.audioTheme || "ocean";
        const ogaPath = `file:///usr/share/sounds/${theme}/stereo/${soundName}.oga`;

        let sfx = root._sfxCache[soundName];
        if (!sfx) {
            sfx = sfxComponent.createObject(root, { "source": ogaPath });
            root._sfxCache[soundName] = sfx;
        }
        if (sfx) {
            sfx.play();
        }
    }

    function refreshNodes(): void {
        const newStreams = [];
        const newAppStreams = [];
        const seenApps = new Set();
        const seenSinks = new Map();
        const seenSources = new Map();

        for (const node of Pipewire.nodes.values) {
            if (!node.isStream) {
                if (node.isSink) {
                    if (root.showInactiveDevices || !AudioBackend.isSinkInactive(node.name)) {
                        if (!seenSinks.has(node.name)) {
                            seenSinks.set(node.name, node);
                        } else {
                            const existing = seenSinks.get(node.name);
                            if (node === Pipewire.defaultAudioSink || (existing !== Pipewire.defaultAudioSink && node.id > existing.id))
                                seenSinks.set(node.name, node);
                        }
                    }
                } else if (node.audio) {
                    if (root.showInactiveDevices || !AudioBackend.isSourceInactive(node.name)) {
                        if (!seenSources.has(node.name)) {
                            seenSources.set(node.name, node);
                        } else {
                            const existing = seenSources.get(node.name);
                            if (node === Pipewire.defaultAudioSource || (existing !== Pipewire.defaultAudioSource && node.id > existing.id))
                                seenSources.set(node.name, node);
                        }
                    }
                }
            } else if (node.audio) {
                newStreams.push(node);
                const name = getStreamName(node);
                if (name === "caelestia-shell")
                    continue;
                if (!seenApps.has(name)) {
                    seenApps.add(name);
                    newAppStreams.push(node);
                }
            }
        }

        root.appStreams = newAppStreams;
        root.sinks = [...seenSinks.values()];
        root.sources = [...seenSources.values()];
        root.streams = newStreams;
    }

    PwObjectTracker {
        objects: [sink, source, ...sinks, ...sources, ...streams].filter(n => n)
    }

    Connections {
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0

        function onVolumeChanged(): void {
            if (!Config.options?.audio?.protection?.enable)
                return;
            const newVolume = sink.audio.volume;
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = (Config.options?.audio?.protection?.maxAllowedIncrease ?? 20) / 100;
            const maxAllowed = (Config.options?.audio?.protection?.maxAllowed ?? 100) / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    Connections {
        target: Pipewire.nodes

        function onValuesChanged(): void {
            root.refreshNodes();
        }
    }

    Connections {
        target: AudioBackend

        function onDevicesChanged(): void {
            root.refreshNodes();
        }
    }

    BeatTracker {
        id: beatTracker
    }

    Component {
        id: sfxComponent

        SoundEffect {}
    }

    Component.onCompleted: {
        AudioBackend.showInactiveDevices = root.showInactiveDevices;
        root.refreshNodes();

        try {
            root.cava = Qt.createQmlObject(
                'import Caelestia.Services\nCavaProvider { bars: 32 }',
                root, "CavaProviderDynamic");
        } catch (e) {
            // CavaProvider dynamic fallback
        }
    }
}
