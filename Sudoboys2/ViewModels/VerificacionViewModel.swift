import Foundation
import Observation
import UIKit

/// Verificación del negocio: foto de la cédula, lectura por OCR, revisión y aprobación simulada.
@Observable
final class VerificacionViewModel {
    let negocio: Negocio

    // Borrador de la carga de cédula.
    private(set) var foto: Data?
    var nombre = ""
    var cedula = ""
    private(set) var leyendo = false
    /// Qué encontró el OCR, para explicarlo en pantalla.
    private(set) var resultadoLectura: String?
    var mensajeError: String?
    /// Sube al enviar a revisión y al aprobar, para el haptic.
    private(set) var cambios = 0

    @ObservationIgnored private let negocios: any NegocioRepository
    @ObservationIgnored private let escaner: any EscanerTextoService
    @ObservationIgnored private let extractor = ExtractorCedula()

    init(negocio: Negocio, negocios: any NegocioRepository, escaner: any EscanerTextoService = EscanerTextoVision()) {
        self.negocio = negocio
        self.negocios = negocios
        self.escaner = escaner
    }

    var requiereCedula: Bool { negocio.tipo.ofrece(.veterinaria) }
    var estado: EstadoVerificacion { negocio.estadoVerificacion }

    /// La aprobación simulada: una veterinaria primero debe enviar su cédula.
    var puedeAprobar: Bool {
        switch estado {
        case .verificado: false
        case .enRevision: true
        case .pendiente: !requiereCedula
        }
    }

    func prepararCarga() {
        foto = nil
        nombre = negocio.nombreVeterinario ?? ""
        cedula = negocio.cedula ?? ""
        resultadoLectura = nil
    }

    private var cedulaLimpia: String { cedula.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// La cédula profesional tiene 7 u 8 dígitos.
    var cedulaValida: Bool {
        (7...8).contains(cedulaLimpia.count) && cedulaLimpia.allSatisfy(\.isNumber)
    }

    var pendiente: String? {
        if foto == nil { return "Agrega la foto de tu cédula" }
        if leyendo { return "Leyendo la cédula…" }
        if nombreLimpio.isEmpty { return "Escribe el nombre como aparece en la cédula" }
        if !cedulaValida { return "El número de cédula tiene 7 u 8 dígitos" }
        return nil
    }

    var puedeEnviar: Bool { pendiente == nil }

    /// Guarda la foto y lee nombre y número con OCR. Lo que no se lea se captura a mano.
    func usarFoto(_ datos: Data) async {
        guard let imagen = UIImage(data: datos) else {
            mensajeError = "No pudimos abrir esa foto."
            return
        }
        let reducida = imagen.reducida(ladoMaximo: 2000)
        foto = reducida.jpegData(compressionQuality: 0.8)
        guard let cgImage = reducida.cgImage else { return }
        leyendo = true
        defer { leyendo = false }
        do {
            let texto = try await escaner.texto(en: [cgImage])
            let datos = extractor.extraer(de: texto)
            if let numero = datos.numero { cedula = numero }
            if let leido = datos.nombre { nombre = leido }
            switch (datos.nombre, datos.numero) {
            case (.some, .some): resultadoLectura = "Leímos el nombre y el número. Revísalos antes de enviar."
            case (nil, nil): resultadoLectura = "No pudimos leer la cédula. Escribe los datos a mano."
            default: resultadoLectura = "Leímos solo una parte. Completa lo que falta."
            }
        } catch {
            resultadoLectura = "No pudimos leer la cédula. Escribe los datos a mano."
        }
    }

    func enviarARevision() -> Bool {
        guard puedeEnviar else { return false }
        do {
            negocio.fotoCedula = foto
            negocio.nombreVeterinario = nombreLimpio
            try negocios.actualizarVerificacion(de: negocio, a: .enRevision, cedula: cedulaLimpia)
            cambios += 1
            return true
        } catch {
            mensajeError = "No pudimos enviar tu cédula. Inténtalo de nuevo."
            return false
        }
    }

    /// Simula al administrador que revisa la cédula (no hay backend).
    func aprobarComoAdministrador() {
        guard puedeAprobar else { return }
        do {
            try negocios.actualizarVerificacion(de: negocio, a: .verificado, cedula: nil)
            cambios += 1
        } catch {
            mensajeError = "No pudimos aprobar la verificación."
        }
    }
}
