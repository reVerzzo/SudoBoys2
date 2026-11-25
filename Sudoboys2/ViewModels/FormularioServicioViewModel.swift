import Foundation
import Observation

/// Alta y edición de un servicio del negocio, con sus etapas y los minutos de cada una.
@Observable
final class FormularioServicioViewModel: Identifiable {
    struct BorradorEtapa: Identifiable, Equatable {
        let id = UUID()
        var titulo: String
        var minutos: Int
    }

    var nombre: String
    var precioTexto: String
    var tipo: TipoServicio {
        didSet { if tipo != oldValue, !esEdicion, !etapasEditadas { usarPlantilla() } }
    }
    var etapas: [BorradorEtapa]
    var mensajeError: String?

    let negocio: Negocio
    /// `nil` al dar de alta.
    @ObservationIgnored private let servicio: Servicio?
    @ObservationIgnored private let negocios: any NegocioRepository
    @ObservationIgnored private var etapasEditadas = false

    init(servicio: Servicio?, negocio: Negocio, negocios: any NegocioRepository) {
        self.servicio = servicio
        self.negocio = negocio
        self.negocios = negocios
        let tipo = servicio?.tipo ?? (negocio.tipo.ofrece(.estetica) ? .estetica : .veterinaria)
        self.tipo = tipo
        nombre = servicio?.nombre ?? ""
        precioTexto = servicio.map { NSDecimalNumber(decimal: $0.precio).stringValue } ?? ""
        etapas = (servicio?.etapas ?? EtapaCita.flujo(para: tipo)).map { BorradorEtapa(titulo: $0.titulo, minutos: $0.minutos) }
    }

    var esEdicion: Bool { servicio != nil }
    var titulo: String { esEdicion ? "Editar servicio" : "Nuevo servicio" }
    /// Solo se elige el tipo si el negocio ofrece los dos.
    var eligeTipo: Bool { negocio.tipo == .ambos }

    var minutosTotales: Int { etapas.reduce(0) { $0 + $1.minutos } }

    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var precio: Decimal? {
        let texto = precioTexto.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let valor = Decimal(string: texto), valor >= 0 else { return nil }
        return valor
    }

    /// Lo que falta para guardar; `nil` si ya está todo.
    var pendiente: String? {
        if nombreLimpio.isEmpty { return "Escribe el nombre del servicio" }
        if precio == nil { return "Escribe el precio, solo el número" }
        if etapas.count < 2 { return "Agrega al menos dos etapas" }
        if etapas.contains(where: { $0.titulo.trimmingCharacters(in: .whitespaces).isEmpty }) { return "Ponle nombre a cada etapa" }
        if minutosTotales == 0 { return "Indica los minutos de al menos una etapa" }
        return nil
    }

    var puedeGuardar: Bool { pendiente == nil }

    /// La nueva etapa entra antes de la última, que es el cierre ("Listo").
    func agregarEtapa() {
        etapasEditadas = true
        etapas.insert(BorradorEtapa(titulo: "", minutos: 10), at: max(etapas.count - 1, 0))
    }

    func quitar(_ etapa: BorradorEtapa) {
        guard etapas.count > 2 else { return }
        etapasEditadas = true
        etapas.removeAll { $0.id == etapa.id }
    }

    /// Propone las etapas según el nombre escrito (por ejemplo, "Vacunación").
    func usarPlantilla() {
        etapas = EtapaCita.plantilla(servicio: nombreLimpio, tipo: tipo)
            .map { BorradorEtapa(titulo: $0.titulo, minutos: $0.minutos) }
    }

    /// Devuelve `true` si se guardó.
    func guardar() -> Bool {
        guard puedeGuardar, let precio else { return false }
        let nuevas = etapas.map { EtapaCita($0.titulo.trimmingCharacters(in: .whitespaces), minutos: $0.minutos) }
        do {
            if let servicio {
                servicio.nombre = nombreLimpio
                servicio.precio = precio
                servicio.tipo = tipo
                servicio.etapas = nuevas
                try negocios.guardar()
            } else {
                try negocios.agregar(Servicio(nombre: nombreLimpio, precio: precio, tipo: tipo, etapas: nuevas), a: negocio)
            }
            return true
        } catch {
            mensajeError = "No pudimos guardar el servicio. Inténtalo de nuevo."
            return false
        }
    }
}
