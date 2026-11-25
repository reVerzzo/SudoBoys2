import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity de una cita en curso: etapas, mascota y tiempo estimado.
/// La app la actualiza localmente con ActivityKit (sin push).
struct SudoboysWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CitaActivityAttributes.self) { context in
            VistaPantallaBloqueo(atributos: context.attributes, estado: context.state)
                .activityBackgroundTint(Color(.fondo))
                .activitySystemActionForegroundColor(Color(.textoPrincipal))
        } dynamicIsland: { context in
            let atributos = context.attributes
            let estado = context.state
            let etapa = atributos.etapaActual(estado)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(atributos.nombreMascota)
                            .font(.system(.headline, design: .rounded))
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: atributos.iconoEspecie)
                            .foregroundStyle(Color(.acento))
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TiempoEstimado(atributos: atributos, estado: estado)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color(.acento))
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(atributos.estaLista(estado) ? "¡Listo para recoger!" : "Ahora: \(etapa.titulo)")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .contentTransition(.opacity)
                        PasosEtapas(atributos: atributos, estado: estado, mostrarTitulos: false)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: etapa.icono)
                    .foregroundStyle(Color(.salud))
                    .contentTransition(.symbolEffect(.replace))
            } compactTrailing: {
                TiempoEstimado(atributos: atributos, estado: estado, compacto: true)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(.acento))
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: etapa.icono)
                    .foregroundStyle(Color(.salud))
            }
            .keylineTint(Color(.salud))
        }
    }
}

// MARK: - Pantalla de bloqueo

private struct VistaPantallaBloqueo: View {
    let atributos: CitaActivityAttributes
    let estado: CitaActivityAttributes.ContentState

    private var lista: Bool { atributos.estaLista(estado) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: atributos.iconoEspecie)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(.primario), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(atributos.nombreMascota)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color(.textoPrincipal))
                        .lineLimit(1)
                    Text(atributos.nombreNegocio)
                        .font(.caption)
                        .foregroundStyle(Color(.textoSecundario))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(lista ? "Ya puedes pasar" : "Listo aprox.")
                        .font(.caption)
                        .foregroundStyle(Color(.textoSecundario))
                    if lista {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(Color(.saludTexto))
                    } else {
                        Text(estado.horaEstimada, style: .time)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Color(.acentoTexto))
                            .monospacedDigit()
                    }
                }
            }
            Text(lista ? "¡Listo para recoger!" : "Ahora: \(atributos.etapaActual(estado).titulo)")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(.textoPrincipal))
                .contentTransition(.opacity)
            PasosEtapas(atributos: atributos, estado: estado, mostrarTitulos: true)
        }
        .padding(16)
    }
}

// MARK: - Piezas

/// Cuenta regresiva hasta la hora estimada; palomita cuando ya está lista.
private struct TiempoEstimado: View {
    let atributos: CitaActivityAttributes
    let estado: CitaActivityAttributes.ContentState
    /// En la isla compacta, más de una hora se muestra en minutos para no ensancharla.
    var compacto = false

    var body: some View {
        let restante = estado.horaEstimada.timeIntervalSinceNow
        if atributos.estaLista(estado) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color(.salud))
        } else if compacto, restante >= 3600 {
            Text("\(Int(restante / 60)) min")
                .monospacedDigit()
        } else if restante > 0 {
            Text(timerInterval: Date.now...estado.horaEstimada, countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        } else {
            Text("Ya casi")
        }
    }
}

/// La misma línea de etapas de la app: completadas en jade, pendientes apagadas.
private struct PasosEtapas: View {
    let atributos: CitaActivityAttributes
    let estado: CitaActivityAttributes.ContentState
    let mostrarTitulos: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(atributos.etapas.enumerated()), id: \.offset) { indice, etapa in
                VStack(spacing: 4) {
                    ZStack {
                        HStack(spacing: 0) {
                            linea(activa: indice <= estado.indiceEtapa, visible: indice > 0)
                            linea(activa: indice < estado.indiceEtapa, visible: indice < atributos.etapas.count - 1)
                        }
                        Image(systemName: etapa.icono)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(indice <= estado.indiceEtapa ? Color(.textoSobreSalud) : Color(.textoSecundario))
                            .frame(width: 28, height: 28)
                            .background(
                                indice <= estado.indiceEtapa ? Color(.saludTexto) : Color(.textoSecundario).opacity(0.25),
                                in: Circle()
                            )
                            .overlay {
                                if indice == estado.indiceEtapa {
                                    Circle().strokeBorder(Color(.acento), lineWidth: 2).padding(-3)
                                }
                            }
                    }
                    if mostrarTitulos {
                        Text(etapa.titulo)
                            .font(.caption2.weight(indice == estado.indiceEtapa ? .semibold : .regular))
                            .foregroundStyle(indice == estado.indiceEtapa ? Color(.textoPrincipal) : Color(.textoSecundario))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Etapa \(atributos.etapaActual(estado).titulo), \(estado.indiceEtapa + 1) de \(atributos.etapas.count)")
    }

    private func linea(activa: Bool, visible: Bool) -> some View {
        Capsule()
            .fill(activa ? Color(.salud) : Color(.borde))
            .frame(height: 3)
            .opacity(visible ? 1 : 0)
    }
}

// MARK: - Vistas previas

extension CitaActivityAttributes {
    fileprivate static var ejemplo: CitaActivityAttributes {
        CitaActivityAttributes(
            citaID: "ejemplo",
            nombreMascota: "Firulais",
            nombreNegocio: "Clínica Huellitas",
            iconoEspecie: "dog.fill",
            etapas: [
                .init(titulo: "Recibido", icono: "checkmark.circle.fill"),
                .init(titulo: "Baño", icono: "shower.fill"),
                .init(titulo: "Secado", icono: "wind"),
                .init(titulo: "Corte", icono: "scissors"),
                .init(titulo: "Listo", icono: "pawprint.fill"),
            ]
        )
    }
}

#Preview("Pantalla de bloqueo", as: .content, using: CitaActivityAttributes.ejemplo) {
    SudoboysWidgetsLiveActivity()
} contentStates: {
    CitaActivityAttributes.ContentState(indiceEtapa: 1, horaEstimada: .now.addingTimeInterval(3000))
    CitaActivityAttributes.ContentState(indiceEtapa: 4, horaEstimada: .now)
}

#Preview("Isla expandida", as: .dynamicIsland(.expanded), using: CitaActivityAttributes.ejemplo) {
    SudoboysWidgetsLiveActivity()
} contentStates: {
    CitaActivityAttributes.ContentState(indiceEtapa: 2, horaEstimada: .now.addingTimeInterval(1800))
}
