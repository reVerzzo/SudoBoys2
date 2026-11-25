import SwiftUI

/// Estado vacío con ícono, mensaje cálido y una acción opcional.
struct EstadoVacio: View {
    let icono: String
    let titulo: String
    let mensaje: String
    var tituloAccion: String?
    var accion: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var visible = false

    init(
        icono: String,
        titulo: String,
        mensaje: String,
        tituloAccion: String? = nil,
        accion: (() -> Void)? = nil
    ) {
        self.icono = icono
        self.titulo = titulo
        self.mensaje = mensaje
        self.tituloAccion = tituloAccion
        self.accion = accion
    }

    var body: some View {
        VStack(spacing: Espaciado.m) {
            Image(systemName: icono)
                .font(.largeTitle)
                .foregroundStyle(Color.app.salud)
                .padding(Espaciado.l)
                .background(Color.app.superficieElevada, in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: Espaciado.xs) {
                Text(titulo)
                    .font(Font.app.titulo3)
                    .foregroundStyle(Color.app.textoPrincipal)
                Text(mensaje)
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
            }
            .multilineTextAlignment(.center)

            if let tituloAccion, let accion {
                BotonPrincipal(tituloAccion, accion: accion)
                    .padding(.top, Espaciado.xs)
            }
        }
        .padding(Espaciado.l)
        .frame(maxWidth: .infinity)
        .opacity(visible ? 1 : 0)
        .scaleEffect(visible || reducirMovimiento ? 1 : 0.95)
        .onAppear {
            withAnimation(Animation.app.resorte) { visible = true }
        }
    }
}

#Preview("Claro") {
    VistaPreviaEstadoVacio()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaEstadoVacio()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaEstadoVacio: View {
    var body: some View {
        EstadoVacio(
            icono: "pawprint.fill",
            titulo: "Aún no tienes mascotas",
            mensaje: "Agrega a tu compañero para llevar su cartilla y reservar citas.",
            tituloAccion: "Agregar mascota"
        ) {}
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
