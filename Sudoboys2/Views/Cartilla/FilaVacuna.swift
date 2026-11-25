import SwiftUI

/// Vacuna de la cartilla, con el indicador de quién la registró.
struct FilaVacuna: View {
    let vacuna: Vacuna
    var hoy: Date = .now

    private var vencida: Bool {
        guard let proxima = vacuna.proximaDosis else { return false }
        return proxima < hoy
    }

    var body: some View {
        TarjetaApp {
            HStack(alignment: .top, spacing: Espaciado.s) {
                Image(systemName: "syringe.fill")
                    .foregroundStyle(Color.app.saludTexto)
                    .frame(width: 40, height: 40)
                    .background(Color.app.salud.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Espaciado.xxs) {
                    Text(vacuna.nombre)
                        .font(Font.app.cuerpoDestacado)
                        .foregroundStyle(Color.app.textoPrincipal)
                    Text("Aplicada el \(vacuna.fechaAplicacion.fechaCorta)")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                    if let proxima = vacuna.proximaDosis {
                        Text(vencida ? "Refuerzo pendiente desde el \(proxima.fechaCorta)" : "Próxima dosis: \(proxima.fechaCorta)")
                            .font(Font.app.nota.weight(.medium))
                            .foregroundStyle(vencida ? Color.app.acentoTexto : Color.app.saludTexto)
                    }
                    registro
                        .padding(.top, Espaciado.xxs)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var registro: some View {
        switch vacuna.registradaPor {
        case .veterinario:
            VStack(alignment: .leading, spacing: 2) {
                Label("Registrada por veterinario", systemImage: "checkmark.seal.fill")
                    .font(Font.app.etiqueta)
                    .foregroundStyle(Color.app.saludTexto)
                    .padding(.horizontal, Espaciado.xs)
                    .padding(.vertical, Espaciado.xxs)
                    .background(Color.app.salud.opacity(0.14), in: Capsule())
                if let detalle = detalleVeterinario {
                    Text(detalle)
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            }
        case .tutor:
            Label("Registrada por el tutor", systemImage: "person.fill")
                .font(Font.app.etiqueta)
                .foregroundStyle(Color.app.textoSecundario)
                .padding(.horizontal, Espaciado.xs)
                .padding(.vertical, Espaciado.xxs)
                .background(Color.app.superficieElevada, in: Capsule())
        }
    }

    /// "Dra. Mariana López · Cédula 1234567".
    private var detalleVeterinario: String? {
        let partes = [
            vacuna.nombreVeterinario,
            vacuna.cedulaVeterinario.flatMap { $0.isEmpty ? nil : "Cédula \($0)" },
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return partes.isEmpty ? nil : partes.joined(separator: " · ")
    }
}

#Preview("Claro") {
    VistaPreviaVacunas().preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaVacunas().preferredColorScheme(.dark)
}

private struct VistaPreviaVacunas: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Espaciado.s) {
                ForEach(VistaPrevia.detalleFirulais()?.mascota.vacunas ?? []) { vacuna in
                    FilaVacuna(vacuna: vacuna)
                }
            }
            .padding(Espaciado.margenPantalla)
        }
        .background(Color.app.fondo)
    }
}
