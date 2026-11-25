import Foundation
import SwiftData

/// Dependencias en memoria con los datos de ejemplo, para `#Preview`.
enum VistaPrevia {
    static let repositorios = Repositorios(contexto: ContenedorDatos.vistaPrevia.mainContext)
    static let auth: any AuthService = AuthServiceLocal()

    /// `rol == nil` deja la app sin sesión.
    static func appState(rol: RolUsuario?) -> AppState {
        let almacen = UserDefaults(suiteName: "vistaPrevia") ?? .standard
        let estado = AppState(usuarios: repositorios.usuarios, almacen: almacen)
        if let rol {
            try? estado.iniciarSesionDemo(rol: rol)
        }
        return estado
    }

    static func inicioSesion() -> InicioSesionViewModel {
        InicioSesionViewModel(appState: appState(rol: nil), repositorios: repositorios, auth: auth)
    }

    static func ajustes(rol: RolUsuario) -> AjustesViewModel {
        AjustesViewModel(appState: appState(rol: rol), auth: auth)
    }
}
