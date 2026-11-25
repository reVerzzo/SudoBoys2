import SwiftUI

/// Insignia de confianza: "Cédula verificada" (veterinaria) o
/// "Negocio verificado" (estética).
struct InsigniaVerificado: View {
    enum Tipo {
        case cedula
        case negocio

        var texto: String {
            switch self {
            case .cedula: "Cédula verificada"
            case .negocio: "Negocio verificado"
            }
        }
    }

    let tipo: Tipo
    /// Si es `true` solo muestra el sello, para espacios pequeños (pines del mapa).
    var compacta = false

    @State private var aparecio = false

    @ScaledMetric(relativeTo: .caption) private var ladoIcono: CGFloat = 14

    init(_ tipo: Tipo, compacta: Bool = false) {
        self.tipo = tipo
        self.compacta = compacta
    }

    var body: some View {
        HStack(spacing: Espaciado.xxs) {
            Image(systemName: "checkmark.seal.fill")
                .symbolEffect(.bounce, value: aparecio)
                .frame(width: ladoIcono, height: ladoIcono)
            if !compacta {
                Text(tipo.texto)
            }
        }
        .font(Font.app.etiqueta)
        .foregroundStyle(Color.app.saludTexto)
        .padding(.horizontal, compacta ? Espaciado.xxs : Espaciado.xs)
        .padding(.vertical, Espaciado.xxs)
        .background(Color.app.salud.opacity(0.14), in: Capsule())
        .onAppear { aparecio = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tipo.texto)
    }
}

#Preview("Claro") {
    VistaPreviaInsigniaVerificado()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaInsigniaVerificado()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaInsigniaVerificado: View {
    var body: some View {
        VStack(spacing: Espaciado.m) {
            InsigniaVerificado(.cedula)
            InsigniaVerificado(.negocio)
            InsigniaVerificado(.cedula, compacta: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
