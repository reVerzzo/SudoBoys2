import Foundation
import Testing
@testable import Sudoboys2

/// AuthService de prueba: devuelve un perfil fijo o lanza un error.
@MainActor
final class AuthServiceFalso: AuthService {
    var resultado: Result<PerfilExterno, ErrorAuth>
    private(set) var cierres = 0

    init(_ resultado: Result<PerfilExterno, ErrorAuth>) {
        self.resultado = resultado
    }

    var googleDisponible: Bool { true }
    func iniciarSesionConGoogle() async throws -> PerfilExterno { try resultado.get() }
    func manejar(url: URL) -> Bool { false }
    func cerrarSesion() { cierres += 1 }
}

@MainActor
struct Escenario {
    let entorno: Entorno
    let estado: AppState
    let auth: AuthServiceFalso

    init(google: Result<PerfilExterno, ErrorAuth> = .failure(.googleNoConfigurado)) throws {
        entorno = try Entorno()
        let almacen = try #require(UserDefaults(suiteName: "pruebas-\(UUID().uuidString)"))
        estado = AppState(usuarios: entorno.repos.usuarios, almacen: almacen)
        auth = AuthServiceFalso(google)
    }

    func inicioSesion() -> InicioSesionViewModel {
        InicioSesionViewModel(appState: estado, repositorios: entorno.repos, auth: auth)
    }
}

@MainActor
@Suite("Inicio de sesión")
struct InicioSesionViewModelTests {
    @Test(arguments: RolUsuario.allCases)
    func laCuentaDemoEntraSinInternet(rol: RolUsuario) throws {
        let escenario = try Escenario()
        let vm = escenario.inicioSesion()
        vm.elegir(rol)
        #expect(vm.ruta == [.inicioSesion(rol)])

        vm.entrarConDemo(rol: rol)
        #expect(escenario.estado.rol == rol)
        #expect(vm.mensajeError == nil)
    }

    @Test func googleSinConfigurarAvisaYNoIniciaSesion() async throws {
        let escenario = try Escenario(google: .failure(.googleNoConfigurado))
        let vm = escenario.inicioSesion()
        await vm.entrarConGoogle(rol: .tutor)
        #expect(!escenario.estado.haySesion)
        #expect(vm.mensajeError != nil)
        #expect(!vm.cargandoGoogle)
    }

    @Test func cancelarGoogleNoEsUnError() async throws {
        let escenario = try Escenario(google: .failure(.cancelado))
        let vm = escenario.inicioSesion()
        await vm.entrarConGoogle(rol: .tutor)
        #expect(!escenario.estado.haySesion)
        #expect(vm.mensajeError == nil)
    }

    @Test func googleCreaLaCuentaUnaSolaVez() async throws {
        let perfil = PerfilExterno(nombre: "Ana Torres", correo: "ana@ejemplo.mx")
        let escenario = try Escenario(google: .success(perfil))
        let vm = escenario.inicioSesion()
        let antes = try escenario.entorno.contar(Usuario.self)

        await vm.entrarConGoogle(rol: .tutor)
        let usuario = try #require(escenario.estado.usuarioActual)
        #expect(usuario.nombre == "Ana Torres")
        #expect(usuario.proveedor == .google)
        #expect(usuario.rol == .tutor)
        #expect(!usuario.esDemo)

        escenario.estado.cerrarSesion()
        await vm.entrarConGoogle(rol: .tutor)
        #expect(escenario.estado.usuarioActual?.id == usuario.id)
        #expect(try escenario.entorno.contar(Usuario.self) == antes + 1)
    }

    @Test func negocioNuevoConGoogleQuedaPendienteDeAlta() async throws {
        let perfil = PerfilExterno(nombre: "Vet Nueva", correo: "vet@ejemplo.mx")
        let escenario = try Escenario(google: .success(perfil))
        await escenario.inicioSesion().entrarConGoogle(rol: .negocio)

        let usuario = try #require(escenario.estado.usuarioActual)
        #expect(usuario.rol == .negocio)
        #expect(escenario.estado.negocioActual == nil)

        let alta = AltaNegocioViewModel(appState: escenario.estado, repositorios: escenario.entorno.repos, propietario: usuario)
        alta.nombre = "Vet Nueva"
        alta.direccion = "Copilco 12"
        alta.guardar()
        #expect(escenario.estado.negocioActual?.nombre == "Vet Nueva")
        #expect(usuario.negocio?.propietario?.id == usuario.id)
    }

