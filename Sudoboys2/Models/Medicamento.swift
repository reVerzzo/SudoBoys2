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

    /// Número de tomas de todo el tratamiento.
    var totalDosis: Int {
        guard cadaHoras > 0 else { return 0 }
        return max(1, dias * 24 / cadaHoras)
    }

    /// "Cada 8 h · 5 días".
    var pauta: String {
        "Cada \(cadaHoras) h · \(dias) \(dias == 1 ? "día" : "días")"
    }
}
