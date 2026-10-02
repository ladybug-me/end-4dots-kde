pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property var filePath: Directories.todoPath
    property var list: []

    function addItem(item) {
        list.push(item);
        root.list = list.slice(0);
        todoFileView.setText(JSON.stringify(root.list));
    }

    function addTask(desc) {
        const item = {
            "content": desc,
            "done": false
        };
        addItem(item);
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = true;
            root.list = list.slice(0);
            todoFileView.setText(JSON.stringify(root.list));
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false;
            root.list = list.slice(0);
            todoFileView.setText(JSON.stringify(root.list));
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1);
            root.list = list.slice(0);
            todoFileView.setText(JSON.stringify(root.list));
        }
    }

    function refresh() {
        todoFileView.reload();
    }

    Component.onCompleted: {
        refresh();
    }

    FileView {
        id: todoFileView

        path: Qt.resolvedUrl(root.filePath)

        onLoaded: {
            const fileContents = todoFileView.text();
            root.list = JSON.parse(fileContents);
            console.log("[To Do] File loaded");
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                console.log("[To Do] File not found, creating new file.");
                root.list = [];
                todoFileView.setText(JSON.stringify(root.list));
            } else {
                console.log("[To Do] Error loading file: " + error);
            }
        }
    }
}
