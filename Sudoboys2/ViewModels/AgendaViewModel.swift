import Foundation
import Observation
import UIKit

/// Modo negocio: agenda del día, check-in y avance de etapas.
@Observable
final class AgendaViewModel {
    let negocio: Negocio
    private(set) var citas: [Cita] = []
    var mensajeError: String?
    /// Cuenta check-ins y avances, para el haptic.
    private(set) var avances = 0

    @ObservationIgnored private let repositorio: any CitaRepository
    @ObservationIgnored private let servicios: ServiciosCitas
    @ObservationIgnored private let reloj: () -> Date

    init(
        negocio: Negocio,
        citas: any CitaRepository,
        servicios: ServiciosCitas = ServiciosCitas(),
        reloj: @escaping () -> Date = { .now }
    ) {
        self.negocio = negocio
        self.repositorio = citas
        self.servicios = servicios
        self.reloj = reloj
    }

    func cargar() {
        do {
            citas = try repositorio.agenda(de: negocio, dia: reloj()).filter { $0.estado != .cancelada }
        } catch {
            mensajeError = "No pudimos cargar la agenda."
        }
    }

    func cita(id: UUID) -> Cita? { citas.first { $0.id == id } }

    /// Citas de hoy que aún se pueden atender: la alternativa al QR.
    var pendientes: [Cita] {
        citas.filter { $0.estado == .programada || $0.estado == .enCurso }
    }

    var resumen: String {
        let enCurso = citas.filter { $0.estado == .enCurso }.count
        let porLlegar = citas.filter { $0.estado == .programada }.count
        let listas = citas.filter { $0.estado == .terminada }.count
        return "\(porLlegar) por llegar · \(enCurso) en curso · \(listas) listas"
    }

    enum ResultadoQR: Equatable {
        case cita(UUID)
        case error(String)
    }

    /// Busca la cita pendiente de hoy de la mascota cuyo QR se escaneó.
    func identificar(codigo: String) -> ResultadoQR {
        cargar()
        let texto = codigo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let idMascota = UUID(uuidString: texto) else {
            return .error("Ese código no es de una mascota registrada.")
        }
        guard let cita = pendientes.first(where: { $0.mascota?.id == idMascota }) else {
            return .error("Esta mascota no tiene cita pendiente hoy.")
        }
        return .cita(cita.id)
    }

    /// Reduce la foto final antes de guardarla.
    func prepararFoto(_ datos: Data) -> Data? {
        UIImage(data: datos)?.reducida(ladoMaximo: 1400).jpegData(compressionQuality: 0.8)
    }

    func registrarLlegada(_ cita: Cita) {
        do {
            try repositorio.registrarLlegada(cita)
            avances += 1
            let liveActivity = servicios.liveActivity
            let notificaciones = servicios.notificaciones
            Task {
                await notificaciones.pedirPermiso()
                await liveActivity.iniciar(para: cita)
            }
        } catch {
            mensajeError = "No pudimos registrar la llegada."
        }
    }

    /// Verdadero si el siguiente paso cierra la cita (se ofrece la foto final).
    func siguienteEsListo(_ cita: Cita) -> Bool { cita.siguienteEtapa == .listo }

    func avanzar(_ cita: Cita, fotoFinal: Data? = nil) {
        do {
            let etapa = try repositorio.avanzarEtapa(cita, fotoFinal: fotoFinal)
            avances += 1
            let liveActivity = servicios.liveActivity
            let notificaciones = servicios.notificaciones
            let mascota = cita.nombreMascota
            let nombreNegocio = negocio.nombre
            Task {
                await liveActivity.actualizar(para: cita)
                if etapa == .listo {
                    await notificaciones.avisarListoParaRecoger(mascota: mascota, negocio: nombreNegocio)
                }
            }
        } catch {
            mensajeError = "No pudimos avanzar la etapa."
        }
    }
}
