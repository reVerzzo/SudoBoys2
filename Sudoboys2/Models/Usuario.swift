import Foundation
import SwiftData

@Model
final class Usuario {
    @Attribute(.unique) var id: UUID
    var nombre: String
    var correo: String
    var proveedor: ProveedorAuth
    var rol: RolUsuario
    /// Cuenta de demostración: siempre disponible sin internet.
    var esDemo: Bool

    @Relationship(deleteRule: .cascade, inverse: \Mascota.tutor)
    var mascotas: [Mascota] = []

    /// Negocio que administra (solo rol negocio).
    @Relationship(inverse: \Negocio.propietario)
    var negocio: Negocio?

    init(
        id: UUID = UUID(),
        nombre: String,
        correo: String,
        proveedor: ProveedorAuth,
        rol: RolUsuario,
        esDemo: Bool = false
    ) {
        self.id = id
        self.nombre = nombre
        self.correo = correo
        self.proveedor = proveedor
        self.rol = rol
        self.esDemo = esDemo
    }
}
