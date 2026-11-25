import Foundation
import Observation

/// Reservar en un negocio: para quién, qué servicio y cuándo.
/// Las urgencias no pasan por aquí: van sin horario (ver `UrgenciaViewModel`).
@Observable
final class ReservarViewModel: Identifiable {
    /// Por qué no se puede elegir un horario.
    enum Ocupado: Hashable {
        /// La mascota ya tiene otra cita que se encima.
        case mascota
        /// El negocio ya tiene una cita en ese horario.
        case negocio
    }

    struct Horario: Identifiable, Hashable {
        let fecha: Date
        let ocupado: Ocupado?
        var id: Date { fecha }
        var disponible: Bool { ocupado == nil }
    }

    let negocio: Negocio
    private(set) var mascotas: [Mascota] = []

    var idMascota: UUID? {
        didSet { if idMascota != oldValue { ajustarHorario() } }
    }

    var tipo: TipoServicio {
        didSet { if tipo != oldValue { servicio = serviciosDisponibles.first } }
    }
    var servicio: Servicio? {
        didSet { if servicio?.id != oldValue?.id { ajustarHorario() } }
    }
    var dia: Date {
        didSet { if dia != oldValue { ajustarHorario() } }
    }
    var horario: Date?

    private(set) var citaConfirmada: Cita?
    var mensajeError: String?

    /// Momento en que se abrió la hoja.
    let ahora: Date

    @ObservationIgnored private let tutor: Usuario?
    @ObservationIgnored private let citas: any CitaRepository
    @ObservationIgnored private let servicios: ServiciosCitas
    @ObservationIgnored private let calendario: Calendar

    init(
        negocio: Negocio,
        tutor: Usuario?,
        citas: any CitaRepository,
        mascotas: any MascotaRepository,
        servicios: ServiciosCitas = ServiciosCitas(),
        ahora: Date = .now,
        calendario: Calendar = .current
    ) {
        self.negocio = negocio
        self.tutor = tutor
        self.citas = citas
        self.servicios = servicios
        self.ahora = ahora
        self.calendario = calendario
        self.tipo = negocio.tipo.ofrece(.veterinaria) && !negocio.tipo.ofrece(.estetica) ? .veterinaria : .estetica
        self.dia = calendario.startOfDay(for: ahora)

        if let tutor {
            self.mascotas = (try? mascotas.mascotas(de: tutor)) ?? []
        }
        self.servicio = serviciosDisponibles.first
        if let primerDia = dias.first { self.dia = primerDia }
        self.idMascota = self.mascotas.first(where: atiende)?.id
        ajustarHorario()
    }

    // MARK: - Opciones

    var eligeTipo: Bool { negocio.tipo == .ambos }

    /// Los servicios que se agendan; "Urgencia" va por su propio flujo, sin horario.
    var serviciosDisponibles: [Servicio] {
        negocio.servicios
            .filter { $0.tipo == tipo && !$0.nombre.localizedCaseInsensitiveContains("urgencia") }
            .sorted { $0.precio < $1.precio }
    }

    func atiende(_ mascota: Mascota) -> Bool {
        negocio.especiesAtendidas.contains(mascota.especie)
    }

    var mascota: Mascota? { mascotas.first { $0.id == idMascota } }

    /// Minutos que ocupará la cita: la suma de las etapas del servicio.
    var duracionMinutos: Int {
        servicio?.duracionMinutos ?? EtapaCita.flujo(para: tipo).minutosTotales
    }

    /// Próximos días en que el negocio abre y todavía tiene horarios.
    var dias: [Date] {
        let hoy = calendario.startOfDay(for: ahora)
        return (0..<10)
            .compactMap { calendario.date(byAdding: .day, value: $0, to: hoy) }
            .filter { !fechas(del: $0).isEmpty }
            .prefix(7)
            .map { $0 }
    }

    /// Horarios del día elegido; los ocupados se muestran deshabilitados.
    var horarios: [Horario] {
        let duracion = TimeInterval(max(duracionMinutos, 1) * 60)
        let deLaMascota = (mascota?.citas ?? []).filter(\.estaActiva).map(\.intervalo)
        // Las urgencias no bloquean la agenda: se atienden al llegar.
        let delNegocio = negocio.citas.filter { $0.estaActiva && !$0.esUrgencia }.map(\.intervalo)
        return fechas(del: dia).map { fecha in
            let nueva = DateInterval(start: fecha, duration: duracion)
            if deLaMascota.contains(where: { $0.seEncima(con: nueva) }) {
                return Horario(fecha: fecha, ocupado: .mascota)
            }
            if delNegocio.contains(where: { $0.seEncima(con: nueva) }) {
                return Horario(fecha: fecha, ocupado: .negocio)
            }
            return Horario(fecha: fecha, ocupado: nil)
        }
    }

    /// Explica por qué hay horarios deshabilitados; `nil` si todos están libres.
    var avisoHorarios: String? {
        let horarios = horarios
        if horarios.contains(where: { $0.ocupado == .mascota }), let mascota {
            let otra = mascota.citas
                .filter { $0.estaActiva && calendario.isDate($0.fecha, inSameDayAs: dia) }
                .min { $0.fecha < $1.fecha }
            let detalle = otra.map { " (\($0.fecha.horaCorta))" } ?? ""
            return "\(mascota.nombre) ya tiene cita este día\(detalle) y no puede tener dos que se encimen: esos horarios no están disponibles"
        }
        if horarios.contains(where: { $0.ocupado == .negocio }) {
            return "Los horarios atenuados ya están ocupados."
        }
        return nil
    }

    private func fechas(del dia: Date) -> [Date] {
        let diaSemana = calendario.component(.weekday, from: dia)
        guard negocio.diasAbiertos.contains(diaSemana) else { return [] }
        let inicio = calendario.startOfDay(for: dia)
        var resultado: [Date] = []
        // Las citas programadas se ofrecen de 8:00 a 20:00 aunque el negocio abra 24 horas.
        var minuto = max(negocio.minutoApertura, 8 * 60)
        while minuto + 30 <= min(negocio.minutoCierre, 20 * 60) {
            if let fecha = calendario.date(byAdding: .minute, value: minuto, to: inicio), fecha > ahora {
                resultado.append(fecha)
            }
            minuto += 30
        }
        return resultado
    }

    /// Suelta el horario elegido si dejó de estar disponible.
    private func ajustarHorario() {
        guard let horario else { return }
        if !horarios.contains(where: { $0.fecha == horario && $0.disponible }) {
            self.horario = nil
        }
    }

    // MARK: - Confirmar

    /// Lo que falta para poder confirmar; `nil` si ya está todo.
    var pendiente: String? {
        if mascotas.isEmpty { return "Agrega a tu mascota en Mis mascotas" }
        if idMascota == nil { return "Elige para quién es la cita" }
        if horario == nil { return "Elige un horario" }
        return nil
    }

    var puedeConfirmar: Bool { pendiente == nil }

    func confirmar() {
        guard let mascota, let horario else { return }
        do {
            citaConfirmada = try citas.reservar(
                en: negocio, fecha: horario, tipo: tipo, servicio: servicio, mascota: mascota, tutor: tutor
            )
            // El permiso se pide aquí para poder avisar "Listo para recoger".
            let notificaciones = servicios.notificaciones
            Task { await notificaciones.pedirPermiso() }
        } catch ErrorRepositorio.citaEncimada {
            self.horario = nil
            mensajeError = "\(mascota.nombre) ya tiene una cita que se encima con ese horario. Elige otro."
        } catch {
            mensajeError = "No pudimos reservar tu cita. Inténtalo de nuevo."
        }
    }
}
