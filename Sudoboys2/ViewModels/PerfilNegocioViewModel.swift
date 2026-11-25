import Foundation
import Observation

/// Perfil de un negocio visto por el tutor.
@Observable
final class PerfilNegocioViewModel {
    let negocio: Negocio
    let distanciaKm: Double?
    /// Desde dónde se midió la distancia: "tu ubicación" o el punto de respaldo.
    let nombreOrigen: String

    @ObservationIgnored private let reloj: () -> Date

    init(
        negocio: Negocio,
        distanciaKm: Double? = nil,
        nombreOrigen: String = ExplorarViewModel.nombreReferencia,
        reloj: @escaping () -> Date = { .now }
    ) {
        self.negocio = negocio
        self.distanciaKm = distanciaKm
        self.nombreOrigen = nombreOrigen
        self.reloj = reloj
    }

    var estaAbierto: Bool { negocio.estaAbierto(en: reloj()) }

    /// Servicios agrupados por tipo, cada grupo por precio.
    var gruposDeServicios: [(tipo: TipoServicio, servicios: [Servicio])] {
        TipoServicio.allCases.compactMap { tipo in
            let servicios = negocio.servicios
                .filter { $0.tipo == tipo }
                .sorted { $0.precio < $1.precio }
            return servicios.isEmpty ? nil : (tipo, servicios)
        }
    }

    var resenas: [Resena] { negocio.resenas }

    var textoDisponibilidad: String {
        switch negocio.disponibilidadHoy {
        case 0: "Sin lugares hoy"
        case 1: "Queda 1 lugar hoy"
        default: "\(negocio.disponibilidadHoy) lugares hoy"
        }
    }
}
