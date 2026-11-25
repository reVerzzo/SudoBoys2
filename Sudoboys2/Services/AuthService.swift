import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

/// Datos mínimos que devuelve un proveedor externo de identidad.
nonisolated struct PerfilExterno: Equatable, Sendable {
    var nombre: String
    var correo: String
}

nonisolated enum ErrorAuth: Error, Equatable {
    /// Falta el paquete GoogleSignIn o el `GIDClientID` en Info.plist.
    case googleNoConfigurado
    /// La persona cerró la hoja de Google.
    case cancelado
    case sinVentana
    case sinPerfil
}

/// Inicio de sesión con proveedores externos. La cuenta demo no pasa por aquí:
/// vive en SwiftData y funciona sin internet (ver `AppState`).
protocol AuthService {
    /// Verdadero si esta compilación puede abrir Google Sign-In.
    var googleDisponible: Bool { get }
    func iniciarSesionConGoogle() async throws -> PerfilExterno
    /// Reenvía la URL de regreso de Google. Devuelve `true` si la manejó.
    func manejar(url: URL) -> Bool
    func cerrarSesion()
}

/// Implementación de la app.
///
/// Para activar Google:
/// 1. Agregar el paquete `https://github.com/google/GoogleSignIn-iOS` al target Sudoboys2 desde Xcode.
/// 2. Poner en Info.plist `GIDClientID` y el URL scheme invertido del cliente de iOS.
/// Mientras falte cualquiera de los dos, `googleDisponible` es `false` y la app
/// ofrece la cuenta demo en su lugar. Sign in with Apple no se implementa: requiere cuenta pagada.
final class AuthServiceLocal: AuthService {
    var googleDisponible: Bool {
        #if canImport(GoogleSignIn)
        Bundle.main.object(forInfoDictionaryKey: "GIDClientID") != nil
        #else
        false
        #endif
    }

    func iniciarSesionConGoogle() async throws -> PerfilExterno {
        guard googleDisponible else { throw ErrorAuth.googleNoConfigurado }
        #if canImport(GoogleSignIn) && canImport(UIKit)
        let ventanas = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        guard let raiz = (ventanas.first(where: \.isKeyWindow) ?? ventanas.first)?.rootViewController else {
            throw ErrorAuth.sinVentana
        }
        do {
            let resultado = try await GIDSignIn.sharedInstance.signIn(withPresenting: raiz)
            guard let perfil = resultado.user.profile else { throw ErrorAuth.sinPerfil }
            return PerfilExterno(nombre: perfil.name, correo: perfil.email)
        } catch let error as GIDSignInError where error.code == .canceled {
            throw ErrorAuth.cancelado
        }
        #else
        throw ErrorAuth.googleNoConfigurado
        #endif
    }

    func manejar(url: URL) -> Bool {
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.handle(url)
        #else
        false
        #endif
    }

    func cerrarSesion() {
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
    }
}
