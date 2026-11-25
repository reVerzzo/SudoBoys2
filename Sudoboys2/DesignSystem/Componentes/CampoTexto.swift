import SwiftUI

/// Campo de texto con etiqueta visible, sobre `superficieElevada`.
struct CampoTexto: View {
    let titulo: String
    var marcador: String = ""
    var icono: String?
    @Binding var texto: String

    init(_ titulo: String, marcador: String = "", icono: String? = nil, texto: Binding<String>) {
        self.titulo = titulo
        self.marcador = marcador
        self.icono = icono
        self._texto = texto
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espaciado.xxs) {
            Text(titulo)
                .font(Font.app.etiqueta)
                .foregroundStyle(Color.app.textoSecundario)
            HStack(spacing: Espaciado.xs) {
                if let icono {
                    Image(systemName: icono)
                        .foregroundStyle(Color.app.primarioTinte)
                        .accessibilityHidden(true)
                }
                TextField(marcador, text: $texto)
                    .font(Font.app.cuerpo)
                    .foregroundStyle(Color.app.textoPrincipal)
                    .accessibilityLabel(titulo)
            }
            .padding(Espaciado.m)
            .background(Color.app.superficieElevada, in: Forma.control)
        }
    }
}

#Preview("Claro") {
    VistaPreviaCampoTexto()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaCampoTexto()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaCampoTexto: View {
    @State private var nombre = ""
    @State private var direccion = "Av. Universidad 3000, Coyoacán"

    var body: some View {
        VStack(spacing: Espaciado.m) {
            CampoTexto("Nombre del negocio", marcador: "Ej. Clínica Huellitas", texto: $nombre)
            CampoTexto("Dirección", icono: "mappin.and.ellipse", texto: $direccion)
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
