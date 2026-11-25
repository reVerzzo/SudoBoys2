import SwiftUI

/// Para pantallas con el título dentro del contenido: al desplazar, la barra de
/// navegación toma fondo y muestra el título, así el contenido no se encima con
/// la barra de estado ni con el botón de regreso. Aplícalo al `ScrollView`.
private struct BarraAlDesplazar: ViewModifier {
    let titulo: String
    /// Puntos desplazados a partir de los cuales el título del contenido ya quedó oculto.
    let umbral: CGFloat

    @State private var desplazado = false

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self) { geometria in
                geometria.contentOffset.y + geometria.contentInsets.top > umbral
            } action: { _, nuevo in
                desplazado = nuevo
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(titulo)
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .lineLimit(1)
                        .opacity(desplazado ? 1 : 0)
                        .accessibilityHidden(!desplazado)
                }
            }
            .toolbarBackground(Color.app.fondo, for: .navigationBar)
            .toolbarBackgroundVisibility(desplazado ? .visible : .hidden, for: .navigationBar)
            .animation(Animation.app.rapida, value: desplazado)
    }
}

extension View {
    func barraAlDesplazar(titulo: String, umbral: CGFloat = 56) -> some View {
        modifier(BarraAlDesplazar(titulo: titulo, umbral: umbral))
    }
}
