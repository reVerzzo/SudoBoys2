import SwiftUI

/// Insignia de salud rellena (vacuna al día, próxima dosis, receta activa).
/// Fondo `saludTexto` con texto `textoSobreSalud` para cumplir contraste AA.
struct InsigniaSalud: View {
    let texto: String
    var icono: String = "syringe.fill"

    @ScaledMetric(relativeTo: .caption) private var ladoIcono: CGFloat = 14

    init(_ texto: String, icono: String = "syringe.fill") {
        self.texto = texto
        self.icono = icono
    }

    var body: some View {
        HStack(spacing: Espaciado.xxs) {
            Image(systemName: icono)
                .frame(width: ladoIcono, height: ladoIcono)
                .accessibilityHidden(true)
            Text(texto)
        }
        .font(Font.app.etiqueta)
        .foregroundStyle(Color.app.textoSobreSalud)
        .padding(.horizontal, Espaciado.xs)
        .padding(.vertical, Espaciado.xxs)
        .background(Color.app.saludTexto, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

#Preview("Claro") {
    VistaPreviaInsigniaSalud()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaInsigniaSalud()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaInsigniaSalud: View {
    var body: some View {
        VStack(spacing: Espaciado.m) {
            InsigniaSalud("Vacunas al día")
            InsigniaSalud("Próxima dosis: 12 dic", icono: "calendar")
            InsigniaSalud("Receta activa", icono: "pills.fill")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
