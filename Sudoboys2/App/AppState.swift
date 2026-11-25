import Foundation
import Observation
import OSLog

/// Sesión y rol actuales. Las vistas lo leen del `Environment`.
@Observable
final class AppState {
    private(set) var usuarioActual: Usuario?
    /// Cambia cuando se restablecen los datos de demo: la raíz se reconstruye
    /// para que ninguna pantalla conserve modelos ya borrados.
    private(set) var generacionDatos = 0

    @ObservationIgnored private let usuarios: any UsuarioRepository
    @ObservationIgnored private let almacen: UserDefaults
    @ObservationIgnored private let registro = Logger(subsystem: "Sudoboys2", category: "Sesion")

    static let claveSesion = "sesionUsuarioID"

    init(usuarios: any UsuarioRepository, almacen: UserDefaults = .standard) {
        self.usuarios = usuarios
        self.almacen = almacen
    }

    var haySesion: Bool { usuarioActual != nil }

    /// Rol de la sesión; `nil` sin sesión.
    var rol: RolUsuario? { usuarioActual?.rol }

    /// Negocio que administra la sesión (solo rol negocio).
    var negocioActual: Negocio? { usuarioActual?.negocio }

    func iniciarSesion(_ usuario: Usuario) {
        usuarioActual = usuario
        almacen.set(usuario.id.uuidString, forKey: Self.claveSesion)
    }

    /// Entra con la cuenta demo del rol. Funciona siempre, sin internet.
    func iniciarSesionDemo(rol: RolUsuario) throws {
        iniciarSesion(try usuarios.usuarioDemo(rol: rol))
    }

    /// Cambio rápido a la cuenta demo del otro rol (para probar ambos en el mismo iPhone).
    func cambiarACuentaDemoDelOtroRol() throws {
        try iniciarSesionDemo(rol: (rol ?? .negocio).otro)
    }

    /// Antes de borrar los datos: cierra la sesión y reconstruye la interfaz,
    /// para que ninguna pantalla (ni los pines del mapa) lea modelos que se van a borrar.
    func prepararRestablecer() {
        cerrarSesion()
        generacionDatos += 1
    }

    func cerrarSesion() {
        usuarioActual = nil
        almacen.removeObject(forKey: Self.claveSesion)
    }

    /// Recupera la sesión guardada al abrir la app. Si ya no existe, queda sin sesión.
    func restaurarSesion() {
        guard let texto = almacen.string(forKey: Self.claveSesion), let id = UUID(uuidString: texto) else { return }
        do {
            if let usuario = try usuarios.usuario(id: id) {
                usuarioActual = usuario
            } else {
                almacen.removeObject(forKey: Self.claveSesion)
            }
        } catch {
            registro.error("No se pudo restaurar la sesión: \(error.localizedDescription, privacy: .public)")
        }
    }
}
