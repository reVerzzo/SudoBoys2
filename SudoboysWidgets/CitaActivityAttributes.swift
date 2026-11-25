import ActivityKit
import Foundation

// IMPORTANTE: este archivo existe idéntico en `SudoboysWidgets/`. ActivityKit empareja
// la app y la extensión por el nombre del tipo; si cambias uno, cambia el otro.

/// Datos de la Live Activity que acompaña una cita en curso.
nonisolated struct CitaActivityAttributes: ActivityAttributes {
    struct Etapa: Codable, Hashable, Sendable {
        var titulo: String
        var icono: String
    }

    struct ContentState: Codable, Hashable, Sendable {
        /// Posición de la etapa actual dentro de `etapas`.
        var indiceEtapa: Int
        /// Hora aproximada en que la mascota estará lista.
        var horaEstimada: Date
    }

    var citaID: String
    var nombreMascota: String
    var nombreNegocio: String
    var iconoEspecie: String
    var etapas: [Etapa]
}

extension CitaActivityAttributes {
    func etapaActual(_ estado: ContentState) -> Etapa {
        guard !etapas.isEmpty else { return Etapa(titulo: "En curso", icono: "pawprint.fill") }
        return etapas[min(max(estado.indiceEtapa, 0), etapas.count - 1)]
    }

    func estaLista(_ estado: ContentState) -> Bool {
        estado.indiceEtapa >= etapas.count - 1
    }
}
