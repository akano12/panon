import QtQuick

Item {

    property alias w: wave
    property alias s: spectrum
    property double beat

    readonly property bool ready: wave.status != Image.Loading && spectrum.status != Image.Loading
    property bool used: true
    property bool audioAvailable: true

    Image { id: wave; visible: false; cache: false }
    Image { id: spectrum; visible: false; cache: false }
}
