import SwiftUI

/// Escala de espaciado 4/8/12/16/24/32.
enum Espaciado {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    /// Margen horizontal de las pantallas.
    static let margenPantalla: CGFloat = 20
}

/// Radios de esquina. Siempre con estilo `.continuous`.
enum Radio {
    static let chip: CGFloat = 12
    static let control: CGFloat = 16
    static let tarjeta: CGFloat = 20
    static let hoja: CGFloat = 24
}

/// Formas base con esquinas continuas.
enum Forma {
    static let chip = RoundedRectangle(cornerRadius: Radio.chip, style: .continuous)
    static let control = RoundedRectangle(cornerRadius: Radio.control, style: .continuous)
    static let tarjeta = RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
    static let hoja = RoundedRectangle(cornerRadius: Radio.hoja, style: .continuous)
}
