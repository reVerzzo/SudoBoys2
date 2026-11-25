import Foundation
import SwiftData

/// Filtros de Explorar. Se aplican en memoria (no con `#Predicate`).
nonisolated struct FiltroNegocios: Equatable, Sendable {
    var servicio: TipoServicio?
    /// Solo negocios que ofrecen estética y veterinaria.
    var soloAmbos = false
    var especie: Especie?
    var soloVerificados = false
    var disponibleHoy = false
    var abiertoAhora = false
    var calificacionMinima: Double?
}

protocol NegocioRepository {
    /// Todos los negocios, por nombre.
    func todos() throws -> [Negocio]
    func negocio(id: UUID) throws -> Negocio?
    /// Negocios que cumplen el filtro; `fecha` decide "abierto ahora".
    func buscar(_ filtro: FiltroNegocios, fecha: Date) throws -> [Negocio]
    func crear(_ negocio: Negocio, propietario: Usuario?) throws
    func agregar(_ servicio: Servicio, a negocio: Negocio) throws
    func actualizarVerificacion(de negocio: Negocio, a estado: EstadoVerificacion, cedula: String?) throws
    func guardar() throws
}

final class NegocioRepositorySwiftData: NegocioRepository {
    private let contexto: ModelContext

    init(contexto: ModelContext) {
        self.contexto = contexto
    }

    func todos() throws -> [Negocio] {
        try contexto.fetch(FetchDescriptor<Negocio>(sortBy: [SortDescriptor(\.nombre)]))
    }

    func negocio(id: UUID) throws -> Negocio? {
        var consulta = FetchDescriptor<Negocio>(predicate: #Predicate { $0.id == id })
        consulta.fetchLimit = 1
        return try contexto.fetch(consulta).first
    }

    func buscar(_ filtro: FiltroNegocios, fecha: Date) throws -> [Negocio] {
        try todos().filter { negocio in
            if let servicio = filtro.servicio, !negocio.tipo.ofrece(servicio) { return false }
            if filtro.soloAmbos, negocio.tipo != .ambos { return false }
            if let especie = filtro.especie, !negocio.especiesAtendidas.contains(especie) { return false }
            if filtro.soloVerificados, !negocio.estaVerificado { return false }
            if filtro.disponibleHoy, !negocio.disponibleHoy { return false }
            if filtro.abiertoAhora, !negocio.estaAbierto(en: fecha) { return false }
            if let minima = filtro.calificacionMinima, negocio.calificacion < minima { return false }
            return true
        }
    }

    func crear(_ negocio: Negocio, propietario: Usuario?) throws {
        contexto.insert(negocio)
        negocio.propietario = propietario
        try contexto.save()
    }

    func agregar(_ servicio: Servicio, a negocio: Negocio) throws {
        contexto.insert(servicio)
        servicio.negocio = negocio
        try contexto.save()
    }

    func actualizarVerificacion(de negocio: Negocio, a estado: EstadoVerificacion, cedula: String?) throws {
        negocio.estadoVerificacion = estado
        if let cedula { negocio.cedula = cedula }
        try contexto.save()
    }

    func guardar() throws {
        try contexto.save()
    }
}
