import SwiftUI

/// Pestañas del negocio: Agenda, Recetas, Perfil y Ajustes.
struct TabsNegocioView: View {
    let negocio: Negocio
    let ajustes: AjustesViewModel
    @State private var agenda: AgendaViewModel
    @State private var verificacion: VerificacionViewModel

    init(negocio: Negocio, ajustes: AjustesViewModel, repositorios: Repositorios, servicios: ServiciosCitas = ServiciosCitas()) {
        self.negocio = negocio
        self.ajustes = ajustes
        // Semillas únicas: `RaizView` recrea esta vista (con `.id`) si cambia el negocio.
        _agenda = State(initialValue: AgendaViewModel(
            negocio: negocio, citas: repositorios.citas, recetas: repositorios.recetas, servicios: servicios
        ))
        _verificacion = State(initialValue: VerificacionViewModel(negocio: negocio, negocios: repositorios.negocios))
    }

    var body: some View {
        TabView {
            Tab("Agenda", systemImage: "calendar") {
                AgendaView(viewModel: agenda)
            }
            Tab("Recetas", systemImage: "pills.fill") {
                RecetasNegocioView(negocio: negocio)
            }
            Tab("Perfil", systemImage: "storefront.fill") {
                PerfilNegocioPropioView(negocio: negocio, viewModel: verificacion)
            }
            Tab("Ajustes", systemImage: "gearshape.fill") {
                AjustesView(viewModel: ajustes)
            }
        }
    }
}

#Preview("Claro") {
    let ajustes = VistaPrevia.ajustes(rol: .negocio)
    if let negocio = ajustes.usuario?.negocio {
        TabsNegocioView(negocio: negocio, ajustes: ajustes, repositorios: VistaPrevia.repositorios)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    let ajustes = VistaPrevia.ajustes(rol: .negocio)
    if let negocio = ajustes.usuario?.negocio {
        TabsNegocioView(negocio: negocio, ajustes: ajustes, repositorios: VistaPrevia.repositorios)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
