import SwiftUI

/// Resortes de la app. Nunca animaciones lineales.
struct AnimacionesApp {
    /// Resorte por defecto para cambios de estado y selección.
    let resorte = Animation.spring(duration: 0.4, bounce: 0.2)
    /// Movimiento suave sin rebote, para contenido que cambia de tamaño.
    let suave = Animation.smooth
    /// Resorte corto para la respuesta al presionar.
    let rapida = Animation.spring(duration: 0.25, bounce: 0.15)
}

extension Animation {
    /// Animaciones de la app: `Animation.app.resorte`…
    static let app = AnimacionesApp()
}

/// Respuesta al presionar: se encoge un poco y se atenúa con resorte.
/// Con "Reducir movimiento" solo se atenúa.
struct EstiloPresionable: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reducirMovimiento ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Animation.app.rapida, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == EstiloPresionable {
    static var presionable: EstiloPresionable { EstiloPresionable() }
}
