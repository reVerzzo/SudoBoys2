import SwiftUI

/// Pestañas del negocio: Agenda, Recetas, Perfil y Ajustes.
struct TabsNegocioView: View {
    let negocio: Negocio
    let ajustes: AjustesViewModel
    @State private var agenda: AgendaViewModel

    init(negocio: Negocio, ajustes: AjustesViewModel, citas: any CitaRepository, servicios: ServiciosCitas = ServiciosCitas()) {
        self.negocio = negocio
        self.ajustes = ajustes
        // Semilla única: `RaizView` recrea esta vista (con `.id`) si cambia el negocio.
        _agenda = State(initialValue: AgendaViewModel(negocio: negocio, citas: citas, servicios: servicios))
    }

    var body: some View {
        TabView {
            Tab("Agenda", systemImage: "calendar") {
                AgendaView(viewModel: agenda)
            }
            Tab("Recetas", systemImage: "pills.fill") {
                PantallaProximamente(
                    titulo: "Recetas",
                    icono: "pills.fill",
                    mensaje: negocio.tipo.ofrece(.veterinaria)
                        ? "Aquí aparecerán las recetas que emitas desde una cita."
                        : "Solo las veterinarias con cédula verificada emiten recetas."
                )
            }
            Tab("Perfil", systemImage: "storefront.fill") {
                PerfilNegocioPropioView(negocio: negocio)
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
        TabsNegocioView(negocio: negocio, ajustes: ajustes, citas: VistaPrevia.repositorios.citas)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    let ajustes = VistaPrevia.ajustes(rol: .negocio)
    if let negocio = ajustes.usuario?.negocio {
        TabsNegocioView(negocio: negocio, ajustes: ajustes, citas: VistaPrevia.repositorios.citas)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
