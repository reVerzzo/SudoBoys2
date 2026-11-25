import Foundation
import SwiftData

/// Lo que captura el veterinario al emitir una receta.
nonisolated struct DatosReceta: Equatable, Sendable {
    var nombreVeterinario: String
    var cedulaVeterinario: String
    var domicilioVeterinario: String
    var diagnostico: String
    var indicaciones: String
    var medicamentos: [DatosMedicamento]
}

nonisolated struct DatosMedicamento: Equatable, Sendable {
    var nombre: String
    var dosis: String
    var cadaHoras: Int
    var dias: Int
    var grupo: GrupoMedicamento
}

protocol RecetaRepository {
    /// Historial de recetas de la mascota, de la más reciente a la más antigua.
    func recetas(de mascota: Mascota) throws -> [Receta]
    func receta(id: UUID) throws -> Receta?
    /// Emite la receta desde una cita. Solo veterinarias con cédula verificada.
    func emitir(_ datos: DatosReceta, para cita: Cita) throws -> Receta
}

final class RecetaRepositorySwiftData: RecetaRepository {
    private let contexto: ModelContext

    init(contexto: ModelContext) {
        self.contexto = contexto
    }

    func recetas(de mascota: Mascota) throws -> [Receta] {
        mascota.recetas.sorted { $0.fecha > $1.fecha }
    }

    func receta(id: UUID) throws -> Receta? {
        var consulta = FetchDescriptor<Receta>(predicate: #Predicate { $0.id == id })
        consulta.fetchLimit = 1
        return try contexto.fetch(consulta).first
    }

    func emitir(_ datos: DatosReceta, para cita: Cita) throws -> Receta {
        guard let negocio = cita.negocio, negocio.puedeEmitirRecetas else {
            throw ErrorRepositorio.negocioNoAutorizadoParaRecetas
        }
        guard cita.receta == nil else { throw ErrorRepositorio.citaYaTieneReceta }

        let receta = Receta(
            nombreVeterinario: datos.nombreVeterinario,
            cedulaVeterinario: datos.cedulaVeterinario,
            domicilioVeterinario: datos.domicilioVeterinario,
            diagnostico: datos.diagnostico,
            indicaciones: datos.indicaciones
        )
        contexto.insert(receta)
        receta.cita = cita
        receta.negocio = negocio
        receta.mascota = cita.mascota
        for dato in datos.medicamentos {
            let medicamento = Medicamento(
                nombre: dato.nombre,
                dosis: dato.dosis,
                cadaHoras: dato.cadaHoras,
                dias: dato.dias,
                grupo: dato.grupo
            )
            contexto.insert(medicamento)
            medicamento.receta = receta
        }
        try contexto.save()
        return receta
    }
}
