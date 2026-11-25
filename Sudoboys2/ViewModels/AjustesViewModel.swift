import Foundation
import Observation

@Observable
final class AjustesViewModel {
    var mensajeError: String?
    /// Cuenta los cambios de rol, para el haptic.
    private(set) var cambiosDeRol = 0

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored private let auth: any AuthService

    init(appState: AppState, auth: any AuthService) {
        self.appState = appState
        self.auth = auth
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
}
