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

    static func explorar() -> ExplorarViewModel {
        let viewModel = ExplorarViewModel(negocios: repositorios.negocios)
        viewModel.cargar()
        return viewModel
    }

    static func perfilHuellitas() -> PerfilNegocioViewModel? {
        let explorar = explorar()
        guard let huellitas = explorar.resultados.first(where: { $0.negocio.nombre == SeedData.nombreNegocioDemo }) else {
            return nil
        }
        return explorar.perfil(para: huellitas.id)
    }

    static func ajustes(rol: RolUsuario) -> AjustesViewModel {
        AjustesViewModel(appState: appState(rol: rol), auth: auth)
    }

    static func misMascotas() -> MisMascotasViewModel {
        let viewModel = MisMascotasViewModel(appState: appState(rol: .tutor), repositorio: repositorios.mascotas)
        viewModel.cargar()
        return viewModel
    }

    static func misCitas() -> MisCitasViewModel {
        let viewModel = MisCitasViewModel(appState: appState(rol: .tutor), citas: repositorios.citas, mascotas: repositorios.mascotas)
        viewModel.cargar()
        return viewModel
    }

    static func reservar() -> ReservarViewModel? {
        guard let perfil = perfilHuellitas() else { return nil }
        return ReservarViewModel(
            negocio: perfil.negocio,
            tutor: appState(rol: .tutor).usuarioActual,
            citas: repositorios.citas,
            mascotas: repositorios.mascotas
        )
    }

    static func agenda() -> AgendaViewModel? {
        guard let negocio = appState(rol: .negocio).negocioActual else { return nil }
        let viewModel = AgendaViewModel(negocio: negocio, citas: repositorios.citas)
        viewModel.cargar()
        return viewModel
    }

    static func recetaFirulais() -> Receta? {
        detalleFirulais()?.recetas.first
    }

    static func formularioReceta() -> FormularioRecetaViewModel? {
        guard let cita = agenda()?.negocio.citas.first(where: { $0.tipoServicio == .veterinaria }) else { return nil }
        return FormularioRecetaViewModel(cita: cita, recetas: repositorios.recetas)
    }

    static func verificacion() -> VerificacionViewModel? {
        guard let negocio = appState(rol: .negocio).negocioActual else { return nil }
        return VerificacionViewModel(negocio: negocio, negocios: repositorios.negocios)
    }

    static func detalleFirulais() -> DetalleMascotaViewModel? {
        let lista = misMascotas()
        guard let firulais = lista.mascotas.first(where: { $0.nombre == "Firulais" }) else { return nil }
        let detalle = lista.detalle(para: firulais.id)
        detalle?.cargar()
        return detalle
    }

    /// Escaneo ya leído, con el texto de una cartilla de ejemplo.
    static func escaneoEnRevision() -> EscaneoCartillaViewModel? {
        guard let escaneo = detalleFirulais()?.nuevoEscaneo() else { return nil }
        let hoy = Date.now
        escaneo.borradores = [
            .init(nombre: "Antirrábica", fechaAplicacion: hoy, fechaPorRevisar: false, tieneProximaDosis: true, proximaDosis: hoy),
            .init(nombre: "Parvovirus", fechaAplicacion: hoy, fechaPorRevisar: true, tieneProximaDosis: false, proximaDosis: hoy),
        ]
        escaneo.mostrarRevision()
        return escaneo
    }
}
