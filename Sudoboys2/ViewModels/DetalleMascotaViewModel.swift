import CoreGraphics
import Foundation
import Observation

/// Tarjeta completa de una mascota: datos, QR y cartilla de vacunación.
@Observable
final class DetalleMascotaViewModel {
    let mascota: Mascota
    /// De la más reciente a la más antigua.
    private(set) var vacunas: [Vacuna] = []
    private(set) var imagenQR: CGImage?
    /// Sube cada vez que se guarda algo en la cartilla (para la respuesta háptica).
    private(set) var guardados = 0
    var mensajeError: String?

    @ObservationIgnored private let repositorio: any MascotaRepository
    @ObservationIgnored private let servicios: ServiciosMascotas

    init(mascota: Mascota, repositorio: any MascotaRepository, servicios: ServiciosMascotas = ServiciosMascotas()) {
        self.mascota = mascota
        self.repositorio = repositorio
        self.servicios = servicios
    }

    /// El QR lleva el id de la mascota: es lo que escanea el negocio al hacer check-in.
    var contenidoQR: String { mascota.id.uuidString }

    var proximaVacuna: Vacuna? { mascota.proximaVacuna() }

    func cargar() {
        vacunas = mascota.vacunas.sorted { $0.fechaAplicacion > $1.fechaAplicacion }
        if imagenQR == nil {
            imagenQR = servicios.qr.imagenQR(para: contenidoQR)
        }
    }

    /// Alta manual: siempre queda registrada por el tutor.
    func agregarVacuna(nombre: String, fechaAplicacion: Date, proximaDosis: Date?) {
        let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return }
        do {
            let vacuna = Vacuna(nombre: limpio, fechaAplicacion: fechaAplicacion, proximaDosis: proximaDosis, registradaPor: .tutor)
            try repositorio.agregar(vacuna, a: mascota)
            cargar()
            guardados += 1
        } catch {
            mensajeError = "No pudimos guardar la vacuna. Inténtalo de nuevo."
        }
    }

    func eliminar(_ vacuna: Vacuna) {
        // Se quita de la lista antes de borrar para no dibujar un modelo eliminado.
        vacunas.removeAll { $0.id == vacuna.id }
        do {
            try repositorio.eliminar(vacuna)
        } catch {
            mensajeError = "No pudimos eliminar la vacuna."
            cargar()
        }
    }

    func nuevoEscaneo() -> EscaneoCartillaViewModel {
        EscaneoCartillaViewModel(
            mascota: mascota,
            repositorio: repositorio,
            escaner: servicios.escaner,
            extractor: servicios.extractor
        ) { [weak self] in
            self?.cargar()
            self?.guardados += 1
        }
    }

    func formularioEdicion() -> FormularioMascotaViewModel {
        FormularioMascotaViewModel(mascota: mascota, tutor: mascota.tutor, repositorio: repositorio) {}
    }
}
