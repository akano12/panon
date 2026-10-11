import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    // Always show the spectrum inline, never as a popup.
    preferredRepresentation: fullRepresentation
    fullRepresentation: Spectrum {}

    toolTipMainText: Plasmoid.configuration.hideTooltip ? "" : Plasmoid.title
    toolTipSubText: Plasmoid.configuration.hideTooltip ? "" : Plasmoid.metaData.description

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
}
