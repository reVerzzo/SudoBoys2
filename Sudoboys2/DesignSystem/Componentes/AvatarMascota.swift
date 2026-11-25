import SwiftUI

/// Avatar circular de la mascota. Sin foto muestra un ícono de respaldo.
struct AvatarMascota: View {
    let imagen: Image?
    /// Nombre de la mascota, para VoiceOver.
    var nombre: String?
    /// SF Symbol cuando no hay foto (por ejemplo, según la especie).
    var iconoRespaldo: String = "pawprint.fill"
    var tamano: CGFloat = 56

    init(
        imagen: Image? = nil,
        nombre: String? = nil,
        iconoRespaldo: String = "pawprint.fill",
        tamano: CGFloat = 56
    ) {
        self.imagen = imagen
        self.nombre = nombre
        self.iconoRespaldo = iconoRespaldo
        self.tamano = tamano
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.app.superficieElevada)
            if let imagen {
                imagen
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            } else {
                Image(systemName: iconoRespaldo)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.app.primarioTinte)
                    .padding(tamano * 0.28)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: tamano, height: tamano)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(Color.app.borde, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nombre.map { "Foto de \($0)" } ?? "Foto de la mascota")
        .accessibilityAddTraits(.isImage)
    }
}

#Preview("Claro") {
    VistaPreviaAvatar()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaAvatar()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaAvatar: View {
    var body: some View {
        HStack(spacing: Espaciado.m) {
            AvatarMascota(nombre: "Firulais", tamano: 40)
            AvatarMascota(nombre: "Mochi", iconoRespaldo: "hare.fill")
            AvatarMascota(nombre: "Pico", iconoRespaldo: "bird.fill", tamano: 88)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
