import Foundation
import Testing
@testable import Sudoboys2

@MainActor
@Suite("UsuarioRepository")
struct UsuarioRepositoryTests {
    @Test(arguments: RolUsuario.allCases)
    func hayCuentaDemoPorRol(rol: RolUsuario) throws {
        let entorno = try Entorno()
        let usuario = try entorno.repos.usuarios.usuarioDemo(rol: rol)
        #expect(usuario.rol == rol)
        #expect(usuario.esDemo)
        #expect(usuario.proveedor == .demo)
    }

    @Test func sinDatosDeEjemploNoHayCuentaDemo() throws {
        let entorno = try Entorno(sembrado: false)
        #expect(throws: ErrorRepositorio.sinCuentaDemo(.tutor)) {
            try entorno.repos.usuarios.usuarioDemo(rol: .tutor)
        }
    }

    @Test func creaYBuscaPorId() throws {
        let entorno = try Entorno(sembrado: false)
        let usuario = Usuario(nombre: "Ana", correo: "ana@ejemplo.mx", proveedor: .google, rol: .tutor)
        try entorno.repos.usuarios.crear(usuario)
        #expect(try entorno.repos.usuarios.usuario(id: usuario.id)?.nombre == "Ana")
        #expect(try entorno.repos.usuarios.usuario(id: UUID()) == nil)
    }
}
