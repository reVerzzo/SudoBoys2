import Foundation
import SwiftData

/// Reseña de una cita real: solo existe ligada a una cita terminada.
@Model
final class Resena {
    @Attribute(.unique) var id: UUID
    /// De 1 a 5.
    var calificacion: Int
    var texto: String
    var fecha: Date

    var cita: Cita?

    init(id: UUID = UUID(), calificacion: Int, texto: String, fecha: Date = .now) {
        self.id = id
        self.calificacion = min(max(calificacion, 1), 5)
        self.texto = texto
        self.fecha = fecha
    }
}
