import SwiftUI

/// Decide qué ve la persona según la sesión: entrada, alta de negocio o las pestañas de su rol.
struct RaizView: View {
    let appState: AppState
    private let repositorios: Repositorios
    private let serviciosCitas: ServiciosCitas
    @State private var inicioSesion: InicioSesionViewModel
    @State private var ajustes: AjustesViewModel
    @State private var explorar: ExplorarViewModel
    @State private var mascotas: MisMascotasViewModel
    @State private var citas: MisCitasViewModel

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    init(
        appState: AppState,
        repositorios: Repositorios,
        auth: any AuthService,
        serviciosCitas: ServiciosCitas = ServiciosCitas()
    ) {
        self.appState = appState
        self.repositorios = repositorios
        self.serviciosCitas = serviciosCitas
        _citas = State(initialValue: MisCitasViewModel(
            appState: appState, citas: repositorios.citas, servicios: serviciosCitas
        ))
        _inicioSesion = State(initialValue: InicioSesionViewModel(
            appState: appState, repositorios: repositorios, auth: auth
        ))
        _ajustes = State(initialValue: AjustesViewModel(appState: appState, auth: auth))
        _explorar = State(initialValue: ExplorarViewModel(negocios: repositorios.negocios))
        _mascotas = State(initialValue: MisMascotasViewModel(appState: appState, repositorio: repositorios.mascotas))
    }

    private enum Destino: Equatable {
        case entrada
        case altaNegocio
        case tutor
        case negocio
    }

    private var destino: Destino {
        guard let usuario = appState.usuarioActual else { return .entrada }
        switch usuario.rol {
        case .tutor: return .tutor
        case .negocio: return usuario.negocio == nil ? .altaNegocio : .negocio
        }
    }

    private var transicion: AnyTransition {
        reducirMovimiento ? .opacity : .opacity.combined(with: .scale(scale: 0.97))
    }

    var body: some View {
        ZStack {
            Color.app.fondo.ignoresSafeArea()
            switch destino {
            case .entrada:
                FlujoAuthView(viewModel: inicioSesion)
                    .transition(transicion)
            case .altaNegocio:
                if let usuario = appState.usuarioActual {
                    AltaNegocioPendienteView(
                        appState: appState, repositorios: repositorios, propietario: usuario, ajustes: ajustes
                    )
                    .transition(transicion)
                }
            case .tutor:
                TabsTutorView(explorar: explorar, mascotas: mascotas, citas: citas, ajustes: ajustes)
                    .transition(transicion)
            case .negocio:
                if let negocio = appState.negocioActual {
                    TabsNegocioView(
                        negocio: negocio, ajustes: ajustes, repositorios: repositorios, servicios: serviciosCitas
                    )
                    .id(negocio.id)
                        .transition(transicion)
                }
            }
        }
        .animation(Animation.app.suave, value: destino)
        .sensoryFeedback(.success, trigger: destino) { _, nuevo in nuevo != .entrada }
        .onChange(of: destino) {
            if destino == .entrada { inicioSesion.reiniciar() }
        }
    }
}

/// Alta para una cuenta que ya inició sesión (por ejemplo con Google) y aún no tiene negocio.
private struct AltaNegocioPendienteView: View {
    @State private var viewModel: AltaNegocioViewModel
    let ajustes: AjustesViewModel

    init(appState: AppState, repositorios: Repositorios, propietario: Usuario, ajustes: AjustesViewModel) {
        _viewModel = State(initialValue: AltaNegocioViewModel(
            appState: appState, repositorios: repositorios, propietario: propietario
        ))
        self.ajustes = ajustes
    }

    var body: some View {
        NavigationStack {
            AltaNegocioView(viewModel: viewModel)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Salir") { ajustes.cerrarSesion() }
                    }
                }
        }
    }
}

#Preview("Entrada · Claro") {
    RaizView(appState: VistaPrevia.appState(rol: nil), repositorios: VistaPrevia.repositorios, auth: VistaPrevia.auth)
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Tutor · Oscuro") {
    RaizView(appState: VistaPrevia.appState(rol: .tutor), repositorios: VistaPrevia.repositorios, auth: VistaPrevia.auth)
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
