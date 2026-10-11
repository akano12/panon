import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root
    // The saved configuration, with the unapplied changes of the configuration dialog on top.
    readonly property var cfg: {
        const config = Plasmoid.configuration
        const values = {}
        for (const key of config.keys())
            values[key] = config[key]
        return Object.assign(values, config.livePreview)    // see config/ConfigPreview.qml
    }

    readonly property bool vertical: Plasmoid.formFactor == PlasmaCore.Types.Vertical

    property bool audioAvailable
    property string fps_message: ""

    property double time_first_frame: Date.now()
    property double time_fps_start: Date.now()
    property double time_prev_frame: Date.now()

    Layout.preferredWidth: vertical ? -1 : animatedMinimum
    Layout.preferredHeight: vertical ? animatedMinimum : -1
    Layout.maximumWidth: cfg.autoHide ? Layout.preferredWidth : -1
    Layout.maximumHeight: cfg.autoHide ? Layout.preferredHeight : -1

    // Gravity property: Center(0), North (1), South (2), East (3), West (4)
    readonly property int gravity: {
        if (cfg.gravity > 0)
            return cfg.gravity
        switch (Plasmoid.location) {
        case PlasmaCore.Types.TopEdge:
            return 2
        case PlasmaCore.Types.RightEdge:
            return 3
        case PlasmaCore.Types.LeftEdge:
            return 4
        }
        return 1
    }

    property int animatedMinimum: !cfg.autoHide || audioAvailable ? cfg.preferredWidth : 0

    Behavior on animatedMinimum {
        enabled: cfg.animateAutoHiding
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }

    Layout.fillWidth: !vertical && cfg.autoExtend
    Layout.fillHeight: vertical && cfg.autoExtend

    ShaderEffect {
        id: mainSE

        Behavior on hueFrom { NumberAnimation { duration: 1000 } }
        Behavior on hueTo { NumberAnimation { duration: 1000 } }
        Behavior on saturation { NumberAnimation { duration: 1000 } }
        Behavior on lightness { NumberAnimation { duration: 1000 } }

        // Color space: HSL (0), HSLuv (1)
        readonly property int colorSpace: cfg.colorSpaceHSLuv ? 1 : 0
        property int hueFrom: cfg.colorSpaceHSLuv ? cfg.hsluvHueFrom : cfg.hslHueFrom
        property int hueTo: cfg.colorSpaceHSLuv ? cfg.hsluvHueTo : cfg.hslHueTo
        property int saturation: cfg.colorSpaceHSLuv ? cfg.hsluvSaturation : cfg.hslSaturation
        property int lightness: cfg.colorSpaceHSLuv ? cfg.hsluvLightness : cfg.hslLightness

        readonly property vector4d iMouse: iMouseArea.i

        property double iTime
        property double iTimeDelta
        property double iBeat
        readonly property vector3d iResolution: root.gravity <= 2 ? Qt.vector3d(mainSE.width, mainSE.height, 0) : Qt.vector3d(mainSE.height, mainSE.width, 0)
        property int iFrame: 0
        readonly property vector3d iChannelResolution0: textureResolution(iChannel0)
        readonly property vector3d iChannelResolution1: textureResolution(iChannel1)
        readonly property vector3d iChannelResolution2: textureResolution(iChannel2)
        readonly property vector3d iChannelResolution3: textureResolution(iChannel3)
        property Item iChannel0
        property Item iChannel1
        readonly property Item iChannel2: bufferSES
        readonly property Item iChannel3: Image {
            visible: false
            source: shaderSourceReader.texture_uri
        }

        function textureResolution(item) {
            return item ? Qt.vector3d(item.width, item.height, 0) : Qt.vector3d(0, 0, 0)
        }

        readonly property int coord_gravity: root.gravity
        readonly property int coord_inversion: cfg.inversion ? 1 : 0

        anchors.fill: parent
        // Avoid rendering with Qt's default shader before the effect is built.
        visible: shaderSourceReader.loaded
        blending: true
        fragmentShader: shaderSourceReader.image_shader_source
    }

    ShaderEffectSource {
        id: bufferSES
        visible: false
        width: mainSE.iResolution.x
        height: mainSE.iResolution.y
        recursive: true
        live: false
        sourceItem: shaderSourceReader.enable_buffer ? bufferSE : null
    }

    ShaderEffect {
        id: bufferSE
        visible: false
        width: mainSE.iResolution.x
        height: mainSE.iResolution.y

        readonly property double iTime: mainSE.iTime
        readonly property double iTimeDelta: mainSE.iTimeDelta
        readonly property double iBeat: mainSE.iBeat
        readonly property vector3d iResolution: mainSE.iResolution
        readonly property int iFrame: mainSE.iFrame
        readonly property vector3d iChannelResolution0: mainSE.iChannelResolution0
        readonly property vector3d iChannelResolution1: mainSE.iChannelResolution1
        readonly property vector3d iChannelResolution2: mainSE.iChannelResolution2
        readonly property vector3d iChannelResolution3: mainSE.iChannelResolution3
        readonly property Item iChannel0: mainSE.iChannel0
        readonly property Item iChannel1: mainSE.iChannel1
        readonly property Item iChannel2: mainSE.iChannel2
        readonly property Item iChannel3: mainSE.iChannel3
        readonly property vector4d iMouse: mainSE.iMouse
        fragmentShader: shaderSourceReader.buffer_shader_source
    }

    readonly property string error_message: {
        if (shaderSourceReader.error_message)
            return shaderSourceReader.error_message
        if (!shaderSourceReader.loaded)
            return i18n("Error: Failed to load the visual effect. Please choose another visual effect in the configuration dialog.")
        if (mainSE.status == ShaderEffect.Error)
            return i18n("Error: Failed to compile image shader.") + mainSE.log
        if (shaderSourceReader.enable_buffer && bufferSE.status == ShaderEffect.Error)
            return i18n("Error: Failed to compile buffer shader.") + bufferSE.log
        return wsConnection.error_message
    }

    PlasmaComponents.Label {
        anchors.fill: parent
        text: error_message + (cfg.showFps ? fps_message : "")
        wrapMode: Text.Wrap
    }

    MouseArea {
        id: iMouseArea
        hoverEnabled: true
        anchors.fill: parent

        readonly property double current_x: root.gravity < 3 ? (cfg.inversion ? (mainSE.width - mouseX) : mouseX) : (cfg.inversion ? mouseY : (mainSE.height - mouseY))
        readonly property double current_y: [mainSE.height - mouseY, mouseY, mainSE.width - mouseX, mouseX][root.gravity - 1]
        property double lastdown_x
        property double lastdown_y
        property double lastclick_x
        property double lastclick_y

        readonly property vector4d i: Qt.vector4d(lastdown_x, lastdown_y, pressed ? lastclick_x : -lastclick_x, -lastclick_y)
        onPressed: {
            lastclick_x = current_x
            lastclick_y = current_y

            lastdown_x = current_x
            lastdown_y = current_y
        }
        onPositionChanged: {
            if (pressed) {
                lastdown_x = current_x
                lastdown_y = current_y
            }
        }
    }

    ShaderSource {
        id: shaderSourceReader
        cfg: root.cfg
    }

    MessageQueue {
        id: messageQueue
        onImgsReadyChanged: {
            audioAvailable = imgsReady.audioAvailable
            const time_current_frame = Date.now()
            mainSE.iTime = (time_current_frame - time_first_frame) / 1000.0
            mainSE.iTimeDelta = (time_current_frame - time_prev_frame) / 1000.0
            mainSE.iFrame += 1
            if (cfg.showFps && mainSE.iFrame % 30 == 1) {
                fps_message = 'fps:' + Math.round(1000 * 30 / (time_current_frame - time_fps_start))
                time_fps_start = time_current_frame
            }

            mainSE.iChannel0 = imgsReady.wave
            mainSE.iChannel1 = imgsReady.spectrum
            mainSE.iBeat = imgsReady.beat
            if (shaderSourceReader.enable_buffer)
                bufferSES.scheduleUpdate()

            time_prev_frame = time_current_frame
        }
    }

    WsConnection {
        id: wsConnection
        cfg: root.cfg
        shaderSource: shaderSourceReader
        queue: messageQueue
    }
}
