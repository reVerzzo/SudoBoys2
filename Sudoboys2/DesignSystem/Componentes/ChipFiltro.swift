import SwiftUI

/// Chip de filtro con estado seleccionado. Cambia con resorte y haptic de selección.
struct ChipFiltro: View {
    let titulo: String
    var icono: String?
    let seleccionado: Bool
    let accion: () -> Void

    /// Ancho común del ícono y la palomita, para que el chip no cambie de ancho al seleccionarse.
    @ScaledMetric(relativeTo: .subheadline) private var anchoIcono: CGFloat = 20

    init(_ titulo: String, icono: String? = nil, seleccionado: Bool, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.icono = icono
        self.seleccionado = seleccionado
        self.accion = accion
    }

    var body: some View {
        Button(action: accion) {
            HStack(spacing: Espaciado.xxs) {
                if let icono {
                    Image(systemName: seleccionado ? "checkmark" : icono)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: anchoIcono)
                        .accessibilityHidden(true)
                }
                Text(titulo)
                    .lineLimit(1)
            }
            .font(Font.app.subtitulo.weight(.medium))
            .foregroundStyle(seleccionado ? Color.app.textoSobrePrimario : Color.app.textoPrincipal)
            .padding(.horizontal, Espaciado.s)
            .padding(.vertical, Espaciado.xs)
            .frame(minHeight: 36)
            .background(
                seleccionado ? Color.app.primario : Color.app.superficieElevada,
                in: Capsule()
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.presionable)
        .animation(Animation.app.resorte, value: seleccionado)
        .sensoryFeedback(.selection, trigger: seleccionado)
        .accessibilityAddTraits(seleccionado ? .isSelected : [])
    }
}

#Preview("Claro") {
    VistaPreviaChipFiltro()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaChipFiltro()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaChipFiltro: View {
    @State private var veterinaria = true
    @State private var estetica = false
    @State private var abierto = false

    var body: some View {
        HStack(spacing: Espaciado.xs) {
            ChipFiltro("Veterinaria", icono: "stethoscope", seleccionado: veterinaria) {
                veterinaria.toggle()
            }
            ChipFiltro("Estética", icono: "scissors", seleccionado: estetica) {
                estetica.toggle()
            }
            ChipFiltro("Abierto ahora", seleccionado: abierto) {
                abierto.toggle()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
