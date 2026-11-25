import SwiftUI

/// Fondo de encabezado con `MeshGradient` muy suave en ciruela, jade y durazno.
/// Se desvanece hacia `fondo` en la parte baja para fundirse con la pantalla.
struct FondoMalla: View {
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.6, 0.45], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: [
                Color.app.primarioTinte.opacity(0.22), Color.app.salud.opacity(0.20), Color.app.acento.opacity(0.26),
                Color.app.salud.opacity(0.24), Color.app.acento.opacity(0.14), Color.app.primarioTinte.opacity(0.16),
                .clear, .clear, .clear,
            ]
        )
        .background(Color.app.fondo)
        .accessibilityHidden(true)
    }
}

#Preview("Claro") {
    FondoMalla()
        .frame(height: 320)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.app.fondo)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    FondoMalla()
        .frame(height: 320)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.app.fondo)
        .preferredColorScheme(.dark)
}
