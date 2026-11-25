import SwiftUI

/// Elevación de tarjetas: sombra suave en claro; en oscuro, borde de 1 pt.
private struct ElevacionTarjeta: ViewModifier {
    @Environment(\.colorScheme) private var esquema
    let radio: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                if esquema == .dark {
                    RoundedRectangle(cornerRadius: radio, style: .continuous)
                        .strokeBorder(Color.app.borde, lineWidth: 1)
                }
            }
            .shadow(
                color: esquema == .dark ? .clear : Color.app.primario.opacity(0.08),
                radius: 16,
                y: 4
            )
    }
}

extension View {
    /// Sombra suave en modo claro y borde `borde` en modo oscuro.
    func elevacionTarjeta(radio: CGFloat = Radio.tarjeta) -> some View {
        modifier(ElevacionTarjeta(radio: radio))
    }
}
