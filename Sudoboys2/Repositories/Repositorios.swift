import SwiftData
import SwiftUI

/// Los cinco repositorios juntos, para inyectarlos por inicializador o `Environment`.
/// Para cambiar a un backend en la nube basta construir este tipo con otras implementaciones.
struct Repositorios {
    let usuarios: any UsuarioRepository
    let mascotas: any MascotaRepository
    let negocios: any NegocioRepository
    let citas: any CitaRepository
    let recetas: any RecetaRepository

    init(
        usuarios: any UsuarioRepository,
        mascotas: any MascotaRepository,
        negocios: any NegocioRepository,
        citas: any CitaRepository,
        recetas: any RecetaRepository
    ) {
        self.usuarios = usuarios
        self.mascotas = mascotas
        self.negocios = negocios
        self.citas = citas
        self.recetas = recetas
    }

    /// Implementación local con SwiftData.
    init(contexto: ModelContext) {
        self.init(
            usuarios: UsuarioRepositorySwiftData(contexto: contexto),
            mascotas: MascotaRepositorySwiftData(contexto: contexto),
            negocios: NegocioRepositorySwiftData(contexto: contexto),
            citas: CitaRepositorySwiftData(contexto: contexto),
            recetas: RecetaRepositorySwiftData(contexto: contexto)
        )
    }
}

extension EnvironmentValues {
    /// Repositorios de la app; `nil` solo si nadie los inyectó.
    @Entry var repositorios: Repositorios? = nil
    /// Live Activity y avisos de las citas; `nil` solo si nadie los inyectó.
    @Entry var serviciosCitas: ServiciosCitas? = nil
}
