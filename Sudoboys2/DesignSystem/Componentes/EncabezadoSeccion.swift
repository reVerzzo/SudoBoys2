import SwiftUI

/// Encabezado de sección con título redondeado y una acción opcional ("Ver todo").
struct EncabezadoSeccion: View {
    let titulo: String
    var tituloAccion: String?
    var accion: (() -> Void)?

    init(_ titulo: String, tituloAccion: String? = nil, accion: (() -> Void)? = nil) {
        self.titulo = titulo
        self.tituloAccion = tituloAccion
        self.accion = accion
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Espaciado.s) {
            Text(titulo)
                .font(Font.app.titulo3)
                .foregroundStyle(Color.app.textoPrincipal)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Espaciado.xs)
            if let tituloAccion, let accion {
                Button(tituloAccion, action: accion)
                    .font(Font.app.subtitulo.weight(.semibold))
                    .foregroundStyle(Color.app.primarioTinte)
                    .buttonStyle(.presionable)
            }
        }
    }
}

#Preview("Claro") {
    VistaPreviaEncabezado()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaEncabezado()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaEncabezado: View {
    var body: some View {
        VStack(spacing: Espaciado.l) {
            EncabezadoSeccion("Cerca de ti", tituloAccion: "Ver todo") {}
            EncabezadoSeccion("Mis mascotas")
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
