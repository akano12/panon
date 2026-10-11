import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support

import "../utils.js" as Utils

KCM.SimpleKCM {

    property alias cfg_reduceBass: reduceBass.checked
    property alias cfg_debugBackend: debugBackend.checked

    property alias cfg_bassResolutionLevel: bassResolutionLevel.currentIndex

    property alias cfg_backendIndex: backend.currentIndex

    property alias cfg_fifoPath: fifoPath.text

    property string cfg_pulseaudioDevice

    // The indices of these levels are used by spectrum.py.
    // ranges: [from Hz, to Hz, latency in ms]
    readonly property var bassResolutionLevels: [
        { text: '0 to 22,050Hz', ranges: [[0, 22050, 16]] },
        { text: '0 to 9,000Hz', ranges: [[0, 600, 133], [600, 1800, 100], [1800, 3000, 83], [3000, 4800, 66], [4800, 6600, 50], [6600, 9000, 33]] },
        { text: '0 to 3,000Hz (F7)', ranges: [[0, 600, 200], [600, 1800, 133], [1800, 3000, 66]] },
        { text: '0 to 1,800Hz (A6) with higher resolution', ranges: [[0, 600, 266], [600, 1800, 200]] },
        { text: '0 to 1,800Hz (A6) with lower latency', ranges: [[0, 1800, 100]] },
        { text: '300 to 1,800Hz (A6) (filter out bass)', ranges: [[300, 1800, 100]] },
        { text: '0 to 600Hz (D5)', ranges: [[0, 600, 266]] },
    ]

    Kirigami.FormLayout {

        QQC2.ComboBox {
            id: backend
            Kirigami.FormData.label: i18n("Back-end:")
            model: ['PortAudio', 'PulseAudio', 'fifo']
        }

        QQC2.ComboBox {
            id: pulseaudioDevice
            Kirigami.FormData.label: i18n("Input device:")
            visible: backend.currentText == 'PulseAudio'
            model: ListModel {
                id: pdItems
            }
            textRole: 'name'
            onActivated: cfg_pulseaudioDevice = pdItems.get(currentIndex).id
        }

        QQC2.TextField {
            id: fifoPath
            Kirigami.FormData.label: i18n("Fifo path:")
            visible: backend.currentText == 'fifo'
        }

        QQC2.CheckBox {
            id: reduceBass
            text: i18nc("@option:check", "Reduce the weight of bass")
        }

        QQC2.CheckBox {
            id: debugBackend
            text: i18nc("@option:check", "Debug")
        }

        QQC2.ComboBox {
            id: bassResolutionLevel
            Kirigami.FormData.label: i18n("Audio frequency:")
            model: bassResolutionLevels
            textRole: 'text'
        }

        QQC2.Label {
            onLinkActivated: link => Qt.openUrlExternally(link)
            text: "<a href='https://www.szynalski.com/tone-generator/' >" + i18n("Test your audio frequency.") + "</a>"
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Latency / resolution:")
            textFormat: Text.RichText
            text: {
                const level = bassResolutionLevels[bassResolutionLevel.currentIndex]
                if (!level)
                    return ''
                return '<table>' + level.ranges.map(([from, to, latency]) =>
                    '<tr><td>' + from.toLocaleString() + '</td><td>~</td><td>'
                    + to.toLocaleString()
                    + 'Hz</td><td> - </td><td>' + latency + 'ms / '
                    + Math.ceil((to - from) * latency / 1000) + 'px</td></tr>').join('') + '</table>'
            }
        }
    }

    P5Support.DataSource {
        engine: 'executable'
        connectedSources: [Utils.pythonCommand('panon.backend.get_pa_devices')]
        onNewData: (sourceName, data) => {
            pdItems.append({ name: 'default', id: 'default' })
            const lst = JSON.parse(data.stdout || '[]')
            for (const device of lst)
                pdItems.append(device)
            if (lst.length > 1) {
                pdItems.append({ name: i18n("Monitor of Current Device"), id: 'smart' })
                pdItems.append({ name: i18n("Mixing All Speakers"), id: 'allspeakers' })
                pdItems.append({ name: i18n("Mixing All Microphones"), id: 'allmicrophones' })
                pdItems.append({ name: i18n("Mixing All Microphones and Speakers"), id: 'all' })
            }

            for (let i = 0; i < pdItems.count; i++)
                if (pdItems.get(i).id == cfg_pulseaudioDevice)
                    pulseaudioDevice.currentIndex = i
            disconnectSource(sourceName)
        }
    }
}
