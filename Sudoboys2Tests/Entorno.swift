import Foundation
import Testing
import SwiftData
@testable import Sudoboys2

/// Contenedor en memoria, nuevo para cada prueba.
@MainActor
struct Entorno {
    let contenedor: ModelContainer
    let repos: Repositorios

    var contexto: ModelContext { contenedor.mainContext }

    init(sembrado: Bool = true) throws {
        contenedor = ContenedorDatos.crear(enMemoria: true)
        repos = Repositorios(contexto: contenedor.mainContext)
        if sembrado {
            try SeedData.sembrarSiHaceFalta(en: contenedor.mainContext)
        }
    }

    func tutor() throws -> Usuario { try repos.usuarios.usuarioDemo(rol: .tutor) }

    func huellitas() throws -> Negocio {
        let negocio = try repos.usuarios.usuarioDemo(rol: .negocio).negocio
        return try #require(negocio)
    }

    func mascota(_ nombre: String) throws -> Mascota {
        let mascota = try repos.mascotas.mascotas(de: tutor()).first { $0.nombre == nombre }
        return try #require(mascota)
    }

    func contar<Modelo: PersistentModel>(_ tipo: Modelo.Type) throws -> Int {
        try contexto.fetchCount(FetchDescriptor<Modelo>())
    }
}
