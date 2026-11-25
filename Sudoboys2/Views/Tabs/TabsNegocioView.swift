import SwiftUI

/// Pestañas del negocio: Agenda, Recetas, Perfil y Ajustes.
struct TabsNegocioView: View {
    let negocio: Negocio
    let ajustes: AjustesViewModel

    var body: some View {
        TabView {
            Tab("Agenda", systemImage: "calendar") {
                PantallaProximamente(
                    titulo: "Agenda",
                    icono: "calendar",
                    mensaje: "Aquí verás las citas de hoy y podrás avanzar cada etapa."
                )
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
        TabsNegocioView(negocio: negocio, ajustes: ajustes)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    let ajustes = VistaPrevia.ajustes(rol: .negocio)
    if let negocio = ajustes.usuario?.negocio {
        TabsNegocioView(negocio: negocio, ajustes: ajustes)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
