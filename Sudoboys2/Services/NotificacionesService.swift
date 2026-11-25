import Foundation
import OSLog
import UserNotifications

/// Notificaciones locales (sin push remoto).
@MainActor
protocol NotificacionesService {
    /// Pide permiso si aún no se ha decidido. Devuelve si se pueden mostrar avisos.
    @discardableResult
    func pedirPermiso() async -> Bool
    /// Aviso "Listo para recoger" al terminar la cita.
    func avisarListoParaRecoger(mascota: String, negocio: String) async
    /// Aviso al negocio de una urgencia en camino.
    func avisarUrgencia(especie: String, motivo: String, minutos: Int?) async
    /// Avisa de la receta nueva y programa un recordatorio por cada dosis.
    /// Devuelve cuántos recordatorios quedaron programados.
    @discardableResult
    func programarRecordatorios(de receta: Receta) async -> Int
    /// Quita los avisos pendientes y los ya entregados (al restablecer los datos de demo).
    func cancelarTodo()
}

/// Un recordatorio de dosis: cuánto falta y qué dice.
nonisolated struct RecordatorioDosis: Equatable, Sendable {
    var segundos: TimeInterval
    var medicamento: String
    var indicacion: String
}

extension Receta {
    /// Una dosis cada `cadaHoras`, empezando una toma después de emitir la receta,
    /// de la más próxima a la más lejana. En modo demo la primera llega al minuto,
    /// para poder mostrarla en la presentación; las demás conservan su horario.
    func recordatoriosDeDosis(modoDemo: Bool, maximo: Int = NotificacionesLocales.maximoRecordatorios) -> [RecordatorioDosis] {
        var dosis: [RecordatorioDosis] = []
        for medicamento in medicamentos where medicamento.cadaHoras > 0 && medicamento.totalDosis > 0 {
            for toma in 1...medicamento.totalDosis {
                dosis.append(RecordatorioDosis(
                    segundos: TimeInterval(toma * medicamento.cadaHoras * 3600),
                    medicamento: medicamento.nombre,
                    indicacion: medicamento.dosis
                ))
            }
        }
        // Orden estable: a la misma hora, por nombre del medicamento.
        dosis.sort { ($0.segundos, $0.medicamento) < ($1.segundos, $1.medicamento) }
        var proximas = Array(dosis.prefix(maximo))
        if modoDemo, !proximas.isEmpty {
            proximas[0].segundos = PreferenciasDemo.segundosPrimerRecordatorio
        }
        return proximas
    }
}

struct NotificacionesSinEfecto: NotificacionesService {
    nonisolated init() {}
    func pedirPermiso() async -> Bool { false }
    func avisarListoParaRecoger(mascota: String, negocio: String) async {}
    func avisarUrgencia(especie: String, motivo: String, minutos: Int?) async {}
    func programarRecordatorios(de receta: Receta) async -> Int { 0 }
    func cancelarTodo() {}
}

final class NotificacionesLocales: NSObject, NotificacionesService, UNUserNotificationCenterDelegate {
    private let centro = UNUserNotificationCenter.current()
    private let registro = Logger(subsystem: "Sudoboys2", category: "Notificaciones")
    /// De aquí se lee el modo demo al programar los recordatorios.
    private let almacen: UserDefaults

    init(almacen: UserDefaults = .standard) {
        self.almacen = almacen
        super.init()
        // Para que el aviso también se vea con la app abierta (los dos roles viven en el mismo iPhone).
        centro.delegate = self
    }

