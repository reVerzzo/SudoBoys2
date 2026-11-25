import SwiftUI

/// Paleta 60/30/10 de la app. Cada token es un Color Set del asset catalog
/// (`Assets.xcassets/Colores`) con variante clara y oscura.
/// Se usa como `Color.app.fondo`; nunca hex sueltos en las vistas.
struct PaletaApp {
    // 60 %: fondos y superficies
    /// Fondo de pantallas.
    let fondo = Color(ColorResource.fondo)
    /// Tarjetas y hojas.
    let superficie = Color(ColorResource.superficie)
    /// Avatares, campos y chips inactivos.
    let superficieElevada = Color(ColorResource.superficieElevada)
    /// Separadores; en oscuro sustituye a la sombra.
    let borde = Color(ColorResource.borde)

    // Texto
    /// Títulos y texto.
    let textoPrincipal = Color(ColorResource.textoPrincipal)
    /// Subtítulos y metadatos.
    let textoSecundario = Color(ColorResource.textoSecundario)

    // 30 %: primario y salud
    /// Fondo de botón principal (texto blanco).
    let primario = Color(ColorResource.primario)
    /// Íconos, enlaces, selección y tint de la app.
    let primarioTinte = Color(ColorResource.primarioTinte)
    /// Rellenos grandes, íconos de salud y gráficas.
    let salud = Color(ColorResource.salud)
    /// Texto verde e insignias de salud.
    let saludTexto = Color(ColorResource.saludTexto)

    // 10 %: acento
    /// Botones destacados (texto `textoSobreAcento`, nunca blanco).
    let acento = Color(ColorResource.acento)
    /// Texto o enlaces en tono durazno.
    let acentoTexto = Color(ColorResource.acentoTexto)
    /// Calificaciones.
    let estrellas = Color(ColorResource.estrellas)

    // Texto sobre rellenos de color (combinaciones con contraste AA)
    /// Texto sobre `primario`: blanco en ambos modos.
    let textoSobrePrimario = Color.white
    /// Texto sobre `acento`.
    let textoSobreAcento = Color(ColorResource.textoSobreAcento)
    /// Texto sobre `saludTexto`.
    let textoSobreSalud = Color(ColorResource.textoSobreSalud)
}

extension Color {
    /// Tokens de color de la app: `Color.app.fondo`, `Color.app.primario`…
    static let app = PaletaApp()
}
