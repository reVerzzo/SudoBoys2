import Foundation
import SwiftData

@Model
final class Receta {
    @Attribute(.unique) var id: UUID
    var fecha: Date
    var nombreVeterinario: String
    var cedulaVeterinario: String
    var domicilioVeterinario: String
    var diagnostico: String
    var indicaciones: String

    var mascota: Mascota?
    var cita: Cita?
    var negocio: Negocio?

    @Relationship(deleteRule: .cascade, inverse: \Medicamento.receta)
    var medicamentos: [Medicamento] = []

    init(
        id: UUID = UUID(),
        fecha: Date = .now,
        nombreVeterinario: String,
        cedulaVeterinario: String,
        domicilioVeterinario: String,
        diagnostico: String,
        indicaciones: String
    ) {
        self.id = id
        self.fecha = fecha
        self.nombreVeterinario = nombreVeterinario
        self.cedulaVeterinario = cedulaVeterinario
        self.domicilioVeterinario = domicilioVeterinario
        self.diagnostico = diagnostico
        self.indicaciones = indicaciones
    }

    /// Verdadero si algún medicamento es de grupo I o II (NOM-064-ZOO-2000).
    var requiereRecetaFisica: Bool {
        medicamentos.contains { $0.grupo.requiereRecetaFisica }
    }
}
