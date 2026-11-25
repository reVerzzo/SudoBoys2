import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Títulos de la barra de navegación con diseño redondeado y `textoPrincipal`.
/// SwiftUI no expone la fuente del título de navegación, así que se configura
/// una sola vez con la apariencia de UIKit, al arrancar la app.
enum EstiloNavegacion {
    static func aplicar() {
        #if canImport(UIKit) && !os(watchOS)
        let color = UIColor(resource: .textoPrincipal)
        let barra = UINavigationBar.appearance()
        barra.largeTitleTextAttributes = [
            .font: fuenteRedondeada(estilo: .largeTitle, peso: .bold),
            .foregroundColor: color,
        ]
        barra.titleTextAttributes = [
            .font: fuenteRedondeada(estilo: .headline, peso: .semibold),
            .foregroundColor: color,
        ]
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    private static func fuenteRedondeada(estilo: UIFont.TextStyle, peso: UIFont.Weight) -> UIFont {
        let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: estilo)
        let conPeso = UIFont.systemFont(ofSize: base.pointSize, weight: peso).fontDescriptor
        let descriptor = conPeso.withDesign(.rounded) ?? conPeso
        return UIFont(descriptor: descriptor, size: base.pointSize)
    }
    #endif
}
