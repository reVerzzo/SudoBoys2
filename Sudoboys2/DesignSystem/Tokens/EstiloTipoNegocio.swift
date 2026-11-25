import SwiftUI

/// Color de cada tipo de negocio en pines y tarjetas:
/// estética en durazno, veterinaria en jade y "ambos" en ciruela.
/// Cada fondo va con su color de ícono para cumplir contraste.
extension TipoNegocio {
    var colorFondo: Color {
        switch self {
        case .estetica: Color.app.acento
        case .veterinaria: Color.app.saludTexto
        case .ambos: Color.app.primario
        }
    }

    var colorIcono: Color {
        switch self {
        case .estetica: Color.app.textoSobreAcento
        case .veterinaria: Color.app.textoSobreSalud
        case .ambos: Color.app.textoSobrePrimario
        }
    }
}
