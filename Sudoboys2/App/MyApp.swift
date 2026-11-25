import OSLog
import SwiftData
import SwiftUI

@main struct MyApp: App {
    private let contenedor: ModelContainer
    private let repositorios: Repositorios
    private let datosDemo: any DatosDemoService
    private let auth: any AuthService = AuthServiceLocal()
    private let serviciosCitas = ServiciosCitas.reales()
    @State private var appState: AppState

    init() {
        EstiloNavegacion.aplicar()

        let contenedor = ContenedorDatos.crear()
        do {
            try SeedData.sembrarSiHaceFalta(en: contenedor.mainContext)
            try SeedData.asegurarCitaDeHoy(en: contenedor.mainContext)
        } catch {
            Logger(subsystem: "Sudoboys2", category: "Datos")
                .error("No se pudieron sembrar los datos de ejemplo: \(error.localizedDescription, privacy: .public)")
        }

        let repositorios = Repositorios(contexto: contenedor.mainContext)
        let appState = AppState(usuarios: repositorios.usuarios)
        appState.restaurarSesion()

        self.contenedor = contenedor
        self.repositorios = repositorios
        self.datosDemo = DatosDemoSwiftData(contexto: contenedor.mainContext)
        _appState = State(initialValue: appState)
    }

    var body: some Scene {
        WindowGroup {
            RaizView(
                appState: appState, repositorios: repositorios, auth: auth,
                serviciosCitas: serviciosCitas, datosDemo: datosDemo
            )
                // Al restablecer los datos de demo se reconstruyen todas las pantallas.
                .id(appState.generacionDatos)
                .tint(Color.app.primarioTinte)
                .aparienciaDeLaApp()
                .onOpenURL { url in _ = auth.manejar(url: url) }
                .environment(appState)
                .environment(\.repositorios, repositorios)
                .environment(\.serviciosCitas, serviciosCitas)
        }
        .modelContainer(contenedor)
    }
}
