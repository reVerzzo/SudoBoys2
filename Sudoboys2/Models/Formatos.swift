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

extension Locale {
    /// Español de México, sin depender del idioma del dispositivo.
    static let mx = Locale(identifier: "es_MX")
}

extension Date {
    /// "25 ene 2026".
    var fechaCorta: String {
        formatted(.dateTime.day().month(.abbreviated).year().locale(.mx))
    }
}

extension Mascota {
    /// "Conejo" para exóticos con detalle; si no, el nombre de la especie.
    var especieTexto: String {
        let detalle = detalleEspecie.trimmingCharacters(in: .whitespacesAndNewlines)
        return detalle.isEmpty ? especie.titulo : detalle
    }

    /// "4 años", "8 meses"; `nil` sin fecha de nacimiento.
    func edadTexto(en fecha: Date = .now) -> String? {
        guard let nacimiento else { return nil }
        let partes = Calendar.current.dateComponents([.year, .month], from: nacimiento, to: fecha)
        let anios = partes.year ?? 0
        let meses = partes.month ?? 0
        if anios >= 1 { return anios == 1 ? "1 año" : "\(anios) años" }
        if meses >= 1 { return meses == 1 ? "1 mes" : "\(meses) meses" }
        return "Recién nacido"
    }

    /// "Perro · Mestizo · 4 años".
    func resumen(en fecha: Date = .now) -> String {
        let razaLimpia = raza.trimmingCharacters(in: .whitespacesAndNewlines)
        return [especieTexto, razaLimpia.isEmpty ? nil : razaLimpia, edadTexto(en: fecha)]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
