import Foundation
import SwiftData

@Model
final class Servicio {
    @Attribute(.unique) var id: UUID
    var nombre: String
    /// Precio en pesos mexicanos.
    var precio: Decimal
    /// Suma de los minutos de sus etapas.
    var duracionMinutos: Int
    var tipo: TipoServicio
    /// Etapas en JSON; usa `etapas`.
    var etapasDatos: Data = Data()

    var negocio: Negocio?

    /// Sin `etapas`, toma la plantilla que corresponde al nombre del servicio.
    init(
        id: UUID = UUID(),
        nombre: String,
        precio: Decimal,
        duracionMinutos: Int? = nil,
        tipo: TipoServicio,
        etapas: [EtapaCita]? = nil
    ) {
        let etapas = etapas ?? EtapaCita.plantilla(servicio: nombre, tipo: tipo)
        self.id = id
        self.nombre = nombre
        self.precio = precio
        self.tipo = tipo
        self.etapasDatos = EtapaCita.codificar(etapas)
        self.duracionMinutos = etapas.minutosTotales > 0 ? etapas.minutosTotales : (duracionMinutos ?? 30)
    }

    /// Etapas del servicio con sus minutos. Al cambiarlas se actualiza la duración.
    var etapas: [EtapaCita] {
        get {
            let guardadas = EtapaCita.decodificar(etapasDatos)
            return guardadas.isEmpty ? EtapaCita.plantilla(servicio: nombre, tipo: tipo) : guardadas
        }
        set {
            etapasDatos = EtapaCita.codificar(newValue)
            if newValue.minutosTotales > 0 { duracionMinutos = newValue.minutosTotales }
        }
    }
}