    @discardableResult
    func pedirPermiso() async -> Bool {
        do {
            return try await centro.requestAuthorization(options: [.alert, .sound])
        } catch {
            registro.error("No se pudo pedir permiso de notificaciones: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func avisarListoParaRecoger(mascota: String, negocio: String) async {
        guard await pedirPermiso() else { return }
        let contenido = UNMutableNotificationContent()
        contenido.title = "Listo para recoger"
        contenido.body = negocio.isEmpty
            ? "\(mascota) ya te está esperando."
            : "\(mascota) ya te está esperando en \(negocio)."
        contenido.sound = .default
        let disparador = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let solicitud = UNNotificationRequest(identifier: UUID().uuidString, content: contenido, trigger: disparador)
        do {
            try await centro.add(solicitud)
        } catch {
            registro.error("No se pudo programar el aviso: \(error.localizedDescription, privacy: .public)")
        }
    }

    func avisarUrgencia(especie: String, motivo: String, minutos: Int?) async {
        guard await pedirPermiso() else { return }
        let contenido = UNMutableNotificationContent()
        contenido.title = "Urgencia en camino"
        contenido.body = TextoUrgencia.aviso(especie: especie, motivo: motivo, minutos: minutos)
        contenido.sound = .default
        contenido.interruptionLevel = .timeSensitive
        await agregar(contenido, en: 1, id: UUID().uuidString)
    }

    /// iOS conserva como máximo 64 avisos pendientes por app; se programan los más próximos.
    nonisolated static let maximoRecordatorios = 60

    @discardableResult
    func programarRecordatorios(de receta: Receta) async -> Int {
        guard await pedirPermiso() else { return 0 }
        let mascota = receta.mascota?.nombre ?? "tu mascota"

        let aviso = UNMutableNotificationContent()
        aviso.title = "Receta nueva para \(mascota)"
        aviso.body = receta.requiereRecetaFisica
            ? "Ya está en su historial. Recuerda pedir la receta física para surtirla."
            : "Ya está en su historial. Te recordaremos cada dosis."
        aviso.sound = .default
        await agregar(aviso, en: 2, id: "receta-\(receta.id.uuidString)")

        let proximas = receta.recordatoriosDeDosis(modoDemo: almacen.bool(forKey: PreferenciasDemo.claveModoDemo))
        for (indice, toma) in proximas.enumerated() {
            let contenido = UNMutableNotificationContent()
            contenido.title = "Medicina de \(mascota)"
            contenido.body = "\(toma.medicamento): \(toma.indicacion)"
            contenido.sound = .default
            await agregar(contenido, en: toma.segundos, id: "dosis-\(receta.id.uuidString)-\(indice)")
        }
        return proximas.count
    }

    func cancelarTodo() {
        centro.removeAllPendingNotificationRequests()
        centro.removeAllDeliveredNotifications()
    }

    private func agregar(_ contenido: UNMutableNotificationContent, en segundos: TimeInterval, id: String) async {
        let disparador = UNTimeIntervalNotificationTrigger(timeInterval: max(segundos, 1), repeats: false)
        do {
            try await centro.add(UNNotificationRequest(identifier: id, content: contenido, trigger: disparador))
        } catch {
            registro.error("No se pudo programar el aviso: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

nonisolated enum TextoUrgencia {
    /// "Urgencia: Gato, vómito. Llegan en ~8 min".
    static func aviso(especie: String, motivo: String, minutos: Int?) -> String {
        let motivo = motivo.trimmingCharacters(in: .whitespacesAndNewlines)
        let inicio = motivo.isEmpty ? "Urgencia: \(especie)." : "Urgencia: \(especie), \(motivo)."
        guard let minutos else { return inicio }
        return "\(inicio) Llegan en ~\(minutos) min"
    }
}

/// Servicios que acompañan una cita: Live Activity, avisos locales, ubicación y rutas.
struct ServiciosCitas {
    var liveActivity: any LiveActivityService = LiveActivitySinEfecto()
    var notificaciones: any NotificacionesService = NotificacionesSinEfecto()
    var ubicacion: any UbicacionService = UbicacionFija()
    var rutas: any RutasService = RutasSinEfecto()

    /// Implementaciones reales; se crean una sola vez en la app.
    static func reales() -> ServiciosCitas {
        ServiciosCitas(
            liveActivity: LiveActivityActivityKit(),
            notificaciones: NotificacionesLocales(),
            ubicacion: UbicacionCoreLocation(),
            rutas: RutasMapKit()
        )
    }
}
