import QtQuick
import Qt5Compat.GraphicalEffects

// A monochrome icon tinted with `color`. Only the source's alpha channel is
// used, so the stroke/fill colour baked into the SVG is ignored — this lets a
// single icon file follow the active theme and selected-state colours.
//
// The tint is applied by ColorOverlay on every repaint. Caching the tinted
// result in a `live: false` ShaderEffectSource turned out to be unsafe: when
// the icon is hidden and re-shown (a Popup closing/reopening, or a ListView
// delegate being recycled) the cached framebuffer is stale and the icon simply
// disappears. The overlay shader is cheap (a single texture sample multiplied
// by a colour), so we render it live and stay correct everywhere.
Item {
    id: icon
    property alias source: image.source
    property color color: "#000000"
    property real size: 22

    implicitWidth: size
    implicitHeight: size

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    ColorOverlay {
        id: overlay
        anchors.fill: parent
        source: image
        color: icon.color
    }
}
