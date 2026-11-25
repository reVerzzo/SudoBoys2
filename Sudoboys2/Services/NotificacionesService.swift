import Foundation
import OSLog
import UserNotifications

/// Notificaciones locales (sin push remoto).
protocol NotificacionesService {
    /// Pide permiso si aún no se ha decidido. Devuelve si se pueden mostrar avisos.
    @discardableResult
    func pedirPermiso() async -> Bool
    /// Aviso "Listo para recoger" al terminar la cita.
    func avisarListoParaRecoger(mascota: String, negocio: String) async
}

struct NotificacionesSinEfecto: NotificacionesService {
    func pedirPermiso() async -> Bool { false }
    func avisarListoParaRecoger(mascota: String, negocio: String) async {}
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
