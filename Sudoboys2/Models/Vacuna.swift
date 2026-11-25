import Foundation
import SwiftData

@Model
final class Vacuna {
    @Attribute(.unique) var id: UUID
    var nombre: String
    var fechaAplicacion: Date
    var proximaDosis: Date?
    var registradaPor: RegistradaPor
    var nombreVeterinario: String?
    var cedulaVeterinario: String?

    var mascota: Mascota?

    init(
        id: UUID = UUID(),
        nombre: String,
        fechaAplicacion: Date,
        proximaDosis: Date? = nil,
        registradaPor: RegistradaPor = .tutor,
        nombreVeterinario: String? = nil,
        cedulaVeterinario: String? = nil
    ) {
        self.id = id
        self.nombre = nombre
        self.fechaAplicacion = fechaAplicacion
        self.proximaDosis = proximaDosis
        self.registradaPor = registradaPor
        self.nombreVeterinario = nombreVeterinario
        self.cedulaVeterinario = cedulaVeterinario
    }
}
