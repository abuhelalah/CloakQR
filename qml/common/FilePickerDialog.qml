import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt.labs.folderlistmodel

// In-app, Material-themed file picker used on desktop instead of the platform
// file dialog, which opens as a separate top-level window and does not follow
// the app's dark/light theme. Because this is an in-overlay Popup it inherits
// the Material theme directly, so it stays readable in every theme. It offers
// an open mode (pick an existing file) and a save mode (choose a folder and
// type a file name). Mobile builds keep the native storage picker.
Popup {
    id: root

    property bool saveMode: false
    property string dialogTitle: saveMode ? qsTr("Save file") : qsTr("Open file")
    // Wildcard patterns applied to the file list, e.g. ["*.png", "*.jpg"].
    property var patterns: ["*"]
    property string defaultSuffix: ""
    property string suggestedName: ""

    // Brand colours supplied by the host page; everything else derives from the
    // active Material theme so the dialog is always legible.
    property color primaryColor: "#086C5C"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#5D6F69"

    signal accepted(url file)

    property url currentFolder
    property url selectedFile

    // Opens the dialog rooted at the given folder (falling back to Home).
    function openAt(folder) {
        root.currentFolder = folder && folder.toString().length > 0
            ? folder : StandardPaths.writableLocation(StandardPaths.HomeLocation)
        root.selectedFile = ""
        nameField.text = root.saveMode ? root.suggestedName : ""
        root.open()
    }

    readonly property bool canAccept: saveMode
        ? nameField.text.trim().length > 0
        : selectedFile.toString().length > 0

    function acceptSelection() {
        if (!canAccept)
            return
        if (saveMode) {
            var name = nameField.text.trim()
            if (defaultSuffix.length > 0 && name.lastIndexOf(".") <= 0)
                name += "." + defaultSuffix
            var base = root.currentFolder.toString()
            if (!base.endsWith("/"))
                base += "/"
            root.accepted(base + encodeURIComponent(name))
        } else {
            root.accepted(root.selectedFile)
        }
        root.close()
    }

    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 0
    width: Math.min((Overlay.overlay ? Overlay.overlay.width : 640) - 48, 640)
    height: Math.min((Overlay.overlay ? Overlay.overlay.height : 720) - 48, 620)

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.55)
    }

    background: Rectangle {
        color: root.Material.background
        radius: 16
        border.width: 1
        border.color: Qt.rgba(root.mutedColor.r, root.mutedColor.g, root.mutedColor.b, 0.16)
    }

    FolderListModel {
        id: folderModel
        folder: root.currentFolder
        nameFilters: root.patterns
        showDirs: true
        showFiles: true
        showDotAndDotDot: false
        showHidden: false
        showDirsFirst: true
        sortField: FolderListModel.Name
    }

    contentItem: ColumnLayout {
        spacing: 0

        // Brand header with title and close affordance.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: root.primaryColor
            topLeftRadius: 16
            topRightRadius: 16

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 10
                spacing: 12

                Label {
                    Layout.fillWidth: true
                    text: root.dialogTitle
                    color: root.primaryTextColor
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                }
                ToolButton {
                    id: closeButton
                    implicitWidth: 40
                    implicitHeight: 40
                    Accessible.name: qsTr("Close")
                    onClicked: root.close()
                    contentItem: Label {
                        text: "\u00D7"
                        color: root.primaryTextColor
                        font.pixelSize: 26
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: closeButton.pressed ? Qt.rgba(1, 0.36, 0.36, 0.55)
                             : closeButton.hovered ? Qt.rgba(1, 0.36, 0.36, 0.32)
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }
        }

        // Quick access to common user folders.
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 12
            spacing: 8

            Repeater {
                model: [
                    { label: qsTr("Home"), loc: StandardPaths.HomeLocation },
                    { label: qsTr("Documents"), loc: StandardPaths.DocumentsLocation },
                    { label: qsTr("Downloads"), loc: StandardPaths.DownloadLocation },
                    { label: qsTr("Pictures"), loc: StandardPaths.PicturesLocation }
                ]
                delegate: Button {
                    required property var modelData
                    flat: true
                    text: modelData.label
                    Material.foreground: root.primaryColor
                    onClicked: root.currentFolder = StandardPaths.writableLocation(modelData.loc)
                }
            }
        }

        // Current path with a parent-folder affordance.
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 12
            Layout.topMargin: 4
            spacing: 6

            ToolButton {
                id: upButton
                Accessible.name: qsTr("Go to parent folder")
                enabled: folderModel.parentFolder.toString().length > 0
                         && folderModel.parentFolder.toString() !== root.currentFolder.toString()
                onClicked: root.currentFolder = folderModel.parentFolder
                contentItem: Label {
                    text: "\u2B06"
                    font.pixelSize: 18
                    color: upButton.enabled ? Material.foreground : root.mutedColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Label {
                Layout.fillWidth: true
                text: root.currentFolder.toString().replace(/^file:\/\//, "")
                color: root.mutedColor
                font.pixelSize: 12
                elide: Text.ElideLeft
            }
        }

        // Folder/file listing.
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 4
            radius: 10
            color: Qt.rgba(root.mutedColor.r, root.mutedColor.g, root.mutedColor.b, 0.08)

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                model: folderModel
                ScrollBar.vertical: ScrollBar {}

                delegate: ItemDelegate {
                    id: rowDelegate
                    required property int index
                    required property var model

                    readonly property string fileName: model.fileName
                    // model.filePath is "/home/…" on Unix and "C:/…" on Windows.
                    // Strip any leading slashes and always use the three-slash
                    // file:/// form so Windows drive letters are not parsed as a host.
                    readonly property url fileURL: Qt.resolvedUrl("file:///" + model.filePath.replace(/^\/+/, ""))
                    readonly property bool fileIsDir: model.fileIsDir

                    width: ListView.view.width
                    highlighted: !fileIsDir
                                 && root.selectedFile.toString() === fileURL.toString()

                    onClicked: {
                        if (fileIsDir) {
                            root.currentFolder = fileURL
                        } else {
                            root.selectedFile = fileURL
                            if (root.saveMode)
                                nameField.text = fileName
                        }
                    }
                    onDoubleClicked: {
                        if (fileIsDir)
                            root.currentFolder = fileURL
                        else
                            root.acceptSelection()
                    }

                    contentItem: RowLayout {
                        spacing: 10
                        Label {
                            text: rowDelegate.fileIsDir ? "\uD83D\uDCC1" : "\uD83D\uDDBC\uFE0F"
                            font.pixelSize: 18
                        }
                        Label {
                            Layout.fillWidth: true
                            text: rowDelegate.fileName
                            color: Material.foreground
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: folderModel.count === 0
                         && folderModel.status === FolderListModel.Ready
                text: qsTr("This folder is empty")
                color: root.mutedColor
            }
        }

        // File name entry (save mode only).
        RowLayout {
            visible: root.saveMode
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 10
            spacing: 10

            Label {
                text: qsTr("File name")
                color: root.mutedColor
            }
            TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: qsTr("File name")
                onAccepted: root.acceptSelection()
            }
        }

        // Actions.
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 10

            Button {
                flat: true
                text: qsTr("Cancel")
                Accessible.name: qsTr("Cancel")
                onClicked: root.close()
            }
            Item { Layout.fillWidth: true }
            Button {
                text: root.saveMode ? qsTr("Save") : qsTr("Open")
                Accessible.name: text
                enabled: root.canAccept
                Material.background: enabled ? root.primaryColor
                    : Qt.rgba(root.mutedColor.r, root.mutedColor.g, root.mutedColor.b, 0.16)
                Material.foreground: enabled ? root.primaryTextColor : root.mutedColor
                onClicked: root.acceptSelection()
            }
        }
    }
}
