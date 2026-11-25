import Foundation
import SwiftData

@Model
final class Cita {
    @Attribute(.unique) var id: UUID
    var fecha: Date
    var tipoServicio: TipoServicio
    var esUrgencia: Bool
    var estado: EstadoCita
    /// Posición de la etapa actual dentro de `etapas`; `nil` hasta el check-in.
    var indiceEtapa: Int?
    /// Etapas fijadas al hacer check-in (JSON); antes de eso se leen del servicio.
    var etapasDatos: Data = Data()
    /// Momento del check-in.
    var horaLlegada: Date?
    /// Momento en que empezó la etapa actual; base del tiempo estimado.
    var horaEtapa: Date?
    /// Urgencias: minutos estimados de camino al reservar.
    var minutosLlegada: Int?
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
        indiceEtapa: Int? = nil,
        especieEmergencia: Especie? = nil,
        motivoEmergencia: String? = nil,
        telefonoEmergencia: String? = nil
    ) {
        self.id = id
        self.fecha = fecha
        self.tipoServicio = tipoServicio
        self.esUrgencia = esUrgencia
        self.estado = estado
        self.indiceEtapa = indiceEtapa
        self.especieEmergencia = especieEmergencia
        self.motivoEmergencia = motivoEmergencia
        self.telefonoEmergencia = telefonoEmergencia
    }

    var esSinPerfil: Bool { mascota == nil }

    /// Especie de la mascota, o la capturada en la emergencia.
    var especie: Especie? { mascota?.especie ?? especieEmergencia }

    /// Etapas de la cita: las fijadas en el check-in o, antes, las del servicio elegido.
    var etapas: [EtapaCita] {
        let fijadas = EtapaCita.decodificar(etapasDatos)
        if !fijadas.isEmpty { return fijadas }
        if let servicio { return servicio.etapas }
        return esUrgencia ? EtapaCita.urgencia : EtapaCita.flujo(para: tipoServicio)
    }

    /// Congela las etapas del servicio: si el negocio lo edita después, esta cita no cambia.
    func fijarEtapas() {
        etapasDatos = EtapaCita.codificar(etapas)
    }

    /// Índice para dibujar el avance. Una cita terminada siempre está en la última etapa
    /// y una en curso sin índice (datos de una versión anterior) se toma como recién recibida.
    var indiceEtapaVisible: Int? {
        switch estado {
        case .terminada: etapas.count - 1
        case .enCurso: indiceEtapa ?? 0
        case .programada, .cancelada: indiceEtapa
        }
    }

    var etapaActual: EtapaCita? {
        guard let indice = indiceEtapaVisible, etapas.indices.contains(indice) else { return nil }
        return etapas[indice]
    }

    /// La etapa que sigue, o `nil` si no ha hecho check-in o ya terminó.
    var siguienteEtapa: EtapaCita? {
        guard let indice = indiceEtapaVisible, etapas.indices.contains(indice + 1) else { return nil }
        return etapas[indice + 1]
    }

    /// Verdadero si el siguiente paso es el último (la cita termina).
    var siguienteEsFinal: Bool {
        guard let indice = indiceEtapaVisible else { return false }
        return indice + 1 == etapas.count - 1
    }

    /// Suma de los minutos de las etapas que faltan, contando la actual.
    var minutosRestantes: Int {
        Array(etapas.dropFirst(indiceEtapaVisible ?? 0)).minutosTotales
    }

    /// Nombre de la mascota, o un texto genérico para la cita sin perfil.
    var nombreMascota: String {
        mascota?.nombre ?? "\(especieEmergencia?.titulo ?? "Mascota") sin perfil"
    }

    /// Duración estimada en minutos: la suma de sus etapas.
    var duracionMinutos: Int {
        let total = etapas.minutosTotales
        return total > 0 ? total : (servicio?.duracionMinutos ?? 30)
    }

    /// Tiempo que ocupa la cita en la agenda.
    var intervalo: DateInterval {
        DateInterval(start: fecha, duration: TimeInterval(duracionMinutos * 60))
    }

    /// Programada o en curso: todavía ocupa su horario.
    var estaActiva: Bool { estado == .programada || estado == .enCurso }

    /// Hora aproximada en que estará lista: lo que falta a partir de la etapa actual
    /// (o de la hora de la cita si aún no llega).
    var horaEstimadaListo: Date {
        (horaEtapa ?? horaLlegada ?? fecha).addingTimeInterval(TimeInterval(minutosRestantes * 60))
    }
}

extension DateInterval {
    /// Verdadero si los dos intervalos comparten tiempo (tocarse en el borde no cuenta).
    nonisolated func seEncima(con otro: DateInterval) -> Bool {
        start < otro.end && otro.start < end
    }
}
