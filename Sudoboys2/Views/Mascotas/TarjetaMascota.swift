import SwiftUI

extension Mascota {
    /// Foto de la mascota lista para SwiftUI; `nil` sin foto.
    var imagen: Image? {
        guard let foto, let imagen = UIImage(data: foto) else { return nil }
        return Image(uiImage: imagen)
    }
}

/// Tarjeta de una mascota en la lista: foto, datos, alergias y próxima vacuna.
struct TarjetaMascota: View {
    let mascota: Mascota

    var body: some View {
        TarjetaApp {
            HStack(spacing: Espaciado.m) {
                AvatarMascota(
                    imagen: mascota.imagen,
                    nombre: mascota.nombre,
                    iconoRespaldo: mascota.especie.icono,
                    tamano: 72
                )
                VStack(alignment: .leading, spacing: Espaciado.xxs) {
                    Text(mascota.nombre)
                        .font(Font.app.titulo3)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .lineLimit(2)
                    Text(mascota.resumen())
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                    if !mascota.alergias.isEmpty {
                        Label("Alergia: \(mascota.alergias)", systemImage: "exclamationmark.triangle.fill")
                            .font(Font.app.etiqueta)
                            .foregroundStyle(Color.app.acentoTexto)
                            .lineLimit(2)
                    }
                    if let proxima = mascota.proximaVacuna(), let fecha = proxima.proximaDosis {
                        InsigniaSalud("Próxima: \(fecha.fechaCorta)")
                            .padding(.top, Espaciado.xxs)
                            .accessibilityLabel("Próxima vacuna: \(proxima.nombre), \(fecha.fechaCorta)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(Font.app.subtitulo.weight(.semibold))
                    .foregroundStyle(Color.app.textoSecundario)
                    .accessibilityHidden(true)
            }
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Claro") {
    VistaPreviaTarjetas().preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaTarjetas().preferredColorScheme(.dark)
}

private struct VistaPreviaTarjetas: View {
    var body: some View {
        VStack(spacing: Espaciado.m) {
            ForEach(VistaPrevia.misMascotas().mascotas) { mascota in
                TarjetaMascota(mascota: mascota)
            }
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
