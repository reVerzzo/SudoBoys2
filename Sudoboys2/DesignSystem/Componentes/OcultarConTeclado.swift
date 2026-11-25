import SwiftUI
import UIKit

/// Oculta una barra inferior mientras el teclado está visible, para que no tape el formulario.
private struct OcultarConTeclado: ViewModifier {
    @State private var tecladoVisible = false
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    func body(content: Content) -> some View {
        Group {
            if !tecladoVisible {
                // Entra y sale deslizándose, nunca con fundido: una barra a medio fundir
                // deja ver la lista que pasa por detrás y su texto se encima con ella.
                content.transition(reducirMovimiento ? .identity : .move(edge: .bottom))
            }
        }
        .clipped()
        .animation(Animation.app.rapida, value: tecladoVisible)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            tecladoVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            tecladoVisible = false
        }
    }
}

extension View {
    /// Para barras de acción en `safeAreaInset(edge: .bottom)` de formularios con campos de texto.
    func ocultarConTeclado() -> some View {
        modifier(OcultarConTeclado())
    }
}
