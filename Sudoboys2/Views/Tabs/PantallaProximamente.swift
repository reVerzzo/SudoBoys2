import SwiftUI

/// Pestaña cuya función aún no se construye: título y un estado vacío cálido.
struct PantallaProximamente: View {
    let titulo: String
    let icono: String
    let mensaje: String

    var body: some View {
        NavigationStack {
            ScrollView {
                EstadoVacio(icono: icono, titulo: "Muy pronto", mensaje: mensaje)
                    .padding(.top, Espaciado.xl)
            }
            .background(Color.app.fondo)
            .navigationTitle(titulo)
        }
    }
}

#Preview("Claro") {
    PantallaProximamente(titulo: "Explorar", icono: "map.fill", mensaje: "Aquí verás el mapa con negocios cerca de ti.")
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    PantallaProximamente(titulo: "Recetas", icono: "pills.fill", mensaje: "Aquí verás las recetas que emitas.")
        .preferredColorScheme(.dark)
}
