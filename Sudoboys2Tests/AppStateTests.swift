import Foundation
import Testing
@testable import Sudoboys2

@MainActor
@Suite("AppState")
struct AppStateTests {
    private func almacenTemporal() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "pruebas-\(UUID().uuidString)"))
    }

    @Test func empiezaSinSesion() throws {
        let entorno = try Entorno()
        let estado = AppState(usuarios: entorno.repos.usuarios, almacen: try almacenTemporal())
        #expect(!estado.haySesion)
        #expect(estado.rol == nil)
    }

    @Test(arguments: RolUsuario.allCases)
    func entraConCuentaDemo(rol: RolUsuario) throws {
        let entorno = try Entorno()
        let estado = AppState(usuarios: entorno.repos.usuarios, almacen: try almacenTemporal())
        try estado.iniciarSesionDemo(rol: rol)
        #expect(estado.haySesion)
        #expect(estado.rol == rol)
        #expect((estado.negocioActual != nil) == (rol == .negocio))
    }

    @Test func cambiaALaCuentaDemoDelOtroRolYCierraSesion() throws {
        let entorno = try Entorno()
        let estado = AppState(usuarios: entorno.repos.usuarios, almacen: try almacenTemporal())
        try estado.iniciarSesionDemo(rol: .tutor)

        try estado.cambiarACuentaDemoDelOtroRol()
        #expect(estado.rol == .negocio)
        #expect(estado.negocioActual?.nombre == "Clínica Huellitas")

        try estado.cambiarACuentaDemoDelOtroRol()
        #expect(estado.rol == .tutor)

        estado.cerrarSesion()
        #expect(!estado.haySesion)
    }

    @Test func restauraLaSesionGuardada() throws {
        let entorno = try Entorno()
        let almacen = try almacenTemporal()
        let primera = AppState(usuarios: entorno.repos.usuarios, almacen: almacen)
        try primera.iniciarSesionDemo(rol: .negocio)

        let segunda = AppState(usuarios: entorno.repos.usuarios, almacen: almacen)
        segunda.restaurarSesion()
        #expect(segunda.rol == .negocio)

        segunda.cerrarSesion()
        let tercera = AppState(usuarios: entorno.repos.usuarios, almacen: almacen)
        tercera.restaurarSesion()
        #expect(!tercera.haySesion)
    }

    @Test func sinDatosDeEjemploLaCuentaDemoFallaSinTronar() throws {
        let entorno = try Entorno(sembrado: false)
        let estado = AppState(usuarios: entorno.repos.usuarios, almacen: try almacenTemporal())
        #expect(throws: ErrorRepositorio.sinCuentaDemo(.tutor)) { try estado.iniciarSesionDemo(rol: .tutor) }
        #expect(!estado.haySesion)
    }
}
