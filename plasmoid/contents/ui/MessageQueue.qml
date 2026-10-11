import QtQuick

/*
 * The length of this queue is 2. The queue rejects new
 * messages before the images of old messages are loaded.
 */

Item {
    // When only spectrum data is enabled, receive raw data to reduce cpu usage.
    property bool only_spectrum: false

    property PreloadingTextures imgsReady: pt0

    property PreloadingTextures imgsLoading: pt0

    function push(message) {
        if (message.length < 1) {
            imgsReady = nt
            return
        }
        if (!imgsLoading.used)
            return

        imgsLoading.used = false
        if (only_spectrum) {
            imgsLoading.s.source = 'data:' + message
        } else {
            const obj = JSON.parse(message)
            imgsLoading.s.source = obj.spectrum ? 'data:' + obj.spectrum : ''
            imgsLoading.w.source = 'data:' + obj.wave
            imgsLoading.beat = obj.beat
        }

        // Images may be loaded synchronously, in which case ready never changes.
        if (imgsLoading.ready)
            loaded(imgsLoading)
    }

    function loaded(textures) {
        imgsReady = textures
        imgsLoading = textures === pt0 ? pt1 : pt0
        imgsLoading.used = true
    }

    PreloadingTextures { id: nt; audioAvailable: false }

    PreloadingTextures { id: pt0; onReadyChanged: if (ready) loaded(pt0) }

    PreloadingTextures { id: pt1; onReadyChanged: if (ready) loaded(pt1) }

}
