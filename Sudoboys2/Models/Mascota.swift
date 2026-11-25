import Foundation
import SwiftData

@Model
final class Mascota {
    @Attribute(.unique) var id: UUID
    var nombre: String
    var especie: Especie
    /// Detalle para exóticos: conejo, ave, hurón…
    var detalleEspecie: String
    var raza: String
    var nacimiento: Date?
    var pesoKg: Double?
    var alergias: String
    var notasComportamiento: String
    @Attribute(.externalStorage) var foto: Data?

    var tutor: Usuario?

    @Relationship(deleteRule: .cascade, inverse: \Vacuna.mascota)
    var vacunas: [Vacuna] = []

    @Relationship(deleteRule: .cascade, inverse: \Receta.mascota)
    var recetas: [Receta] = []

    @Relationship(inverse: \Cita.mascota)
    var citas: [Cita] = []

    init(
        id: UUID = UUID(),
        nombre: String,
        especie: Especie,
        detalleEspecie: String = "",
        raza: String = "",
        nacimiento: Date? = nil,
        pesoKg: Double? = nil,
        alergias: String = "",
        notasComportamiento: String = "",
        foto: Data? = nil
    ) {
        self.id = id
        self.nombre = nombre
        self.especie = especie
        self.detalleEspecie = detalleEspecie
        self.raza = raza
        self.nacimiento = nacimiento
        self.pesoKg = pesoKg
        self.alergias = alergias
        self.notasComportamiento = notasComportamiento
        self.foto = foto
    }

    /// La vacuna con la próxima dosis más cercana a partir de `fecha`.
    func proximaVacuna(desde fecha: Date = .now) -> Vacuna? {
        vacunas
            .filter { ($0.proximaDosis ?? .distantPast) >= fecha }
            .min { ($0.proximaDosis ?? .distantFuture) < ($1.proximaDosis ?? .distantFuture) }
    }
}
