pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Caelestia.Services
import qs.modules.common

/**
 * A service that provides easy access to the active Mpris player and synchronizes Lyrics.
 */
Singleton {
    id: root

    property list<MprisPlayer> players: Mpris.players.values.filter(player => isRealPlayer(player))
    property MprisPlayer trackedPlayer: null
    property MprisPlayer activePlayer: trackedPlayer ?? Mpris.players.values[0] ?? null
    property bool __reverse: false
    property var activeTrack: null

    readonly property bool hasActivePlasmaIntegration: Mpris.players.values.some(
        p => p.dbusName?.startsWith('org.mpris.MediaPlayer2.plasma-browser-integration')
    )
    readonly property bool isPlaying: root.activePlayer && root.activePlayer.isPlaying
    readonly property bool canTogglePlaying: root.activePlayer?.canTogglePlaying ?? false
    readonly property bool canGoPrevious: root.activePlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: root.activePlayer?.canGoNext ?? false
    readonly property bool canChangeVolume: root.activePlayer && root.activePlayer.volumeSupported && root.activePlayer.canControl
    readonly property bool loopSupported: root.activePlayer && root.activePlayer.loopSupported && root.activePlayer.canControl
    property var loopState: root.activePlayer?.loopState ?? MprisLoopState.None
    readonly property bool shuffleSupported: root.activePlayer && root.activePlayer.shuffleSupported && root.activePlayer.canControl
    readonly property bool hasShuffle: root.activePlayer?.shuffle ?? false

    signal trackChanged(reverse: bool)

    function isRealPlayer(player: MprisPlayer): bool {
        if (!Config.options.media.filterDuplicatePlayers) {
            return true;
        }
        return (
            !(hasActivePlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.firefox')) &&
            !(hasActivePlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.chromium')) &&
            !player.dbusName?.startsWith('org.mpris.MediaPlayer2.playerctld') &&
            !(player.dbusName?.endsWith('.mpd') && !player.dbusName.endsWith('MediaPlayer2.mpd'))
        );
    }

    function updateTrack(): void {
        root.activeTrack = {
            uniqueId: root.activePlayer?.uniqueId ?? 0,
            artUrl: root.activePlayer?.trackArtUrl ?? "",
            title: root.activePlayer?.trackTitle || Translation.tr("Unknown Title"),
            artist: root.activePlayer?.trackArtist || Translation.tr("Unknown Artist"),
            album: root.activePlayer?.trackAlbum || Translation.tr("Unknown Album"),
        };

        if (root.activePlayer && root.activePlayer.trackTitle) {
            Lyrics.setTrack(
                root.activePlayer.trackArtist ?? "",
                root.activePlayer.trackTitle ?? "",
                root.activePlayer.trackAlbum ?? "",
                (root.activePlayer.length ?? 0) / 1000000
            );
        } else {
            Lyrics.clearTrack();
        }

        root.trackChanged(__reverse);
        root.__reverse = false;
    }

    function togglePlaying(): void {
        if (root.canTogglePlaying)
            root.activePlayer.togglePlaying();
    }

    function previous(): void {
        if (root.canGoPrevious) {
            root.__reverse = true;
            root.activePlayer.previous();
        }
    }

    function next(): void {
        if (root.canGoNext) {
            root.__reverse = false;
            root.activePlayer.next();
        }
    }

    function setLoopState(state: var): void {
        if (root.loopSupported)
            root.activePlayer.loopState = state;
    }

    function setShuffle(shuffle: bool): void {
        if (root.shuffleSupported)
            root.activePlayer.shuffle = shuffle;
    }

    function setActivePlayer(player: MprisPlayer): void {
        const targetPlayer = player ?? Mpris.players[0];
        if (targetPlayer && root.activePlayer) {
            root.__reverse = Mpris.players.indexOf(targetPlayer) < Mpris.players.indexOf(root.activePlayer);
        } else {
            root.__reverse = false;
        }
        root.trackedPlayer = targetPlayer;
    }

    onActivePlayerChanged: root.updateTrack()

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData

            function onPlaybackStateChanged(): void {
                if (root.trackedPlayer !== modelData)
                    root.trackedPlayer = modelData;
            }

            target: modelData

            Component.onCompleted: {
                if (root.trackedPlayer == null || modelData.isPlaying)
                    root.trackedPlayer = modelData;
            }

            Component.onDestruction: {
                if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
                    for (const player of Mpris.players.values) {
                        if (player.playbackState.isPlaying) {
                            root.trackedPlayer = player;
                            break;
                        }
                    }
                    if (root.trackedPlayer == null && Mpris.players.values.length != 0)
                        root.trackedPlayer = Mpris.players.values[0];
                }
            }
        }
    }

    Connections {
        function onPostTrackChanged(): void {
            root.updateTrack();
        }

        function onTrackArtUrlChanged(): void {
            if (root.activePlayer && root.activeTrack && root.activePlayer.uniqueId == root.activeTrack.uniqueId && root.activePlayer.trackArtUrl != root.activeTrack.artUrl) {
                const r = root.__reverse;
                root.updateTrack();
                root.__reverse = r;
            }
        }

        target: root.activePlayer
    }

    IpcHandler {
        function pauseAll(): void {
            for (const player of Mpris.players.values) {
                if (player.canPause)
                    player.pause();
            }
        }

        function playPause(): void { root.togglePlaying(); }

        function previous(): void { root.previous(); }

        function next(): void { root.next(); }

        target: "mpris"
    }
}
