import CoreLocation
import Foundation
import MapKit
import Observation

/// Ubicación actual del dispositivo. `actual` es `nil` sin permiso o sin señal:
/// quien la usa cae a Ciudad Universitaria como respaldo.
protocol UbicacionService: AnyObject {
    var actual: PuntoGeografico? { get }
    /// Pide permiso (si falta) y empieza a seguir la ubicación. Se puede llamar varias veces.
    func solicitar()
}

/// Para vistas previas y pruebas: una ubicación fija, o ninguna.
@Observable
final class UbicacionFija: UbicacionService {
    var actual: PuntoGeografico?

    init(_ actual: PuntoGeografico? = nil) {
        self.actual = actual
    }

    func solicitar() {}
}

@Observable
final class UbicacionCoreLocation: UbicacionService {
    private(set) var actual: PuntoGeografico?
    @ObservationIgnored private var tarea: Task<Void, Never>?

    func solicitar() {
        guard tarea == nil else { return }
        tarea = Task { [weak self] in
            // La sesión pide el permiso "al usar la app" y lo mantiene mientras viva.
            let sesion = CLServiceSession(authorization: .whenInUse)
            defer { withExtendedLifetime(sesion) {} }
            do {
                for try await novedad in CLLocationUpdate.liveUpdates() {
                    guard let self else { return }
                    if novedad.authorizationDenied {
                        self.actual = nil
                    } else if let lugar = novedad.location {
                        self.registrar(lugar.coordinate)
                    }
                }
            } catch {
                self?.actual = nil
            }
        }
    }

    /// Solo publica cambios de más de 30 m, para no recalcular distancias de más.
    private func registrar(_ coordenada: CLLocationCoordinate2D) {
        let punto = PuntoGeografico(latitud: coordenada.latitude, longitud: coordenada.longitude)
        if let actual, actual.distanciaKm(a: punto) < 0.03 { return }
        actual = punto
    }
}

// MARK: - Tiempo de llegada

/// Tiempo de traslado en auto entre dos puntos.
protocol RutasService {
    /// Minutos de camino; `nil` si no se pudo calcular (por ejemplo, sin internet).
    func minutos(desde origen: PuntoGeografico, a destino: PuntoGeografico) async -> Int?
}

struct RutasSinEfecto: RutasService {
    func minutos(desde origen: PuntoGeografico, a destino: PuntoGeografico) async -> Int? { nil }
}

/// Tiempo real con tráfico, con MapKit.
struct RutasMapKit: RutasService {
    func minutos(desde origen: PuntoGeografico, a destino: PuntoGeografico) async -> Int? {
        let solicitud = MKDirections.Request()
        solicitud.source = MKMapItem(location: CLLocation(latitude: origen.latitud, longitude: origen.longitud), address: nil)
        solicitud.destination = MKMapItem(location: CLLocation(latitude: destino.latitud, longitude: destino.longitud), address: nil)
        solicitud.transportType = .automobile
        guard let respuesta = try? await MKDirections(request: solicitud).calculateETA() else { return nil }
        return max(1, Int((respuesta.expectedTravelTime / 60).rounded()))
    }
}

extension PuntoGeografico {
    /// Respaldo sin internet: tiempo aproximado en ciudad con tráfico (unos 14 km/h más 3 minutos de salida).
    nonisolated func minutosAproximados(a destino: PuntoGeografico) -> Int {
        max(3, Int((distanciaKm(a: destino) / 14 * 60).rounded()) + 3)
    }
}
