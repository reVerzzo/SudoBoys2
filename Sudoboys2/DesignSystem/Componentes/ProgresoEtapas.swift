import SwiftUI

/// Avance de una cita por etapas: completadas en jade, la actual con un pulso suave.
struct ProgresoEtapas: View {
    let etapas: [EtapaCita]
    /// `nil` = aún sin check-in.
    let actual: EtapaCita?
    var mostrarTitulos = true

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @ScaledMetric(relativeTo: .caption) private var lado: CGFloat = 36

    private var indiceActual: Int? { actual.flatMap { etapas.firstIndex(of: $0) } }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(etapas.enumerated()), id: \.element) { indice, etapa in
                VStack(spacing: Espaciado.xxs) {
                    ZStack {
                        HStack(spacing: 0) {
                            linea(activa: indice <= (indiceActual ?? -1), visible: indice > 0)
                            linea(activa: indice < (indiceActual ?? -1), visible: indice < etapas.count - 1)
                        }
                        circulo(etapa, indice: indice)
                    }
                    if mostrarTitulos {
                        Text(etapa.titulo)
                            .font(.caption2.weight(indice == indiceActual ? .semibold : .regular))
                            .foregroundStyle(indice == indiceActual ? Color.app.textoPrincipal : Color.app.textoSecundario)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(Animation.app.resorte, value: actual)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(etiqueta)
    }

    private var etiqueta: String {
        guard let actual, let indiceActual else { return "Aún sin llegar" }
        return "Etapa \(actual.titulo), \(indiceActual + 1) de \(etapas.count)"
    }

    private func linea(activa: Bool, visible: Bool) -> some View {
        Capsule()
            .fill(activa ? Color.app.salud : Color.app.borde)
            .frame(height: 3)
            .opacity(visible ? 1 : 0)
    }

    @ViewBuilder
    private func circulo(_ etapa: EtapaCita, indice: Int) -> some View {
        let alcanzada = indice <= (indiceActual ?? -1)
        let esActual = indice == indiceActual
        Image(systemName: etapa.icono)
            .font(.caption.weight(.semibold))
            .foregroundStyle(alcanzada ? Color.app.textoSobreSalud : Color.app.textoSecundario)
            .frame(width: lado, height: lado)
            .background(alcanzada ? Color.app.saludTexto : Color.app.superficieElevada, in: Circle())
            .symbolEffect(.bounce, value: esActual)
            .background {
                if esActual, etapa != .listo, !reducirMovimiento {
                    Circle()
                        .fill(Color.app.salud)
                        .phaseAnimator([false, true]) { contenido, fase in
                            contenido
                                .scaleEffect(fase ? 1.45 : 1)
                                .opacity(fase ? 0 : 0.45)
                        } animation: { fase in
                            fase ? .easeOut(duration: 1.4) : .easeOut(duration: 0.01)
                        }
                }
            }
    }
}

#Preview("Claro") {
    VistaPreviaProgreso().preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaProgreso().preferredColorScheme(.dark)
}

private struct VistaPreviaProgreso: View {
    @State private var indice = 1
    private let etapas = EtapaCita.flujo(para: .estetica)

    var body: some View {
        VStack(spacing: Espaciado.l) {
            TarjetaApp { ProgresoEtapas(etapas: etapas, actual: etapas[indice]) }
            TarjetaApp { ProgresoEtapas(etapas: EtapaCita.flujo(para: .veterinaria), actual: nil) }
            BotonPrincipal("Avanzar") { indice = (indice + 1) % etapas.count }
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
