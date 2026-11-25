import Foundation
import SwiftData

@Model
final class Servicio {
    @Attribute(.unique) var id: UUID
    var nombre: String
    /// Precio en pesos mexicanos.
    var precio: Decimal
    var duracionMinutos: Int
    var tipo: TipoServicio

    var negocio: Negocio?

    init(
        id: UUID = UUID(),
        nombre: String,
        precio: Decimal,
        duracionMinutos: Int,
        tipo: TipoServicio
    ) {
        self.id = id
        self.nombre = nombre
        self.precio = precio
        self.duracionMinutos = duracionMinutos
        self.tipo = tipo
    }
}
