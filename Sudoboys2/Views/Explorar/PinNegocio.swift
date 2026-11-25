import SwiftUI

/// Anotación del mapa: círculo con el color del tipo de negocio y sello si está verificado.
struct PinNegocio: View {
    let tipo: TipoNegocio
    let verificado: Bool
    let seleccionado: Bool

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    var body: some View {
        Image(systemName: tipo.icono)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tipo.colorIcono)
            .frame(width: 34, height: 34)
            .background(tipo.colorFondo, in: Circle())
            .overlay {
                Circle().strokeBorder(Color.app.superficie, lineWidth: 2)
            }
            .overlay(alignment: .topTrailing) {
                if verificado {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.app.saludTexto)
                        .background(Color.app.superficie, in: Circle())
                        .offset(x: 5, y: -5)
                }
            }
            .shadow(color: Color.app.primario.opacity(0.18), radius: 4, y: 2)
            .scaleEffect(seleccionado && !reducirMovimiento ? 1.3 : 1, anchor: .bottom)
            .opacity(seleccionado || !reducirMovimiento ? 1 : 0.85)
            .animation(Animation.app.resorte, value: seleccionado)
            .accessibilityHidden(true)
    }
}

#Preview("Claro") {
    VistaPreviaPines()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaPines()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaPines: View {
    var body: some View {
        HStack(spacing: Espaciado.l) {
            PinNegocio(tipo: .estetica, verificado: false, seleccionado: false)
            PinNegocio(tipo: .veterinaria, verificado: true, seleccionado: false)
            PinNegocio(tipo: .ambos, verificado: true, seleccionado: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
