import SwiftUI

/// Tarjeta de contenido: fondo `superficie`, esquinas continuas y elevación
/// (sombra en claro, borde en oscuro). Sin vidrio: es contenido.
struct TarjetaApp<Contenido: View>: View {
    var relleno: CGFloat = Espaciado.m
    @ViewBuilder let contenido: Contenido

    init(relleno: CGFloat = Espaciado.m, @ViewBuilder contenido: () -> Contenido) {
        self.relleno = relleno
        self.contenido = contenido()
    }

    var body: some View {
        contenido
            .padding(relleno)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.app.superficie, in: Forma.tarjeta)
            .elevacionTarjeta()
    }
}

#Preview("Claro") {
    VistaPreviaTarjeta()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaTarjeta()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaTarjeta: View {
    var body: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.xs) {
                Text("Clínica Huellitas")
                    .font(Font.app.titulo3)
                    .foregroundStyle(Color.app.textoPrincipal)
                Text("Veterinaria y estética · Coyoacán")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
            }
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
