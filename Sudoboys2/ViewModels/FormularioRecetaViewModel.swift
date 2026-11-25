import Foundation
import Observation

/// Emisión de una receta desde una cita. Solo veterinarias con cédula verificada.
@Observable
final class FormularioRecetaViewModel: Identifiable {
    struct BorradorMedicamento: Identifiable, Equatable {
        let id = UUID()
        var nombre = ""
        var dosis = ""
        var cadaHoras = 8
        var dias = 5
        var grupo: GrupoMedicamento = .ventaLibre

        var estaVacio: Bool {
            nombre.trimmingCharacters(in: .whitespaces).isEmpty && dosis.trimmingCharacters(in: .whitespaces).isEmpty
        }

        var estaCompleto: Bool {
            !nombre.trimmingCharacters(in: .whitespaces).isEmpty && !dosis.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    static let frecuencias = [4, 6, 8, 12, 24, 48]

    let cita: Cita
    var nombreVeterinario: String
    var diagnostico = ""
    var indicaciones = ""
    var medicamentos: [BorradorMedicamento] = [BorradorMedicamento()]
    var mensajeError: String?
    private(set) var emitida = false

    @ObservationIgnored private let recetas: any RecetaRepository
    @ObservationIgnored private let notificaciones: any NotificacionesService
    @ObservationIgnored private let alEmitir: (Receta) -> Void

    init(
        cita: Cita,
        recetas: any RecetaRepository,
        notificaciones: any NotificacionesService = NotificacionesSinEfecto(),
        alEmitir: @escaping (Receta) -> Void = { _ in }
    ) {
        self.cita = cita
        self.recetas = recetas
        self.notificaciones = notificaciones
        self.alEmitir = alEmitir
        // El nombre de la cédula; si falta, el de la última receta del negocio.
        let negocio = cita.negocio
        nombreVeterinario = negocio?.nombreVeterinario
            ?? negocio?.recetas.max { $0.fecha < $1.fecha }?.nombreVeterinario
            ?? ""
    }

    var cedula: String { cita.negocio?.cedula ?? "" }
    var domicilio: String { cita.negocio?.direccion ?? "" }

    private var completos: [BorradorMedicamento] { medicamentos.filter(\.estaCompleto) }

    /// Verdadero si algún medicamento es de grupo I o II (NOM-064-ZOO-2000).
    var requiereRecetaFisica: Bool {
        medicamentos.contains { !$0.estaVacio && $0.grupo.requiereRecetaFisica }
    }

    /// Lo que falta para emitir; `nil` si ya está todo.
    var pendiente: String? {
        if nombreVeterinario.trimmingCharacters(in: .whitespaces).isEmpty { return "Escribe el nombre de quien receta" }
        if diagnostico.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Escribe el diagnóstico" }
        if completos.isEmpty { return "Agrega al menos un medicamento con su dosis" }
        if medicamentos.contains(where: { !$0.estaVacio && !$0.estaCompleto }) { return "Completa nombre y dosis de cada medicamento" }
        return nil
    }

    var puedeEmitir: Bool { pendiente == nil && !emitida }

    /// Verdadero si ya se capturó algo que se perdería al cerrar.
    var tieneCambios: Bool {
        !emitida && (!diagnostico.isEmpty || !indicaciones.isEmpty || medicamentos.contains { !$0.estaVacio })
    }

    func agregarMedicamento() {
        medicamentos.append(BorradorMedicamento())
    }

    func quitar(_ medicamento: BorradorMedicamento) {
        medicamentos.removeAll { $0.id == medicamento.id }
        if medicamentos.isEmpty { medicamentos = [BorradorMedicamento()] }
    }

    func emitir() {
        guard puedeEmitir else { return }
        let datos = DatosReceta(
            nombreVeterinario: nombreVeterinario.trimmingCharacters(in: .whitespaces),
            cedulaVeterinario: cedula,
            domicilioVeterinario: domicilio,
            diagnostico: diagnostico.trimmingCharacters(in: .whitespacesAndNewlines),
            indicaciones: indicaciones.trimmingCharacters(in: .whitespacesAndNewlines),
            medicamentos: completos.map {
                DatosMedicamento(
                    nombre: $0.nombre.trimmingCharacters(in: .whitespaces),
                    dosis: $0.dosis.trimmingCharacters(in: .whitespaces),
                    cadaHoras: $0.cadaHoras,
                    dias: $0.dias,
                    grupo: $0.grupo
                )
            }
        )
        do {
            let receta = try recetas.emitir(datos, para: cita)
            emitida = true
            alEmitir(receta)
            let notificaciones = notificaciones
            Task { await notificaciones.programarRecordatorios(de: receta) }
        } catch ErrorRepositorio.negocioNoAutorizadoParaRecetas {
            mensajeError = "Solo una veterinaria con cédula verificada puede emitir recetas."
        } catch ErrorRepositorio.citaYaTieneReceta {
            mensajeError = "Esta cita ya tiene una receta."
        } catch {
            mensajeError = "No pudimos emitir la receta. Inténtalo de nuevo."
        }
    }
}
