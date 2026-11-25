import OSLog
import SwiftData
import SwiftUI

@main struct MyApp: App {
    private let contenedor: ModelContainer
    private let repositorios: Repositorios
    @State private var appState: AppState

    init() {
        EstiloNavegacion.aplicar()

        let contenedor = ContenedorDatos.crear()
        do {
            try SeedData.sembrarSiHaceFalta(en: contenedor.mainContext)
        } catch {
            Logger(subsystem: "Sudoboys2", category: "Datos")
                .error("No se pudieron sembrar los datos de ejemplo: \(error.localizedDescription, privacy: .public)")
        }

        let repositorios = Repositorios(contexto: contenedor.mainContext)
        let appState = AppState(usuarios: repositorios.usuarios)
        appState.restaurarSesion()

        self.contenedor = contenedor
        self.repositorios = repositorios
        _appState = State(initialValue: appState)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.app.primarioTinte)
                .aparienciaDeLaApp()
                .environment(appState)
                .environment(\.repositorios, repositorios)
        }
        .modelContainer(contenedor)
    }
}
