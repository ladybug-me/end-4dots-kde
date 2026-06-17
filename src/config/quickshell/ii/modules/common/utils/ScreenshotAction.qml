pragma ComponentBehavior: Bound
pragma Singleton
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell

Singleton {
    id: root

    enum Action {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound
    }

    property string imageSearchEngineBaseUrl: Config.options.search.imageSearch.imageSearchEngineBaseUrl
    property string fileUploadApiEndpoint: "https://uguu.se/upload"

    function getCommand(x, y, width, height, screenshotPath, action, saveDir = "") {
        // Set command for action
        const rx = Math.round(x);
        const ry = Math.round(y);
        const rw = Math.round(width);
        const rh = Math.round(height);

        const cropBase = `magick '${StringUtils.shellSingleQuoteEscape(screenshotPath)}' `
            + `-crop ${rw}x${rh}+${rx}+${ry} +repage`
        const cropToFile = (outPath) => `${cropBase} '${StringUtils.shellSingleQuoteEscape(outPath)}'`
        const cropToStdout = `${cropBase} png:-`
        const cleanup = `rm -f '${StringUtils.shellSingleQuoteEscape(screenshotPath)}'`
        const annotationCommand = `${Config.options.regionSelector.annotation.useSatty ? "satty" : "swappy"} -f -`;
        const uploadAndGetUrl = (filePath) => {
            return `curl -sF files[]=@'${StringUtils.shellSingleQuoteEscape(filePath)}' ${root.fileUploadApiEndpoint} | jq -r '.files[0].url'`
        }
        // saveDir may contain ~/ — pass it to bash and let bash expand via ${var/#\~/$HOME}
        const rawSaveDir = saveDir;

        switch (action) {
            case ScreenshotAction.Action.Copy: {
                // If savePath config is empty, fallback to a default failproof directory
                let saveDir = rawSaveDir === "" ? "~/Pictures/Screenshots" : rawSaveDir;
                
                return [
                    "bash", "-c",
                    `set -euo pipefail; ` +
                    `SAVE_DIR='${StringUtils.shellSingleQuoteEscape(saveDir)}'; ` +
                    `SAVE_DIR="\${SAVE_DIR/#\\~/$HOME}"; ` +
                    `mkdir -p "$SAVE_DIR" && ` +
                    `saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" && ` +
                    `${cropBase} "$saveFile" && ` +
                    `wl-copy -t image/png < "$saveFile"; ` +
                    `${cleanup}`
                ]
            }

            case ScreenshotAction.Action.Edit:
                return ["bash", "-c",
                    `set -euo pipefail; TMPF=$(mktemp /tmp/qs-snip-XXXXXX.png); ` +
                    `${cropBase} "$TMPF" && ` +
                    `${annotationCommand} < "$TMPF"; ` +
                    `rm -f "$TMPF"; ${cleanup}`
                ]

            case ScreenshotAction.Action.Search: {
                const tmpFile = "/tmp/qs-snip-search.png"
                return ["bash", "-c",
                    `set -euo pipefail; ` +
                    `${cropToFile(tmpFile)} && ` +
                    `xdg-open "${root.imageSearchEngineBaseUrl}$(${uploadAndGetUrl(tmpFile)})"; ` +
                    `rm -f '${tmpFile}'; ${cleanup}`
                ]
            }

            case ScreenshotAction.Action.CharRecognition:
                return ["bash", "-c",
                    `set -euo pipefail; TMPF=$(mktemp /tmp/qs-snip-XXXXXX.png); ` +
                    `${cropBase} "$TMPF" && ` +
                    `tesseract "$TMPF" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') | wl-copy; ` +
                    `rm -f "$TMPF"; ${cleanup}`
                ]

            case ScreenshotAction.Action.Record:
                return ["bash", "-c", `${Directories.recordScriptPath} --region '${rx},${ry} ${rw}x${rh}'`]

            case ScreenshotAction.Action.RecordWithSound:
                return ["bash", "-c", `${Directories.recordScriptPath} --region '${rx},${ry} ${rw}x${rh}' --sound`]

            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                return;
        }
    }
}
