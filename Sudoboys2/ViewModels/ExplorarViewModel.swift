import Foundation
import Observation

/// Un negocio con su distancia al punto de referencia.
struct ResultadoNegocio: Identifiable {
    let negocio: Negocio
    let distanciaKm: Double
    var id: UUID { negocio.id }
}

/// Explorar: negocios filtrados en memoria, para el mapa y la lista.
@Observable
final class ExplorarViewModel {
    enum Modo: Hashable {
        case mapa
        case lista
    }

    /// Opción de servicio en la hoja de filtros.
    enum OpcionServicio: Hashable, CaseIterable {
        case todos
        case estetica
        case veterinaria
        case ambos

        var titulo: String {
            switch self {
            case .todos: "Todos"
            case .estetica: "Estética"
            case .veterinaria: "Veterinaria"
            case .ambos: "Ambos"
            }
        }

        var icono: String? {
            switch self {
            case .todos: nil
            case .estetica: TipoNegocio.estetica.icono
            case .veterinaria: TipoNegocio.veterinaria.icono
            case .ambos: TipoNegocio.ambos.icono
            }
        }
    }

    static let calificacionesMinimas: [Double] = [4.0, 4.5]
    static let distanciasMaximasKm: [Double] = [2, 5, 10]

    /// Las distancias se miden desde Ciudad Universitaria (sede del hackathon):
    /// así la demo no depende del permiso ni de la ubicación del dispositivo.
    static let referencia = PuntoGeografico(latitud: 19.3245, longitud: -99.1846)
    static let nombreReferencia = "Ciudad Universitaria"

    var modo: Modo = .mapa
    var mostrandoFiltros = false
    var idSeleccionado: UUID?
    var mensajeError: String?

    var filtro = FiltroNegocios() {
        didSet { if filtro != oldValue { recalcular() } }
    }

    var distanciaMaximaKm: Double? {
        didSet { if distanciaMaximaKm != oldValue { recalcular() } }
    }

    /// Negocios que cumplen los filtros, del más cercano al más lejano.
    private(set) var resultados: [ResultadoNegocio] = []
    /// Momento con el que se evaluó "abierto ahora".
    private(set) var ahora: Date

    @ObservationIgnored private let negocios: any NegocioRepository
    @ObservationIgnored private let reloj: () -> Date
    @ObservationIgnored private var perfiles: [UUID: PerfilNegocioViewModel] = [:]

    init(negocios: any NegocioRepository, reloj: @escaping () -> Date = { .now }) {
        self.negocios = negocios
        self.reloj = reloj
        self.ahora = reloj()
    }

    // MARK: - Filtros

    var servicio: OpcionServicio {
        get {
            if filtro.soloAmbos { return .ambos }
            switch filtro.servicio {
            case .estetica: return .estetica
            case .veterinaria: return .veterinaria
            case nil: return .todos
            }
        }
        set {
            var nuevo = filtro
            nuevo.soloAmbos = newValue == .ambos
            switch newValue {
            case .estetica: nuevo.servicio = .estetica
            case .veterinaria: nuevo.servicio = .veterinaria
            case .todos, .ambos: nuevo.servicio = nil
            }
            filtro = nuevo
        }
    }

    /// Cuántos filtros están puestos, para la insignia del botón.
    var filtrosActivos: Int {
        var cuenta = 0
        if servicio != .todos { cuenta += 1 }
        if filtro.especie != nil { cuenta += 1 }
        if filtro.soloVerificados { cuenta += 1 }
        if filtro.disponibleHoy { cuenta += 1 }
        if filtro.abiertoAhora { cuenta += 1 }
        if filtro.calificacionMinima != nil { cuenta += 1 }
        if distanciaMaximaKm != nil { cuenta += 1 }
        return cuenta
    }

    func alternar(_ especie: Especie) {
        filtro.especie = filtro.especie == especie ? nil : especie
    }

    func alternarCalificacion(_ minima: Double) {
        filtro.calificacionMinima = filtro.calificacionMinima == minima ? nil : minima
    }

    func alternarDistancia(_ maxima: Double) {
        distanciaMaximaKm = distanciaMaximaKm == maxima ? nil : maxima
    }

    func limpiarFiltros() {
        distanciaMaximaKm = nil
        filtro = FiltroNegocios()
    }

    // MARK: - Resultados

    var seleccionado: ResultadoNegocio? {
        guard let idSeleccionado else { return nil }
        return resultados.first { $0.id == idSeleccionado }
    }

    func cargar() {
        recalcular()
    }

    /// ViewModel del perfil; se conserva para que la navegación no lo recree.
    func perfil(para id: UUID) -> PerfilNegocioViewModel? {
        if let existente = perfiles[id] { return existente }
        guard let negocio = try? negocios.negocio(id: id) else { return nil }
        let perfil = PerfilNegocioViewModel(
            negocio: negocio,
            distanciaKm: Self.referencia.distanciaKm(a: negocio.punto),
            reloj: reloj
        )
        perfiles[id] = perfil
        return perfil
    }

    private func recalcular() {
        ahora = reloj()
        do {
            let filtrados = try negocios.buscar(filtro, fecha: ahora)
            resultados = filtrados
                .map { ResultadoNegocio(negocio: $0, distanciaKm: Self.referencia.distanciaKm(a: $0.punto)) }
                .filter { resultado in
                    guard let maxima = distanciaMaximaKm else { return true }
                    return resultado.distanciaKm <= maxima
                }
                .sorted { $0.distanciaKm < $1.distanciaKm }
            mensajeError = nil
        } catch {
            resultados = []
            mensajeError = "No pudimos cargar los negocios."
        }
        if let idSeleccionado, !resultados.contains(where: { $0.id == idSeleccionado }) {
            self.idSeleccionado = nil
        }
    }
}