    @Test func reiniciarVuelveALaBienvenida() throws {
        let vm = try Escenario().inicioSesion()
        vm.elegir(.negocio)
        vm.registrarNegocio()
        vm.altaNegocio.nombre = "Borrador"
        #expect(vm.ruta == [.inicioSesion(.negocio), .altaNegocio])

        vm.reiniciar()
        #expect(vm.ruta.isEmpty)
        #expect(vm.altaNegocio.nombre.isEmpty)
    }
}

@MainActor
@Suite("Alta de negocio")
struct AltaNegocioViewModelTests {
    private func alta(_ escenario: Escenario) -> AltaNegocioViewModel {
        AltaNegocioViewModel(appState: escenario.estado, repositorios: escenario.entorno.repos)
    }

    @Test func esteticaNoPideCedula() throws {
        let escenario = try Escenario()
        let vm = alta(escenario)
        #expect(!vm.puedeGuardar)
        #expect(vm.ayuda != nil)

        vm.nombre = "  Spa Peludos  "
        vm.direccion = "Av. Universidad 100"
        vm.especies = [.gato, .perro]
        #expect(!vm.requiereCedula)
        #expect(vm.puedeGuardar)
        #expect(vm.ayuda == nil)

        let antes = try escenario.entorno.contar(Negocio.self)
        vm.guardar()

        let negocio = try #require(escenario.estado.negocioActual)
        #expect(escenario.estado.rol == .negocio)
        #expect(negocio.nombre == "Spa Peludos")
        #expect(negocio.tipo == .estetica)
        #expect(negocio.especiesAtendidas == [.perro, .gato])
        #expect(negocio.estadoVerificacion == .pendiente)
        #expect(negocio.cedula == nil)
        #expect(!negocio.puedeEmitirRecetas)
        #expect(try escenario.entorno.contar(Negocio.self) == antes + 1)
    }

    @Test(arguments: [TipoNegocio.veterinaria, .ambos])
    func veterinariaPideCedulaYFoto(tipo: TipoNegocio) throws {
        let escenario = try Escenario()
        let vm = alta(escenario)
        vm.nombre = "Vet Sur"
        vm.direccion = "Tlalpan 10"
        vm.tipo = tipo
        #expect(vm.requiereCedula)
        #expect(!vm.puedeGuardar)

        #expect(vm.ayuda == "Falta el número de cédula (7 u 8 dígitos) y la foto de la cédula.")

        vm.cedula = "12AB"
        vm.fotoCedula = Data([1, 2, 3])
        #expect(!vm.cedulaValida)
        #expect(!vm.puedeGuardar)

        vm.cedula = "1234567"
        vm.fotoCedula = nil
        #expect(!vm.puedeGuardar)

        vm.fotoCedula = Data([1, 2, 3])
        #expect(vm.puedeGuardar)
        vm.guardar()

        let negocio = try #require(escenario.estado.negocioActual)
        #expect(negocio.estadoVerificacion == .enRevision)
        #expect(negocio.cedula == "1234567")
        #expect(negocio.fotoCedula == Data([1, 2, 3]))
        // En revisión todavía no puede emitir recetas ni muestra insignia.
        #expect(!negocio.puedeEmitirRecetas)
        #expect(negocio.insignia == nil)
    }

    @Test func sinEspeciesNoSePuedeGuardar() throws {
        let vm = alta(try Escenario())
        vm.nombre = "Spa"
        vm.direccion = "Calle 1"
        vm.alternar(.perro)
        #expect(vm.especies.isEmpty)
        #expect(!vm.puedeGuardar)
        vm.alternar(.exotico)
        #expect(vm.puedeGuardar)
    }
}

@MainActor
@Suite("Ajustes")
struct AjustesViewModelTests {
    @Test func cambiaRapidoEntreLasCuentasDemo() throws {
        let escenario = try Escenario()
        try escenario.estado.iniciarSesionDemo(rol: .tutor)
        let vm = AjustesViewModel(appState: escenario.estado, auth: escenario.auth)
        #expect(vm.tituloCambioDeRol == "Cambiar a cuenta demo de negocio")

        vm.cambiarACuentaDemoDelOtroRol()
        #expect(escenario.estado.rol == .negocio)
        #expect(vm.tituloCambioDeRol == "Cambiar a cuenta demo de tutor")
        #expect(vm.cambiosDeRol == 1)

        vm.cambiarACuentaDemoDelOtroRol()
        #expect(escenario.estado.rol == .tutor)
        #expect(vm.mensajeError == nil)
    }

    @Test func cerrarSesionTambienCierraElProveedor() throws {
        let escenario = try Escenario()
        try escenario.estado.iniciarSesionDemo(rol: .negocio)
        let vm = AjustesViewModel(appState: escenario.estado, auth: escenario.auth)
        vm.cerrarSesion()
        #expect(!escenario.estado.haySesion)
        #expect(escenario.auth.cierres == 1)
    }
}
