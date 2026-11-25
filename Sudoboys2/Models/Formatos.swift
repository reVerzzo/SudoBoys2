import Foundation

extension Sequence where Element == String {
    /// "a, b y c": lista en español de México, sin depender del idioma del dispositivo.
    var listaEnEspanol: String {
        Array(self).formatted(.list(type: .and).locale(Locale(identifier: "es_MX")))
    }
}

/// Punto en el mapa, sin depender de CoreLocation.
nonisolated struct PuntoGeografico: Equatable, Sendable {
    var latitud: Double
    var longitud: Double

    /// Distancia en kilómetros (fórmula del haversine).
    func distanciaKm(a otro: PuntoGeografico) -> Double {
        let radioTierraKm = 6371.0
        let dLat = (otro.latitud - latitud) * .pi / 180
        let dLon = (otro.longitud - longitud) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(latitud * .pi / 180) * cos(otro.latitud * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return radioTierraKm * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

extension Double {
    /// "850 m" o "2.4 km".
    var distanciaLegible: String {
        if self < 1 {
            let metros = (self * 1000 / 50).rounded() * 50
            return "\(Int(metros)) m"
        }
        return formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "es_MX"))) + " km"
    }
}
