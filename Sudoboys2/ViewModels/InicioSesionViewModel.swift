import Foundation
import Observation

/// Flujo de entrada: elegir rol, iniciar sesión y, para negocios nuevos, el alta.
@Observable
final class InicioSesionViewModel {
    enum Ruta: Hashable {
        case inicioSesion(RolUsuario)
        case altaNegocio
    }

    var ruta: [Ruta] = []
    var mensajeError: String?
    private(set) var cargandoGoogle = false
    /// Alta de un negocio nuevo sin cuenta previa.
    private(set) var altaNegocio: AltaNegocioViewModel

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored private let repositorios: Repositorios
    @ObservationIgnored private let auth: any AuthService

    init(appState: AppState, repositorios: Repositorios, auth: any AuthService) {
        self.appState = appState
        self.repositorios = repositorios
        self.auth = auth
        self.altaNegocio = AltaNegocioViewModel(appState: appState, repositorios: repositorios)
    }

    func elegir(_ rol: RolUsuario) {
        ruta = [.inicioSesion(rol)]
    }

    func registrarNegocio() {
        ruta.append(.altaNegocio)
    }

    /// Siempre funciona sin internet: la cuenta demo vive en los datos locales.
    func entrarConDemo(rol: RolUsuario) {
        do {
            try appState.iniciarSesionDemo(rol: rol)
        } catch {
            mensajeError = "No encontramos la cuenta demo. Vuelve a instalar la app para restaurar los datos de ejemplo."
        }
    }

    func entrarConGoogle(rol: RolUsuario) async {
        guard !cargandoGoogle else { return }
        cargandoGoogle = true
        defer { cargandoGoogle = false }
        do {
            let perfil = try await auth.iniciarSesionConGoogle()
            appState.iniciarSesion(try usuario(para: perfil, rol: rol))
        } catch ErrorAuth.cancelado {
            // La persona cerró la hoja: no es un error.
        } catch ErrorAuth.googleNoConfigurado {
            mensajeError = "Google todavía no está disponible en esta versión. Mientras tanto, entra con la cuenta demo."
        } catch {
            mensajeError = "No pudimos iniciar sesión con Google. Revisa tu conexión o entra con la cuenta demo."
        }
    }

    /// Vuelve a la pantalla de bienvenida con un alta limpia (al cerrar sesión).
    func reiniciar() {
        ruta = []
        mensajeError = nil
        altaNegocio = AltaNegocioViewModel(appState: appState, repositorios: repositorios)
    }

    /// La cuenta que ya existe con ese correo o una nueva con el rol elegido.
    private func usuario(para perfil: PerfilExterno, rol: RolUsuario) throws -> Usuario {
        if let existente = try repositorios.usuarios.usuario(correo: perfil.correo) {
            return existente
        }
        let nuevo = Usuario(nombre: perfil.nombre, correo: perfil.correo, proveedor: .google, rol: rol)
        try repositorios.usuarios.crear(nuevo)
        return nuevo
    }
}
