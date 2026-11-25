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
    /// Avisa de la receta nueva y programa un recordatorio por cada dosis.
    /// Devuelve cuántos recordatorios quedaron programados.
    @discardableResult
    func programarRecordatorios(de receta: Receta) async -> Int
}

struct NotificacionesSinEfecto: NotificacionesService {
    nonisolated init() {}
    func pedirPermiso() async -> Bool { false }
    func avisarListoParaRecoger(mascota: String, negocio: String) async {}
    func programarRecordatorios(de receta: Receta) async -> Int { 0 }
}

final class NotificacionesLocales: NSObject, NotificacionesService, UNUserNotificationCenterDelegate {
    private let centro = UNUserNotificationCenter.current()
    private let registro = Logger(subsystem: "Sudoboys2", category: "Notificaciones")

    override init() {
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

    /// iOS conserva como máximo 64 avisos pendientes por app; se programan los más próximos.
    static let maximoRecordatorios = 60

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

        // Una dosis cada `cadaHoras`, empezando una toma después de emitir la receta.
        var dosis: [(segundos: TimeInterval, medicamento: String, indicacion: String)] = []
        for medicamento in receta.medicamentos where medicamento.cadaHoras > 0 {
            for toma in 1...medicamento.totalDosis {
                dosis.append((TimeInterval(toma * medicamento.cadaHoras * 3600), medicamento.nombre, medicamento.dosis))
            }
        }
        let proximas = dosis.sorted { $0.segundos < $1.segundos }.prefix(Self.maximoRecordatorios)
        for (indice, toma) in proximas.enumerated() {
            let contenido = UNMutableNotificationContent()
            contenido.title = "Medicina de \(mascota)"
            contenido.body = "\(toma.medicamento): \(toma.indicacion)"
            contenido.sound = .default
            await agregar(contenido, en: toma.segundos, id: "dosis-\(receta.id.uuidString)-\(indice)")
        }
        return proximas.count
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

/// Servicios que acompañan una cita: Live Activity y avisos locales.
struct ServiciosCitas {
    var liveActivity: any LiveActivityService = LiveActivitySinEfecto()
    var notificaciones: any NotificacionesService = NotificacionesSinEfecto()

    /// Implementaciones reales; se crean una sola vez en la app.
    static func reales() -> ServiciosCitas {
        ServiciosCitas(liveActivity: LiveActivityActivityKit(), notificaciones: NotificacionesLocales())
    }
}
