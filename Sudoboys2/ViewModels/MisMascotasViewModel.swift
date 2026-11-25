import Foundation
import Observation

/// Servicios que usan las pantallas de mascotas y cartilla.
struct ServiciosMascotas {
    var qr: any GeneradorQRService = GeneradorQRCoreImage()
    var escaner: any EscanerTextoService = EscanerTextoVision()
    var extractor: any ExtractorIAService = ExtractorIAFoundationModels()
}

/// Mis mascotas: la lista de tarjetas del tutor.
@Observable
final class MisMascotasViewModel {
    private(set) var mascotas: [Mascota] = []
    var mensajeError: String?

    @ObservationIgnored private let appState: AppState
    @ObservationIgnored private let repositorio: any MascotaRepository
    @ObservationIgnored private let servicios: ServiciosMascotas
    /// Un detalle por mascota, para que su estado sobreviva a los redibujos de la navegación.
    @ObservationIgnored private var detalles: [UUID: DetalleMascotaViewModel] = [:]

    init(appState: AppState, repositorio: any MascotaRepository, servicios: ServiciosMascotas = ServiciosMascotas()) {
        self.appState = appState
        self.repositorio = repositorio
        self.servicios = servicios
    }

    func cargar() {
        guard let tutor = appState.usuarioActual else {
            mascotas = []
            return
        }
        do {
            mascotas = try repositorio.mascotas(de: tutor)
        } catch {
            mensajeError = "No pudimos cargar tus mascotas."
        }
    }

    func detalle(para id: UUID) -> DetalleMascotaViewModel? {
        if let existente = detalles[id] { return existente }
        guard let mascota = mascotas.first(where: { $0.id == id }) else { return nil }
        let detalle = DetalleMascotaViewModel(mascota: mascota, repositorio: repositorio, servicios: servicios)
        detalles[id] = detalle
        return detalle
    }

    func formularioNuevaMascota() -> FormularioMascotaViewModel {
        FormularioMascotaViewModel(mascota: nil, tutor: appState.usuarioActual, repositorio: repositorio) { [weak self] in
            self?.cargar()
        }
    }
}
