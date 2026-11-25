import Foundation
import OSLog
import SwiftData

/// Crea el `ModelContainer` local de la app. Todo vive en SwiftData, sin iCloud.
enum ContenedorDatos {
    static let modelos: [any PersistentModel.Type] = [
        Usuario.self,
        Mascota.self,
        Vacuna.self,
        Negocio.self,
        Servicio.self,
        Cita.self,
        Resena.self,
        Receta.self,
        Medicamento.self,
    ]

    private static let registro = Logger(subsystem: "Sudoboys2", category: "Datos")

    /// Contenedor en disco. Si el almacén no abre, cae a memoria para que la demo nunca truene.
    static func crear(enMemoria: Bool = false) -> ModelContainer {
        let esquema = Schema(modelos)
        if !enMemoria {
            do {
                let configuracion = ModelConfiguration(schema: esquema, cloudKitDatabase: .none)
                return try ModelContainer(for: esquema, configurations: configuracion)
            } catch {
                registro.error("No se pudo abrir el almacén en disco, se usa memoria: \(error.localizedDescription, privacy: .public)")
            }
        }
        do {
            let configuracion = ModelConfiguration(
                schema: esquema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: esquema, configurations: configuracion)
        } catch {
            // Un contenedor en memoria solo falla si el esquema está mal definido.
            fatalError("Esquema de SwiftData inválido: \(error)")
        }
    }

    /// Contenedor en memoria con los datos de ejemplo, para `#Preview`.
    static let vistaPrevia: ModelContainer = {
        let contenedor = crear(enMemoria: true)
        do {
            try SeedData.sembrarSiHaceFalta(en: contenedor.mainContext)
        } catch {
            registro.error("No se pudieron sembrar los datos de vista previa: \(error.localizedDescription, privacy: .public)")
        }
        return contenedor
    }()
}
