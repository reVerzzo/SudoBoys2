import Foundation
import Observation

/// Citas del tutor: las activas arriba y el historial abajo.
@Observable
final class MisCitasViewModel {
    private(set) var activas: [Cita] = []
    private(set) var anteriores: [Cita] = []
    var mensajeError: String?
    /// Cuenta los perfiles creados desde una cita sin perfil, para el haptic.
    private(set) var perfilesCreados = 0

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored private let citas: any CitaRepository
    @ObservationIgnored private let mascotas: (any MascotaRepository)?
    @ObservationIgnored private let servicios: ServiciosCitas

    init(
        appState: AppState,
        citas: any CitaRepository,
        mascotas: (any MascotaRepository)? = nil,
        servicios: ServiciosCitas = ServiciosCitas()
    ) {
        self.appState = appState
        self.citas = citas
        self.mascotas = mascotas
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

    // MARK: - Perfil desde una cita sin perfil

    /// Al terminar una cita sin perfil se ofrece guardar a la mascota.
    func ofrecePerfil(_ cita: Cita) -> Bool {
        mascotas != nil && cita.estado == .terminada && cita.esSinPerfil
    }

    /// Formulario de alta con la especie de la emergencia; al guardar, la cita queda ligada a la mascota.
    func formularioPerfil(para cita: Cita) -> FormularioMascotaViewModel? {
        guard let mascotas, ofrecePerfil(cita), let tutor = appState.usuarioActual else { return nil }
        return FormularioMascotaViewModel(
            mascota: nil,
            tutor: tutor,
            repositorio: mascotas,
            especieInicial: cita.especieEmergencia ?? .perro,
            alCrear: { [weak self] mascota in
                guard let self else { return }
                do {
                    try citas.asignar(mascota, a: cita)
                    perfilesCreados += 1
                } catch {
                    mensajeError = "Guardamos a \(mascota.nombre), pero no pudimos ligar la cita a su perfil."
                }
            },
            alGuardar: { [weak self] in self?.cargar() }
        )
    }
}
