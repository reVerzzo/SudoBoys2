import CoreGraphics
import Foundation
import Observation

/// Escaneo de cartilla: lee el texto, extrae vacunas y las deja listas para que el tutor confirme.
@Observable
final class EscaneoCartillaViewModel: Identifiable {
    enum Estado: Equatable {
        case inicio
        case procesando
        /// El tutor revisa y corrige antes de guardar.
        case revision
        case sinResultados
        case error
    }

    /// Vacuna detectada que el tutor puede corregir o descartar.
    struct Borrador: Identifiable {
        let id = UUID()
        var incluir = true
        var nombre: String
        var fechaAplicacion: Date
        /// El lector no encontró la fecha: se propone hoy y se pide revisarla.
        var fechaPorRevisar: Bool
        var tieneProximaDosis: Bool
        var proximaDosis: Date
    }

    private(set) var estado: Estado = .inicio
    private(set) var metodo: MetodoExtraccion = .respaldo
    var borradores: [Borrador] = []
    var mensajeError: String?

    let nombreMascota: String

    @ObservationIgnored private let mascota: Mascota
    @ObservationIgnored private let repositorio: any MascotaRepository
    @ObservationIgnored private let escaner: any EscanerTextoService
    @ObservationIgnored private let extractor: any ExtractorIAService
    @ObservationIgnored private let alGuardar: () -> Void

    init(
        mascota: Mascota,
        repositorio: any MascotaRepository,
        escaner: any EscanerTextoService,
        extractor: any ExtractorIAService,
        alGuardar: @escaping () -> Void
    ) {
        self.mascota = mascota
        self.nombreMascota = mascota.nombre
        self.repositorio = repositorio
        self.escaner = escaner
        self.extractor = extractor
        self.alGuardar = alGuardar
    }

    private var porGuardar: [Borrador] {
        borradores.filter { $0.incluir && !$0.nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var cantidadPorGuardar: Int { porGuardar.count }

    var textoMetodo: String {
        switch metodo {
        case .appleIntelligence: "Leído con Apple Intelligence en tu iPhone"
        case .respaldo: "Leído con reconocimiento de texto en tu iPhone"
        }
    }

    func procesar(imagenes: [CGImage]) async {
        guard !imagenes.isEmpty else { return }
        estado = .procesando
        do {
            let texto = try await escaner.texto(en: imagenes)
            let resultado = await extractor.extraer(de: texto)
            let hoy = Date.now
            metodo = resultado.metodo
            borradores = resultado.vacunas.map { vacuna in
                Borrador(
                    nombre: vacuna.nombre,
                    // Una vacuna no se aplica en el futuro: si la fecha leída lo es, se pide revisarla.
                    fechaAplicacion: min(vacuna.fechaAplicacion ?? hoy, hoy),
                    fechaPorRevisar: vacuna.fechaAplicacion == nil || (vacuna.fechaAplicacion ?? hoy) > hoy,
                    tieneProximaDosis: vacuna.proximaDosis != nil,
                    proximaDosis: vacuna.proximaDosis
                        ?? Calendar.current.date(byAdding: .year, value: 1, to: vacuna.fechaAplicacion ?? hoy) ?? hoy
                )
            }
            estado = borradores.isEmpty ? .sinResultados : .revision
        } catch {
            estado = .error
        }
    }

    /// Pasa a revisión con los borradores ya cargados (vistas previas).
    func mostrarRevision() {
        estado = borradores.isEmpty ? .sinResultados : .revision
    }

    func reintentar() {
        borradores = []
        estado = .inicio
    }

    /// Guarda solo lo que el tutor dejó marcado. Devuelve `true` si se guardó.
    func guardar() -> Bool {
        let seleccion = porGuardar
        guard !seleccion.isEmpty else { return false }
        do {
            for borrador in seleccion {
                let vacuna = Vacuna(
                    nombre: borrador.nombre.trimmingCharacters(in: .whitespacesAndNewlines),
                    fechaAplicacion: borrador.fechaAplicacion,
                    proximaDosis: borrador.tieneProximaDosis ? borrador.proximaDosis : nil,
                    registradaPor: .tutor
                )
                try repositorio.agregar(vacuna, a: mascota)
            }
            alGuardar()
            return true
        } catch {
            mensajeError = "No pudimos guardar las vacunas. Inténtalo de nuevo."
            return false
        }
    }
}
