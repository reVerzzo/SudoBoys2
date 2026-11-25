import Foundation
import Observation

@Observable
final class AjustesViewModel {
    var mensajeError: String?
    /// Cuenta los cambios de rol, para el haptic.
    private(set) var cambiosDeRol = 0
    /// El primer recordatorio de dosis llega al minuto de emitir la receta.
    var modoDemo: Bool {
        didSet { almacen.set(modoDemo, forKey: PreferenciasDemo.claveModoDemo) }
    }

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored private let auth: any AuthService
    @ObservationIgnored private let datosDemo: any DatosDemoService
    @ObservationIgnored private let servicios: ServiciosCitas
    @ObservationIgnored private let almacen: UserDefaults

    init(
        appState: AppState,
        auth: any AuthService,
        datosDemo: any DatosDemoService = DatosDemoSinEfecto(),
        servicios: ServiciosCitas = ServiciosCitas(),
        almacen: UserDefaults = .standard
    ) {
        self.appState = appState
        self.auth = auth
        self.datosDemo = datosDemo
        self.servicios = servicios
        self.almacen = almacen
        modoDemo = almacen.bool(forKey: PreferenciasDemo.claveModoDemo)
    }

    var usuario: Usuario? { appState.usuarioActual }

    var tituloCambioDeRol: String {
        switch appState.rol {
        case .negocio: "Cambiar a cuenta demo de tutor"
        default: "Cambiar a cuenta demo de negocio"
        }
    }

    var iconoCambioDeRol: String {
        switch appState.rol {
        case .negocio: "pawprint.fill"
        default: "cross.case.fill"
        }
    }

    func cambiarACuentaDemoDelOtroRol() {
        do {
            try appState.cambiarACuentaDemoDelOtroRol()
            cambiosDeRol += 1
        } catch {
            mensajeError = "No encontramos la cuenta demo del otro rol."
        }
    }

    func cerrarSesion() {
        auth.cerrarSesion()
        appState.cerrarSesion()
    }

    /// Borra todo, vuelve a cargar los datos de ejemplo y entra con la cuenta demo del mismo rol.
    func restablecerDatosDemo() {
        let rol = appState.rol ?? .tutor
        // Primero se suelta la sesión: nadie debe leer modelos que están por borrarse.
        auth.cerrarSesion()
        appState.cerrarSesion()
        servicios.notificaciones.cancelarTodo()
        let liveActivity = servicios.liveActivity
        Task { await liveActivity.terminarTodas() }
        do {
            try datosDemo.restablecer()
            try appState.reiniciarTrasRestablecer(rol: rol)
        } catch {
            // La app queda en la pantalla de entrada, sin sesión.
            mensajeError = "No pudimos restablecer los datos. Cierra la app y vuelve a abrirla."
        }
    }
}
