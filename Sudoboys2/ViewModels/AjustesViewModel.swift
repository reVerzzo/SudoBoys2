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
    /// Tiempo para que las pantallas anteriores terminen de desmontarse antes de borrar.
    @ObservationIgnored var espera: Duration = .milliseconds(500)

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
    func restablecerDatosDemo() async {
        let rol = appState.rol ?? .tutor
        // Primero se suelta la sesión y se desmontan las pantallas: MapKit dibuja los pines
        // por su cuenta y truena si lee un negocio ya borrado.
        auth.cerrarSesion()
        appState.prepararRestablecer()
        servicios.notificaciones.cancelarTodo()
        await servicios.liveActivity.terminarTodas()
        try? await Task.sleep(for: espera)
        do {
            try datosDemo.restablecer()
            try appState.iniciarSesionDemo(rol: rol)
        } catch {
            // La app queda en la pantalla de entrada, sin sesión.
            mensajeError = "No pudimos restablecer los datos. Cierra la app y vuelve a abrirla."
        }
    }
}
