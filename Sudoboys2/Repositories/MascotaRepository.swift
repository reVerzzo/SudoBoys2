import Foundation
import SwiftData

protocol MascotaRepository {
    /// Mascotas del tutor, por nombre.
    func mascotas(de tutor: Usuario) throws -> [Mascota]
    /// Búsqueda por id; es lo que contiene el QR de la mascota.
    func mascota(id: UUID) throws -> Mascota?
    func agregar(_ mascota: Mascota, a tutor: Usuario) throws
    func agregar(_ vacuna: Vacuna, a mascota: Mascota) throws
    func eliminar(_ vacuna: Vacuna) throws
    func eliminar(_ mascota: Mascota) throws
    func guardar() throws
}

final class MascotaRepositorySwiftData: MascotaRepository {
    private let contexto: ModelContext

    init(contexto: ModelContext) {
        self.contexto = contexto
    }

    func mascotas(de tutor: Usuario) throws -> [Mascota] {
        tutor.mascotas.sorted { $0.nombre.localizedCompare($1.nombre) == .orderedAscending }
    }

    func mascota(id: UUID) throws -> Mascota? {
        var consulta = FetchDescriptor<Mascota>(predicate: #Predicate { $0.id == id })
        consulta.fetchLimit = 1
        return try contexto.fetch(consulta).first
    }

    func agregar(_ mascota: Mascota, a tutor: Usuario) throws {
        contexto.insert(mascota)
        mascota.tutor = tutor
        try contexto.save()
    }

    func agregar(_ vacuna: Vacuna, a mascota: Mascota) throws {
        contexto.insert(vacuna)
        vacuna.mascota = mascota
        try contexto.save()
    }

    func eliminar(_ vacuna: Vacuna) throws {
        contexto.delete(vacuna)
        try contexto.save()
    }

    func eliminar(_ mascota: Mascota) throws {
        contexto.delete(mascota)
        try contexto.save()
    }

    func guardar() throws {
        try contexto.save()
    }
}
