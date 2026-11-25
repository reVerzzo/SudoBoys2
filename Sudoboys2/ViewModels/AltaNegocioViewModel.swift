import Foundation
import Observation
import UIKit

/// Alta de negocio: tipo, especies, ubicación y cédula si es veterinaria.
@Observable
final class AltaNegocioViewModel {
    var nombre = ""
    var tipo: TipoNegocio = .estetica
    var especies: Set<Especie> = [.perro]
    var direccion = ""
    /// Centro de Coyoacán como punto de partida del mapa.
    var latitud = 19.3497
    var longitud = -99.1618
    var cedula = ""
    var fotoCedula: Data?
    /// Nombre del titular, leído de la foto de la cédula.
    private(set) var nombreVeterinario: String?
    private(set) var leyendoCedula = false
    var mensajeError: String?
    private(set) var guardando = false

    /// Cuenta que ya inició sesión (por Google) y aún no tiene negocio; `nil` crea una cuenta local.
    @ObservationIgnored private let propietario: Usuario?
    @ObservationIgnored private let appState: AppState
    @ObservationIgnored private let repositorios: Repositorios
    @ObservationIgnored private let escaner: any EscanerTextoService = EscanerTextoVision()

    init(appState: AppState, repositorios: Repositorios, propietario: Usuario? = nil) {
        self.appState = appState
        self.repositorios = repositorios
        self.propietario = propietario
    }

    /// Veterinaria y "ambos" necesitan cédula profesional.
    var requiereCedula: Bool { tipo.ofrece(.veterinaria) }

    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var direccionLimpia: String { direccion.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var cedulaLimpia: String { cedula.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// La cédula profesional tiene 7 u 8 dígitos.
    var cedulaValida: Bool {
        (7...8).contains(cedulaLimpia.count) && cedulaLimpia.allSatisfy(\.isNumber)
    }

    /// Lo que falta para poder guardar, en el orden del formulario.
    var faltantes: [String] {
        var lista: [String] = []
        if nombreLimpio.isEmpty { lista.append("el nombre del negocio") }
        if especies.isEmpty { lista.append("al menos una especie") }
        if direccionLimpia.isEmpty { lista.append("la dirección") }
        if requiereCedula {
            if !cedulaValida { lista.append("el número de cédula (7 u 8 dígitos)") }
            if fotoCedula == nil { lista.append("la foto de la cédula") }
        }
        return lista
    }

    var puedeGuardar: Bool { faltantes.isEmpty && !guardando }

    var ayuda: String? {
        guard !faltantes.isEmpty else { return nil }
        return "Falta " + faltantes.listaEnEspanol + "."
    }

    /// Lee nombre y número de la foto de la cédula; el número solo se llena si aún está vacío.
    func leerCedula() async {
        guard let fotoCedula, let imagen = UIImage(data: fotoCedula)?.reducida(ladoMaximo: 2000).cgImage else { return }
        leyendoCedula = true
        defer { leyendoCedula = false }
        guard let texto = try? await escaner.texto(en: [imagen]) else { return }
        let datos = ExtractorCedula().extraer(de: texto)
        nombreVeterinario = datos.nombre
        if cedulaLimpia.isEmpty, let numero = datos.numero { cedula = numero }
    }

    func alternar(_ especie: Especie) {
        if especies.contains(especie) {
            especies.remove(especie)
        } else {
            especies.insert(especie)
        }
    }

    func guardar() {
        guard puedeGuardar else { return }
        guardando = true
        defer { guardando = false }
        do {
            let usuario: Usuario
            if let propietario {
                usuario = propietario
            } else {
                usuario = Usuario(nombre: nombreLimpio, correo: "", proveedor: .demo, rol: .negocio)
                try repositorios.usuarios.crear(usuario)
            }
            let negocio = Negocio(
                nombre: nombreLimpio,
                tipo: tipo,
                especiesAtendidas: Especie.allCases.filter(especies.contains),
                latitud: latitud,
                longitud: longitud,
                direccion: direccionLimpia,
                // La cédula queda en revisión hasta que un administrador la apruebe.
                estadoVerificacion: requiereCedula ? .enRevision : .pendiente,
                cedula: requiereCedula ? cedulaLimpia : nil
            )
            negocio.fotoCedula = requiereCedula ? fotoCedula : nil
            negocio.nombreVeterinario = requiereCedula ? nombreVeterinario : nil
            try repositorios.negocios.crear(negocio, propietario: usuario)
            appState.iniciarSesion(usuario)
        } catch {
            mensajeError = "No pudimos guardar tu negocio. Inténtalo de nuevo."
        }
    }
}
