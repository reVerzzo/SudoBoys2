import Foundation
import Observation

/// Citas del tutor: las activas arriba y el historial abajo.
@Observable
final class MisCitasViewModel {
    private(set) var activas: [Cita] = []
    private(set) var anteriores: [Cita] = []
    var mensajeError: String?

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored private let citas: any CitaRepository
    @ObservationIgnored private let servicios: ServiciosCitas

    init(appState: AppState, citas: any CitaRepository, servicios: ServiciosCitas = ServiciosCitas()) {
        self.appState = appState
        self.citas = citas
        self.servicios = servicios
    }

    func cargar() {
        guard let tutor = appState.usuarioActual else {
            activas = []
            anteriores = []
            return
        }
        do {
            let todas = try citas.citas(de: tutor)
            activas = todas
                .filter { $0.estado == .programada || $0.estado == .enCurso }
                .sorted { ($0.estado == .enCurso ? 0 : 1, $0.fecha) < ($1.estado == .enCurso ? 0 : 1, $1.fecha) }
            anteriores = todas.filter { $0.estado == .terminada || $0.estado == .cancelada }
        } catch {
            mensajeError = "No pudimos cargar tus citas."
        }
    }

    func cancelar(_ cita: Cita) {
        do {
            try citas.cancelar(cita)
            let liveActivity = servicios.liveActivity
            Task { await liveActivity.terminar(para: cita) }
            cargar()
        } catch {
            mensajeError = "No pudimos cancelar la cita."
        }
    }
}
