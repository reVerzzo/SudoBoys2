import Foundation
import SwiftData

@Model
final class Negocio {
    @Attribute(.unique) var id: UUID
    var nombre: String
    var tipo: TipoNegocio
    /// Especies atendidas como texto; usa `especiesAtendidas`.
    var especiesAtendidasCrudas: [String]
    var latitud: Double
    var longitud: Double
    var direccion: String
    /// Minutos desde medianoche (480 = 8:00).
    var minutoApertura: Int
    /// Minutos desde medianoche (1440 = medianoche: abierto hasta el final del día).
    var minutoCierre: Int
    /// Días abiertos con la numeración de `Calendar` (1 = domingo … 7 = sábado).
    var diasAbiertos: [Int]
    var calificacion: Double
    var estadoVerificacion: EstadoVerificacion
    /// Cédula profesional (solo veterinaria).
    var cedula: String?
    /// Foto de la cédula que se sube para revisión.
    @Attribute(.externalStorage) var fotoCedula: Data?
    /// Lugares libres para hoy.
    var disponibilidadHoy: Int

    var propietario: Usuario?

    @Relationship(deleteRule: .cascade, inverse: \Servicio.negocio)
    var servicios: [Servicio] = []

    @Relationship(deleteRule: .cascade, inverse: \Cita.negocio)
    var citas: [Cita] = []

    @Relationship(inverse: \Receta.negocio)
    var recetas: [Receta] = []

    init(
        id: UUID = UUID(),
        nombre: String,
        tipo: TipoNegocio,
        especiesAtendidas: [Especie],
        latitud: Double,
        longitud: Double,
        direccion: String,
        minutoApertura: Int = 9 * 60,
        minutoCierre: Int = 19 * 60,
        diasAbiertos: [Int] = [2, 3, 4, 5, 6, 7],
        calificacion: Double = 0,
        estadoVerificacion: EstadoVerificacion = .pendiente,
        cedula: String? = nil,
        disponibilidadHoy: Int = 0
    ) {
        self.id = id
        self.nombre = nombre
        self.tipo = tipo
        self.especiesAtendidasCrudas = especiesAtendidas.map(\.rawValue)
        self.latitud = latitud
        self.longitud = longitud
        self.direccion = direccion
        self.minutoApertura = minutoApertura
        self.minutoCierre = minutoCierre
        self.diasAbiertos = diasAbiertos
        self.calificacion = calificacion
        self.estadoVerificacion = estadoVerificacion
        self.cedula = cedula
        self.disponibilidadHoy = disponibilidadHoy
    }

    var especiesAtendidas: [Especie] {
        get { especiesAtendidasCrudas.compactMap(Especie.init(rawValue:)) }
        set { especiesAtendidasCrudas = newValue.map(\.rawValue) }
    }

    var estaVerificado: Bool { estadoVerificacion == .verificado }
    var disponibleHoy: Bool { disponibilidadHoy > 0 }

    /// Solo una veterinaria (o ambos) con cédula verificada puede emitir recetas.
    var puedeEmitirRecetas: Bool {
        estaVerificado && tipo.ofrece(.veterinaria) && !(cedula ?? "").isEmpty
    }

    var insignia: InsigniaNegocio? {
        guard estaVerificado else { return nil }
        return tipo.ofrece(.veterinaria) ? .cedulaVerificada : .negocioVerificado
    }

    /// Reseñas de citas reales, de la más reciente a la más antigua.
    var resenas: [Resena] {
        citas.compactMap(\.resena).sorted { $0.fecha > $1.fecha }
    }

    func estaAbierto(en fecha: Date = .now, calendario: Calendar = .current) -> Bool {
        let partes = calendario.dateComponents([.weekday, .hour, .minute], from: fecha)
        guard let dia = partes.weekday, diasAbiertos.contains(dia) else { return false }
        let minuto = (partes.hour ?? 0) * 60 + (partes.minute ?? 0)
        return minuto >= minutoApertura && minuto < minutoCierre
    }

    /// Horario legible, por ejemplo "9:00 – 19:00" o "Abierto 24 horas".
    var horarioTexto: String {
        if minutoApertura <= 0 && minutoCierre >= 24 * 60 { return "Abierto 24 horas" }
        func hora(_ minutos: Int) -> String {
            "\(minutos / 60):" + String(format: "%02d", minutos % 60)
        }
        return "\(hora(minutoApertura)) – \(hora(minutoCierre))"
    }
}
