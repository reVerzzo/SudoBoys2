import Foundation
import Observation

/// Urgencia: sin horario. El tutor elige una veterinaria abierta ahora y avisa que va en camino.
@Observable
final class UrgenciaViewModel: Identifiable {
    /// Una veterinaria abierta ahora, con su tiempo de llegada.
    struct Opcion: Identifiable {
        let negocio: Negocio
        let distanciaKm: Double
        /// Minutos de camino.
        var minutos: Int
        /// `true` mientras es una aproximación por distancia; `false` cuando ya es la ruta de MapKit.
        var aproximado = true
        var id: UUID { negocio.id }
    }

    private(set) var mascotas: [Mascota] = []
    /// `nil` = sin perfil: se elige la especie.
    var idMascota: UUID? {
        didSet { if idMascota != oldValue { cargar(elegirMasCercana: true) } }
    }
    var especieSinPerfil: Especie = .perro {
        didSet { if especieSinPerfil != oldValue { cargar(elegirMasCercana: true) } }
    }
    var motivo = ""
    var telefono = ""

    private(set) var opciones: [Opcion] = []
    var idNegocio: UUID?
    private(set) var citaConfirmada: Cita?
    var mensajeError: String?

    @ObservationIgnored private let tutor: Usuario?
    @ObservationIgnored private let origen: PuntoGeografico
    @ObservationIgnored private let negocios: any NegocioRepository
    @ObservationIgnored private let citas: any CitaRepository
    @ObservationIgnored private let servicios: ServiciosCitas
    @ObservationIgnored private let reloj: () -> Date

    init(
        tutor: Usuario?,
        origen: PuntoGeografico,
        negocios: any NegocioRepository,
        citas: any CitaRepository,
        mascotas: any MascotaRepository,
        servicios: ServiciosCitas = ServiciosCitas(),
        reloj: @escaping () -> Date = { .now }
    ) {
        self.tutor = tutor
        self.origen = origen
        self.negocios = negocios
        self.citas = citas
        self.servicios = servicios
        self.reloj = reloj
        if let tutor {
            self.mascotas = (try? mascotas.mascotas(de: tutor)) ?? []
        }
        cargar()
    }

    var mascota: Mascota? { mascotas.first { $0.id == idMascota } }
    var especie: Especie { mascota?.especie ?? especieSinPerfil }
    var seleccionada: Opcion? { opciones.first { $0.id == idNegocio } }

    /// Veterinarias abiertas ahora que atienden a la especie, de la más cercana a la más lejana.
    /// Al cambiar de paciente cambia la lista, así que se vuelve a proponer la más cercana.
    func cargar(elegirMasCercana: Bool = false) {
        var filtro = FiltroNegocios()
        filtro.servicio = .veterinaria
        filtro.especie = especie
        filtro.abiertoAhora = true
        do {
            let origen = origen
            let anteriores = Dictionary(uniqueKeysWithValues: opciones.map { ($0.id, $0) })
            opciones = try negocios.buscar(filtro, fecha: reloj())
                .map { negocio in
                    // Conserva la ruta ya calculada con MapKit.
                    anteriores[negocio.id] ?? Opcion(
                        negocio: negocio,
                        distanciaKm: origen.distanciaKm(a: negocio.punto),
                        minutos: origen.minutosAproximados(a: negocio.punto)
                    )
                }
                .sorted { $0.distanciaKm < $1.distanciaKm }
        } catch {
            opciones = []
            mensajeError = "No pudimos cargar las veterinarias abiertas."
        }
        if elegirMasCercana || seleccionada == nil { idNegocio = opciones.first?.id }
    }

    /// Tiempo de llegada con MapKit para las más cercanas; sin internet queda la aproximación.
    func calcularTiempos() async {
        let rutas = servicios.rutas
        for opcion in opciones.prefix(6) where opcion.aproximado {
            guard let minutos = await rutas.minutos(desde: origen, a: opcion.negocio.punto) else { continue }
            if let indice = opciones.firstIndex(where: { $0.id == opcion.id }) {
                opciones[indice].minutos = minutos
                opciones[indice].aproximado = false
            }
        }
    }

    // MARK: - Confirmar

    private var motivoLimpio: String { motivo.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var telefonoLimpio: String { telefono.filter(\.isNumber) }

    /// Lo que falta para avisar; `nil` si ya está todo.
    var pendiente: String? {
        if opciones.isEmpty { return "No hay veterinarias abiertas ahora para \(especie.tituloPlural.lowercased())" }
        if motivoLimpio.isEmpty { return "Cuéntanos qué pasa" }
        if telefonoLimpio.count < 8 { return "Agrega un teléfono de contacto" }
        if seleccionada == nil { return "Elige a dónde vas" }
        return nil
    }

    var puedeConfirmar: Bool { pendiente == nil }

    func confirmar() {
        guard puedeConfirmar, let opcion = seleccionada else { return }
        let datos = DatosEmergencia(especie: especie, motivo: motivoLimpio, telefono: telefonoLimpio)
        do {
            citaConfirmada = try citas.reservarUrgencia(
                en: opcion.negocio, mascota: mascota, datos: datos, minutosLlegada: opcion.minutos, tutor: tutor
            )
            // Los dos roles viven en el mismo iPhone: el aviso al negocio es una notificación local.
            let notificaciones = servicios.notificaciones
            let especie = mascota?.especieTexto ?? especie.titulo
            let motivo = motivoLimpio
            let minutos = opcion.minutos
            Task { await notificaciones.avisarUrgencia(especie: especie, motivo: motivo, minutos: minutos) }
        } catch {
            mensajeError = "No pudimos avisar a la veterinaria. Inténtalo de nuevo o llama directamente."
        }
    }
}
