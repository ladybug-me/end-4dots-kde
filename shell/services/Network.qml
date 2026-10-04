pragma Singleton
pragma ComponentBehavior: Bound

import qs.services.network
import QtQuick
import Quickshell
import Caelestia.Services

/**
 * Network service backed by the native C++ NmQt (NetworkManagerQt) plugin.
 */
Singleton {
    id: root

    property bool wifi: wifiEnabled && !ethernet
    readonly property bool ethernet: (NmQt.activeEthernet && Object.keys(NmQt.activeEthernet).length > 0) || (activeEthernetDevice !== null)

    readonly property bool wifiEnabled: NmQt.wifiEnabled
    readonly property bool wifiScanning: NmQt.scanning
    readonly property bool wifiConnecting: NmQt.connectingSsid.length > 0
    property WifiAccessPoint wifiConnectTarget: null

    property list<WifiAccessPoint> __wifiNetworks: []
    readonly property list<WifiAccessPoint> wifiNetworks: __wifiNetworks

    readonly property WifiAccessPoint active: {
        const raw = NmQt.active;
        if (!raw || !raw.ssid || raw.ssid.length === 0)
            return null;
        return __wifiNetworks.find(n => n.ssid === raw.ssid) ?? null;
    }

    readonly property list<var> friendlyWifiNetworks: [...__wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })

    readonly property var activeEthernetDevice: {
        const devs = NmQt.ethernetDevices;
        if (!devs || devs.length === 0)
            return null;
        return devs.find(d => d.connected) ?? null;
    }

    readonly property string wifiStatus: {
        if (!NmQt.wifiEnabled)
            return "disabled";
        if (NmQt.connectingSsid.length > 0)
            return "connecting";
        if (active !== null)
            return "connected";
        return "disconnected";
    }

    readonly property string networkName: {
        if (root.ethernet) {
            const rawEth = NmQt.activeEthernet;
            return (rawEth && rawEth.connectionName) ? rawEth.connectionName : "Ethernet";
        }
        if (root.active && root.active.ssid)
            return root.active.ssid;
        return "";
    }

    readonly property int networkStrength: root.active ? root.active.strength : 0

    readonly property string materialSymbol: root.ethernet
        ? "lan"
        : (root.wifiEnabled && root.wifiStatus === "connected")
            ? (
                (root.active?.strength ?? 0) > 83 ? "signal_wifi_4_bar" :
                (root.active?.strength ?? 0) > 67 ? "network_wifi" :
                (root.active?.strength ?? 0) > 50 ? "network_wifi_3_bar" :
                (root.active?.strength ?? 0) > 33 ? "network_wifi_2_bar" :
                (root.active?.strength ?? 0) > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_find"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    function enableWifi(enabled: var): void {
        NmQt.enableWifi(enabled === undefined ? true : enabled);
    }

    function toggleWifi(): void {
        NmQt.toggleWifi();
    }

    function rescanWifi(): void {
        NmQt.rescanWifi();
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint): void {
        if (!accessPoint)
            return;
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;

        NmQt.connectToNetworkWithPasswordCheck(accessPoint.ssid, accessPoint.isSecure, (result) => {
            if (result && result.needsPassword) {
                accessPoint.askingPassword = true;
            } else if (result && !result.success) {
                accessPoint.askingPassword = (result.error && result.error.includes("Secrets were required"));
            }
            root.wifiConnectTarget = null;
        }, accessPoint.bssid);
    }

    function disconnectWifiNetwork(): void {
        NmQt.disconnectFromNetwork();
    }

    function openPublicWifiPortal(): void {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    function changePassword(network: WifiAccessPoint, password: string, username: var): void {
        if (!network)
            return;
        network.askingPassword = false;
        root.wifiConnectTarget = network;
        NmQt.connectToNetwork(network.ssid, password, network.bssid, (result) => {
            if (result && !result.success) {
                network.askingPassword = true;
            }
            root.wifiConnectTarget = null;
        });
    }

    function rebuildNetworkList(): void {
        const rawList = NmQt.networks;
        const newList = [];
        const oldMap = new Map();

        for (let i = 0; i < __wifiNetworks.length; i++) {
            const ap = __wifiNetworks[i];
            if (ap && ap.ssid) {
                const key = ap.bssid || ap.ssid;
                oldMap.set(key, ap);
            }
        }

        for (let i = 0; i < rawList.length; i++) {
            const raw = rawList[i];
            const key = raw.bssid || raw.ssid;
            const existing = oldMap.get(key);
            if (existing) {
                existing.lastIpcObject = raw;
                newList.push(existing);
                oldMap.delete(key);
            } else {
                newList.push(apComp.createObject(root, { "lastIpcObject": raw }));
            }
        }

        oldMap.forEach(ap => {
            ap.destroy();
        });

        root.__wifiNetworks = newList;
    }

    Connections {
        target: NmQt

        function onNetworksChanged(): void {
            root.rebuildNetworkList();
        }
    }

    Component.onCompleted: {
        root.rebuildNetworkList();
    }

    Component {
        id: apComp

        WifiAccessPoint {}
    }
}
