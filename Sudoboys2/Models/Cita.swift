import Foundation
import SwiftData

@Model
final class Cita {
    @Attribute(.unique) var id: UUID
    var fecha: Date
    var tipoServicio: TipoServicio
    var esUrgencia: Bool
    var estado: EstadoCita
    /// `nil` hasta el check-in.
    var etapaActual: EtapaCita?
    @Attribute(.externalStorage) var fotoFinal: Data?

    // Datos de emergencia para una cita sin perfil (`mascota == nil`).
    var especieEmergencia: Especie?
    var motivoEmergencia: String?
    var telefonoEmergencia: String?

    var negocio: Negocio?
    /// `nil` = cita sin perfil.
    var mascota: Mascota?
    /// Quien reservó; permite listar también las citas sin perfil.
    var tutor: Usuario?
    var servicio: Servicio?

    @Relationship(deleteRule: .cascade, inverse: \Resena.cita)
    var resena: Resena?

    @Relationship(inverse: \Receta.cita)
    var receta: Receta?

    init(
        id: UUID = UUID(),
        fecha: Date,
        tipoServicio: TipoServicio,
        esUrgencia: Bool = false,
        estado: EstadoCita = .programada,
        etapaActual: EtapaCita? = nil,
        especieEmergencia: Especie? = nil,
        motivoEmergencia: String? = nil,
        telefonoEmergencia: String? = nil
    ) {
        self.id = id
        self.fecha = fecha
        self.tipoServicio = tipoServicio
        self.esUrgencia = esUrgencia
        self.estado = estado
        self.etapaActual = etapaActual
        self.especieEmergencia = especieEmergencia
        self.motivoEmergencia = motivoEmergencia
        self.telefonoEmergencia = telefonoEmergencia
    }

    var esSinPerfil: Bool { mascota == nil }

    /// Especie de la mascota, o la capturada en la emergencia.
    var especie: Especie? { mascota?.especie ?? especieEmergencia }

    var etapas: [EtapaCita] { EtapaCita.flujo(para: tipoServicio) }

    /// La etapa que sigue, o `nil` si no ha hecho check-in o ya terminó.
    var siguienteEtapa: EtapaCita? {
        guard let etapaActual, let indice = etapas.firstIndex(of: etapaActual) else { return nil }
        let siguiente = etapas.index(after: indice)
        return siguiente < etapas.endIndex ? etapas[siguiente] : nil
    }
}
