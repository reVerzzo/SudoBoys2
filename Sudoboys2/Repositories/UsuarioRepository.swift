import Foundation
import SwiftData

protocol UsuarioRepository {
    func usuario(id: UUID) throws -> Usuario?
    func usuario(correo: String) throws -> Usuario?
    /// La cuenta demo del rol; siempre disponible sin internet.
    func usuarioDemo(rol: RolUsuario) throws -> Usuario
    func crear(_ usuario: Usuario) throws
    func guardar() throws
}

final class UsuarioRepositorySwiftData: UsuarioRepository {
    private let contexto: ModelContext

    init(contexto: ModelContext) {
        self.contexto = contexto
    }

    func usuario(id: UUID) throws -> Usuario? {
        var consulta = FetchDescriptor<Usuario>(predicate: #Predicate { $0.id == id })
        consulta.fetchLimit = 1
        return try contexto.fetch(consulta).first
    }

    func usuario(correo: String) throws -> Usuario? {
        var consulta = FetchDescriptor<Usuario>(predicate: #Predicate { $0.correo == correo })
        consulta.fetchLimit = 1
        return try contexto.fetch(consulta).first
    }

    func usuarioDemo(rol: RolUsuario) throws -> Usuario {
        let demos = try contexto.fetch(FetchDescriptor<Usuario>(predicate: #Predicate { $0.esDemo }))
        guard let usuario = demos.first(where: { $0.rol == rol }) else {
            throw ErrorRepositorio.sinCuentaDemo(rol)
        }
        return usuario
    }

    func crear(_ usuario: Usuario) throws {
        contexto.insert(usuario)
        try contexto.save()
    }

    func guardar() throws {
        try contexto.save()
    }
}
