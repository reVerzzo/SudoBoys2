import Foundation
import SwiftData

@Model
final class Medicamento {
    @Attribute(.unique) var id: UUID
    var nombre: String
    var dosis: String
    var cadaHoras: Int
    var dias: Int
    var grupo: GrupoMedicamento

    var receta: Receta?

    init(
        id: UUID = UUID(),
        nombre: String,
        dosis: String,
        cadaHoras: Int,
        dias: Int,
        grupo: GrupoMedicamento
    ) {
        self.id = id
        self.nombre = nombre
        self.dosis = dosis
        self.cadaHoras = cadaHoras
        self.dias = dias
        self.grupo = grupo
    }
}
