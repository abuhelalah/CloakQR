import QtQuick
import QtQuick.Controls.impl

// A monochrome icon tinted with `color`. IconImage renders the source using
// only its alpha channel and fills it with `color`, so the stroke/fill colour
// baked into the SVG is ignored — a single icon file can follow the active
// theme and selected-state colours.
//
// This replaces the old ColorOverlay from Qt5Compat.GraphicalEffects, which is
// an optional Qt installer component and was absent on the Windows build
// machine. IconImage lives in QtQuick.Controls.impl (available in every Qt 6
// install), needs no shader code, and works identically on every platform and
// rendering backend (OpenGL, D3D, Metal, Vulkan).
Item {
    id: icon
    property alias source: iconImage.source
    property color color: "#000000"
    property real size: 22

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: iconImage
        anchors.fill: parent
        color: icon.color
        fillMode: Image.PreserveAspectFit
    }
}
