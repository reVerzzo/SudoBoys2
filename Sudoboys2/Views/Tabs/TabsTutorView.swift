import SwiftUI

/// Pestañas del tutor: Explorar, Mis mascotas, Citas y Ajustes.
struct TabsTutorView: View {
    let ajustes: AjustesViewModel

    var body: some View {
        TabView {
            Tab("Explorar", systemImage: "map.fill") {
                PantallaProximamente(
                    titulo: "Explorar",
                    icono: "map.fill",
                    mensaje: "Aquí verás el mapa con veterinarias y estéticas cerca de ti."
                )
            }
            Tab("Mis mascotas", systemImage: "pawprint.fill") {
                PantallaProximamente(
                    titulo: "Mis mascotas",
                    icono: "pawprint.fill",
                    mensaje: "Aquí vivirán las tarjetas y la cartilla de tus mascotas."
                )
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
    TabsTutorView(ajustes: VistaPrevia.ajustes(rol: .tutor))
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    TabsTutorView(ajustes: VistaPrevia.ajustes(rol: .tutor))
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
