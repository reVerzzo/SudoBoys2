import SwiftUI

@main struct MyApp: App {
    init() {
        EstiloNavegacion.aplicar()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.app.primarioTinte)
                .aparienciaDeLaApp()
        }
    }
}
