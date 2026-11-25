import Foundation
import Observation

/// Reservar en un negocio: para quién, qué servicio y cuándo.
@Observable
final class ReservarViewModel: Identifiable {
    enum Paciente: Hashable {
        case mascota(UUID)
        /// Emergencia: sin crear perfil, solo especie, motivo y teléfono.
        case sinPerfil
    }

    let negocio: Negocio
    private(set) var mascotas: [Mascota] = []

    var paciente: Paciente? {
        didSet { if paciente != oldValue { ajustarHorario() } }
    }
    var especieEmergencia: Especie
    var motivo = ""
    var telefono = ""

    var tipo: TipoServicio {
        didSet { if tipo != oldValue { servicio = serviciosDisponibles.first } }
    }
    var servicio: Servicio?
    var dia: Date {
        didSet { if dia != oldValue { ajustarHorario() } }
    }
    var horario: Date?

    private(set) var citaConfirmada: Cita?
    var mensajeError: String?

    /// Momento en que se abrió la hoja; es el horario "Ahora" de las emergencias.
    let ahora: Date

    @ObservationIgnored private let tutor: Usuario?
    @ObservationIgnored private let citas: any CitaRepository
    @ObservationIgnored private let repositorioMascotas: any MascotaRepository
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
        self.repositorioMascotas = mascotas
        self.servicios = servicios
        self.ahora = ahora
        self.calendario = calendario
        self.tipo = negocio.tipo.ofrece(.veterinaria) && !negocio.tipo.ofrece(.estetica) ? .veterinaria : .estetica
        self.especieEmergencia = negocio.especiesAtendidas.first ?? .perro
        self.dia = calendario.startOfDay(for: ahora)

        if let tutor {
            self.mascotas = (try? mascotas.mascotas(de: tutor)) ?? []
        }
        self.servicio = serviciosDisponibles.first
        if let primerDia = dias.first { self.dia = primerDia }
        if let primera = self.mascotas.first(where: atiende) {
            self.paciente = .mascota(primera.id)
        }
        ajustarHorario()
    }

    // MARK: - Opciones

    var eligeTipo: Bool { negocio.tipo == .ambos }

    var serviciosDisponibles: [Servicio] {
        negocio.servicios.filter { $0.tipo == tipo }.sorted { $0.precio < $1.precio }
    }

    func atiende(_ mascota: Mascota) -> Bool {
        negocio.especiesAtendidas.contains(mascota.especie)
    }

    var esSinPerfil: Bool { paciente == .sinPerfil }

    /// Próximos días en que el negocio abre y todavía tiene horarios.
    var dias: [Date] {
        let hoy = calendario.startOfDay(for: ahora)
        return (0..<10)
            .compactMap { calendario.date(byAdding: .day, value: $0, to: hoy) }
            .filter { !horarios(del: $0, conAhora: true).isEmpty }
            .prefix(7)
            .map { $0 }
    }

    /// Horarios del día elegido. En emergencias con el negocio abierto, el primero es "Ahora".
    var horarios: [Date] { horarios(del: dia, conAhora: esSinPerfil) }

    func esAhora(_ fecha: Date) -> Bool { fecha == ahora }

    private func horarios(del dia: Date, conAhora: Bool) -> [Date] {
        let diaSemana = calendario.component(.weekday, from: dia)
        guard negocio.diasAbiertos.contains(diaSemana) else { return [] }
        let inicio = calendario.startOfDay(for: dia)
        var resultado: [Date] = []
        if conAhora, calendario.isDate(dia, inSameDayAs: ahora), negocio.estaAbierto(en: ahora, calendario: calendario) {
            resultado.append(ahora)
        }
        // Las citas programadas se ofrecen de 8:00 a 20:00 aunque el negocio abra 24 horas;
        // fuera de ese horario queda "Ahora" para emergencias.
        var minuto = max(negocio.minutoApertura, 8 * 60)
        while minuto + 30 <= min(negocio.minutoCierre, 20 * 60) {
            if let fecha = calendario.date(byAdding: .minute, value: minuto, to: inicio), fecha > ahora {
                resultado.append(fecha)
            }
            minuto += 30
        }
        return resultado
    }

    private func ajustarHorario() {
        let opciones = horarios
        if esSinPerfil, let primero = opciones.first, esAhora(primero) {
            horario = primero
        } else if let horario, opciones.contains(horario), !esAhora(horario) {
            return
        } else {
            horario = nil
        }
    }

    // MARK: - Confirmar

    private var motivoLimpio: String { motivo.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var telefonoLimpio: String { telefono.filter(\.isNumber) }

    /// Lo que falta para poder confirmar; `nil` si ya está todo.
    var pendiente: String? {
        guard let paciente else { return "Elige para quién es la cita" }
        if paciente == .sinPerfil {
            if motivoLimpio.isEmpty { return "Cuéntanos el motivo" }
            if telefonoLimpio.count < 8 { return "Agrega un teléfono de contacto" }
        }
        if horario == nil { return "Elige un horario" }
        return nil
    }

    var puedeConfirmar: Bool { pendiente == nil }

    func confirmar() {
        guard let paciente, let horario else { return }
        do {
            switch paciente {
            case .mascota(let id):
                guard let mascota = mascotas.first(where: { $0.id == id }) else { return }
                citaConfirmada = try citas.reservar(
                    en: negocio, fecha: horario, tipo: tipo, servicio: servicio, mascota: mascota, tutor: tutor
                )
            case .sinPerfil:
                let datos = DatosEmergencia(especie: especieEmergencia, motivo: motivoLimpio, telefono: telefonoLimpio)
                let cita = try citas.reservarSinPerfil(en: negocio, fecha: horario, tipo: tipo, datos: datos, tutor: tutor)
                cita.servicio = servicio
                citaConfirmada = cita
            }
            // El permiso se pide aquí para poder avisar "Listo para recoger".
            let notificaciones = servicios.notificaciones
            Task { await notificaciones.pedirPermiso() }
        } catch {
            mensajeError = "No pudimos reservar tu cita. Inténtalo de nuevo."
        }
    }
}
