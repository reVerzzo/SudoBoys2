import ActivityKit
import Foundation
import OSLog

/// Live Activity de la cita en curso. Se actualiza localmente, sin push.
@MainActor
protocol LiveActivityService {
    /// Inicia la actividad al hacer check-in (o la actualiza si ya existe).
    func iniciar(para cita: Cita) async
    /// Refleja la etapa actual; si la cita ya está lista, cierra la actividad con el estado final.
    func actualizar(para cita: Cita) async
    func terminar(para cita: Cita) async
    /// Cierra todas las actividades (al restablecer los datos de demo).
    func terminarTodas() async
}

/// Para vistas previas y pruebas.
struct LiveActivitySinEfecto: LiveActivityService {
    func iniciar(para cita: Cita) async {}
    func actualizar(para cita: Cita) async {}
    func terminar(para cita: Cita) async {}
    func terminarTodas() async {}
}

final class LiveActivityActivityKit: LiveActivityService {
    private let registro = Logger(subsystem: "Sudoboys2", category: "LiveActivity")

    func iniciar(para cita: Cita) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            registro.info("Las Live Activities no están habilitadas; se omite.")
            return
        }
        if actividad(de: cita) != nil {
            await actualizar(para: cita)
            return
        }
        let atributos = CitaActivityAttributes(
            citaID: cita.id.uuidString,
            nombreMascota: cita.nombreMascota,
            nombreNegocio: cita.negocio?.nombre ?? "",
            iconoEspecie: cita.especie?.icono ?? "pawprint.fill",
            etapas: cita.etapas.map { .init(titulo: $0.titulo, icono: $0.icono) }
        )
        do {
            _ = try Activity.request(
                attributes: atributos,
                content: contenido(de: cita),
                pushType: nil
            )
        } catch {
            registro.error("No se pudo iniciar la Live Activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    func actualizar(para cita: Cita) async {
        guard let actividad = actividad(de: cita) else { return }
        let contenido = contenido(de: cita)
        if cita.estado == .enCurso {
            await actividad.update(contenido)
        } else {
            // Lista o cancelada: queda el estado final en la pantalla de bloqueo.
            await actividad.end(contenido, dismissalPolicy: .default)
        }
    }

    func terminar(para cita: Cita) async {
        guard let actividad = actividad(de: cita) else { return }
        await actividad.end(nil, dismissalPolicy: .immediate)
    }

    func terminarTodas() async {
        for actividad in Activity<CitaActivityAttributes>.activities {
            await actividad.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func actividad(de cita: Cita) -> Activity<CitaActivityAttributes>? {
        let id = cita.id.uuidString
        return Activity<CitaActivityAttributes>.activities.first {
            $0.attributes.citaID == id && $0.activityState == .active
        }
    }

    private func contenido(de cita: Cita) -> ActivityContent<CitaActivityAttributes.ContentState> {
        let indice = cita.etapaActual.flatMap { cita.etapas.firstIndex(of: $0) } ?? 0
        let estado = CitaActivityAttributes.ContentState(indiceEtapa: indice, horaEstimada: cita.horaEstimadaListo)
        return ActivityContent(state: estado, staleDate: nil)
    }
}
