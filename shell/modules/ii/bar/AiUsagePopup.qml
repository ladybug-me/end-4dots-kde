import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    function formatTokens(count) {
        if (count >= 1000000) return `${(count / 1000000).toFixed(1)}M`;
        if (count >= 1000) return `${Math.round(count / 1000)}k`;
        return `${count}`;
    }

    function formatReset() {
        if (ClaudeUsage.resetsAt <= 0) return Translation.tr("No usage in this window");
        const seconds = Math.max(0, ClaudeUsage.resetsAt - Date.now() / 1000);
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return Translation.tr("Resets in %1").arg(h > 0 ? `${h}h ${m}m` : `${m}m`);
    }

    ColumnLayout {
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 3
            spacing: 7

            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimaryContainer

                CustomIcon {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "claude-symbolic"
                    colorize: true
                    color: Appearance.colors.colPrimary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -3

                StyledText {
                    text: "Claude Code"
                    font {
                        weight: Font.Medium
                        pixelSize: Appearance.font.pixelSize.normal
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.6
                    text: root.formatReset()
                }
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                Layout.rightMargin: 8
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colPrimary
                text: `${Math.round(ClaudeUsage.percentage * 100)}%`
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            valueBarWidth: 260
            value: ClaudeUsage.percentage
        }

        StyledPopupValueRow {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            icon: "token"
            label: Translation.tr("Tokens (estimate)")
            value: `${root.formatTokens(ClaudeUsage.tokens)} / ${root.formatTokens(ClaudeUsage.tokenLimit)}`
        }

        StyledPopupValueRow {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            visible: ClaudeUsage.activeSessions === 0
            icon: "bedtime"
            label: Translation.tr("No active sessions")
            value: ""
        }

        Repeater {
            model: ClaudeUsage.sessions
            delegate: StyledPopupValueRow {
                required property var modelData
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                icon: modelData.status === "busy" ? "progress_activity" : "terminal"
                label: modelData.name
                value: modelData.status === "busy" ? Translation.tr("Working") : Translation.tr("Idle")
            }
        }
    }
}
