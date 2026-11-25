import SwiftUI

/// Tipografía de la app: SF Pro con diseño redondeado en títulos para un tono
/// cálido y estilos semánticos en todo lo demás, para respetar Dynamic Type.
struct TipografiaApp {
    // Títulos (redondeados)
    let tituloGrande = Font.system(.largeTitle, design: .rounded, weight: .bold)
    let titulo = Font.system(.title, design: .rounded, weight: .bold)
    let titulo2 = Font.system(.title2, design: .rounded, weight: .semibold)
    let titulo3 = Font.system(.title3, design: .rounded, weight: .semibold)
    let encabezado = Font.system(.headline, design: .rounded)

    // Texto
    let cuerpo = Font.body
    let cuerpoDestacado = Font.body.weight(.semibold)
    let subtitulo = Font.subheadline
    let nota = Font.footnote
    let etiqueta = Font.caption.weight(.medium)
}

extension Font {
    /// Estilos de texto de la app: `Font.app.titulo`, `Font.app.cuerpo`…
    static let app = TipografiaApp()
}
