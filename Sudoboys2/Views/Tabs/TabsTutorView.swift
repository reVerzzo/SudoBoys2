import SwiftUI

/// Pestañas del tutor: Explorar, Mis mascotas, Citas y Ajustes.
struct TabsTutorView: View {
    let explorar: ExplorarViewModel
    let mascotas: MisMascotasViewModel
    let ajustes: AjustesViewModel

    var body: some View {
        TabView {
            Tab("Explorar", systemImage: "map.fill") {
                ExplorarView(viewModel: explorar)
            }
            Tab("Mis mascotas", systemImage: "pawprint.fill") {
                MisMascotasView(viewModel: mascotas)
            }
            Tab("Citas", systemImage: "calendar") {
                PantallaProximamente(
                    titulo: "Citas",
                    icono: "calendar",
                    mensaje: "Aquí podrás reservar y seguir cada etapa de tus citas."
                )
            }
            Tab("Ajustes", systemImage: "gearshape.fill") {
                AjustesView(viewModel: ajustes)
            }
        }
    }
}

#Preview("Claro") {
    TabsTutorView(explorar: VistaPrevia.explorar(), mascotas: VistaPrevia.misMascotas(), ajustes: VistaPrevia.ajustes(rol: .tutor))
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    TabsTutorView(explorar: VistaPrevia.explorar(), mascotas: VistaPrevia.misMascotas(), ajustes: VistaPrevia.ajustes(rol: .tutor))
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
