import QtQuick

// A monochrome icon tinted with `color`. Only the source's alpha channel is
// used, so the stroke/fill colour baked into the SVG is ignored — this lets a
// single icon file follow the active theme and selected-state colours.
//
// The tint is applied by a small ShaderEffect that multiplies the source alpha
// by the requested colour. We render it ourselves instead of using the
// deprecated Qt5Compat.GraphicalEffects ColorOverlay because that module is an
// optional installer component that may be missing (it was absent on the
// Windows build machine), whereas ShaderEffect ships with QtQuick itself.
// (QtQuick.Effects.MultiEffect is unsuitable here: its colorization is
// luminance based, so a solid-black icon would stay black.)
//
// Caching the tinted result in a `live: false` ShaderEffectSource turned out
// to be unsafe: when the icon is hidden and re-shown (a Popup
// closing/reopening, or a ListView delegate being recycled) the cached
// framebuffer is stale and the icon simply disappears. The tint shader is cheap
// (a single texture sample multiplied by a colour), so we render it live and
// stay correct everywhere.
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

    // Renders the (hidden) source Image into a texture so the ShaderEffect can
    // sample its alpha channel. Hidden here because only the ShaderEffect below
    // should be displayed.
    ShaderEffectSource {
        id: proxy
        anchors.fill: parent
        sourceItem: image
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        property var src: proxy
        property color tint: icon.color
        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D src;
            uniform lowp vec4 tint;
            uniform lowp float qt_Opacity;
            void main() {
                lowp float a = texture2D(src, qt_TexCoord0).a;
                gl_FragColor = tint * a * qt_Opacity;
            }"
    }
}
