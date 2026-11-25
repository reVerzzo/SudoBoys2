import Foundation

/// Una etapa de un servicio: lo que ve el tutor en el avance de su cita.
/// Cada servicio define las suyas, con los minutos estimados de cada una.
nonisolated struct EtapaCita: Codable, Hashable, Sendable {
    var titulo: String
    var icono: String
    /// Minutos estimados de la etapa (0 en la última: ya está lista).
    var minutos: Int

    init(_ titulo: String, minutos: Int = 0, icono: String? = nil) {
        self.titulo = titulo
        self.minutos = max(0, minutos)
        self.icono = icono ?? Self.icono(para: titulo)
    }

    /// Ícono según el nombre de la etapa, para las que escribe el negocio.
    static func icono(para titulo: String) -> String {
        let texto = titulo.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_MX")).lowercased()
        let reglas: [(String, String)] = [
            ("recib", "checkmark.circle.fill"),
            ("bano", "shower.fill"),
            ("secad", "wind"),
            ("unas", "scissors"),
            ("corte", "scissors"),
            ("revis", "stethoscope"),
            ("consult", "stethoscope"),
            ("valora", "stethoscope"),
            ("diagn", "list.clipboard.fill"),
            ("aplica", "syringe.fill"),
            ("vacun", "syringe.fill"),
            ("observ", "eye.fill"),
            ("trata", "cross.case.fill"),
            ("ciru", "cross.case.fill"),
            ("estable", "heart.fill"),
            ("listo", "pawprint.fill"),
        ]
        return reglas.first { texto.contains($0.0) }?.1 ?? "pawprint.fill"
    }

    // MARK: - Plantillas

    static let recibido = EtapaCita("Recibido", minutos: 5)
    static let listo = EtapaCita("Listo")

    static let corteDeUnas = [EtapaCita("Recibido", minutos: 2), EtapaCita("Corte de uñas", minutos: 13), listo]
    static let bano = [recibido, EtapaCita("Baño", minutos: 30), EtapaCita("Secado", minutos: 25), listo]
    static let banoYCorte = [
        recibido, EtapaCita("Baño", minutos: 30), EtapaCita("Secado", minutos: 25), EtapaCita("Corte", minutos: 30), listo,
    ]
    static let consulta = [recibido, EtapaCita("Revisión", minutos: 15), EtapaCita("Diagnóstico", minutos: 10), listo]
    static let vacunacion = [
        recibido, EtapaCita("Revisión", minutos: 5), EtapaCita("Aplicación", minutos: 5),
        EtapaCita("Observación", minutos: 10), listo,
    ]
    static let urgencia = [
        recibido, EtapaCita("Valoración", minutos: 10), EtapaCita("Tratamiento", minutos: 30), EtapaCita("Estable"),
    ]

    /// Etapas por omisión cuando la cita no tiene servicio.
    static func flujo(para tipo: TipoServicio) -> [EtapaCita] {
        switch tipo {
        case .estetica: banoYCorte
        case .veterinaria: consulta
        }
    }

    /// Plantilla según el nombre del servicio; sirve de punto de partida al crear uno.
    static func plantilla(servicio nombre: String, tipo: TipoServicio) -> [EtapaCita] {
        let texto = nombre.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_MX")).lowercased()
        if texto.contains("vacun") { return vacunacion }
        if texto.contains("unas") { return corteDeUnas }
        if texto.contains("bano"), texto.contains("corte") { return banoYCorte }
        if texto.contains("bano") { return bano }
        if texto.contains("urgenc") || texto.contains("emergenc") { return urgencia }
        return flujo(para: tipo)
    }

    // MARK: - Guardado

    static func codificar(_ etapas: [EtapaCita]) -> Data {
        (try? JSONEncoder().encode(etapas)) ?? Data()
    }

    static func decodificar(_ datos: Data) -> [EtapaCita] {
        guard !datos.isEmpty else { return [] }
        return (try? JSONDecoder().decode([EtapaCita].self, from: datos)) ?? []
    }
}

extension Array where Element == EtapaCita {
    nonisolated var minutosTotales: Int { reduce(0) { $0 + $1.minutos } }
}
