import Foundation
import SwiftData

/// Preferencias de la presentación, guardadas en `UserDefaults`.
nonisolated enum PreferenciasDemo {
    /// Con el modo demo, el primer recordatorio de dosis llega al minuto de emitir la receta.
    static let claveModoDemo = "modoDemo"
    /// Espera del primer recordatorio de dosis en modo demo.
    static let segundosPrimerRecordatorio: TimeInterval = 60
}

/// Deja la app como recién instalada: borra todo y vuelve a cargar los datos de ejemplo.
protocol DatosDemoService {
    func restablecer() throws
}

struct DatosDemoSinEfecto: DatosDemoService {
    func restablecer() throws {}
}

final class DatosDemoSwiftData: DatosDemoService {
    private let contexto: ModelContext

    init(contexto: ModelContext) {
        self.contexto = contexto
    }

    func restablecer() throws {
        // Objeto por objeto (no en lote) para que el contexto en memoria quede al día
        // y se respeten las reglas de borrado en cascada.
        try borrar(Usuario.self)
        try borrar(Negocio.self)
        try contexto.save()
        // Lo que no cuelga de un usuario o negocio (por ejemplo, citas sin perfil).
        try borrar(Cita.self)
        try borrar(Receta.self)
        try borrar(Mascota.self)
        try borrar(Resena.self)
        try borrar(Medicamento.self)
        try borrar(Vacuna.self)
        try borrar(Servicio.self)
        try contexto.save()

        try SeedData.sembrarSiHaceFalta(en: contexto)
    }

    private func borrar<Modelo: PersistentModel>(_ tipo: Modelo.Type) throws {
        for objeto in try contexto.fetch(FetchDescriptor<Modelo>()) {
            contexto.delete(objeto)
        }
    }
}
