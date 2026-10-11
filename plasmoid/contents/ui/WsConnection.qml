import QtQuick
import QtWebSockets
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import "utils.js" as Utils
/*
 * This module starts a python back-end client,
 * and pushes messages from the client to a queue.
 *
 * A queue is required to store new data sent from the
 * audio back-end. Because if new audio data is used
 * directly as an image by the shaders, those images
 * may be used before they are loaded, which will cause
 * flickering problems.
 */
Item {

    readonly property var cfg: Plasmoid.configuration

    property MessageQueue queue

    property ShaderSource shaderSource

    WebSocketServer {
        id: server
        listen: true
        onClientConnected: webSocket => {
            webSocket.onTextMessageReceived.connect(message => queue.push(message))
        }
    }

    readonly property string startBackEnd: {
        if (server.port == 0) return ''
        if (shaderSource.image_shader_source.toString() == '') return ''
        const backend = ['pyaudio', 'soundcard', 'fifo'][cfg.backendIndex]
        const args = [server.url.toString(), '--backend=' + backend]
        if (backend == 'soundcard')
            args.push('--device=' + cfg.pulseaudioDevice)
        if (backend == 'fifo')
            args.push('--fifo-path=' + cfg.fifoPath)
        args.push('--fps=' + cfg.fps)
        if (cfg.reduceBass)
            args.push('--reduce-bass')
        args.push('--bass-resolution-level=' + cfg.bassResolutionLevel)
        if (shaderSource.enable_iChannel0)
            args.push('--enable-wave-data')
        if (shaderSource.enable_iChannel1)
            args.push('--enable-spectrum-data')
        const cmd = Utils.pythonCommand('panon.backend.client', args)
        if (cfg.debugBackend) {
            // Let the user start the back-end manually to see its output.
            console.log('Executing: ' + cmd)
            return ''
        }
        return cmd
    }

    P5Support.DataSource {
        engine: 'executable'
        connectedSources: startBackEnd ? [startBackEnd] : []
        onNewData: (sourceName, data) => {
            // Show back-end errors.
            console.log(data.stdout)
            console.log(data.stderr)
        }
    }

}
