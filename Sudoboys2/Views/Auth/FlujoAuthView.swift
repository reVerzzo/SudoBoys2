import SwiftUI

/// Navegación de entrada: bienvenida → inicio de sesión → alta de negocio.
struct FlujoAuthView: View {
    @Bindable var viewModel: InicioSesionViewModel
    @Namespace private var transicion

    var body: some View {
        NavigationStack(path: $viewModel.ruta) {
            BienvenidaView(transicion: transicion, alElegir: viewModel.elegir)
                .navigationDestination(for: InicioSesionViewModel.Ruta.self) { ruta in
                    switch ruta {
                    case .inicioSesion(let rol):
                        InicioSesionView(viewModel: viewModel, rol: rol)
                            .navigationTransition(.zoom(sourceID: rol, in: transicion))
                    case .altaNegocio:
                        AltaNegocioView(viewModel: viewModel.altaNegocio)
                    }
                }
        }
    }
}

#Preview("Claro") {
    FlujoAuthView(viewModel: VistaPrevia.inicioSesion())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    FlujoAuthView(viewModel: VistaPrevia.inicioSesion())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
