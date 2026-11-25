import SwiftUI

/// La receta en formato de hoja carta, con los datos que pide la NOM-064-ZOO-2000.
/// Se dibuja siempre en claro; es el contenido del PDF.
struct HojaRecetaPDF: View {
    let receta: Receta

    var body: some View {
        VStack(alignment: .leading, spacing: Espaciado.m) {
            encabezado
            Divider().overlay(Color.app.borde)
            paciente
            seccion("Diagnóstico") {
                Text(receta.diagnostico)
            }
            seccion("Tratamiento") {
                VStack(alignment: .leading, spacing: Espaciado.s) {
                    ForEach(Array(receta.medicamentosOrdenados.enumerated()), id: \.element.id) { indice, medicamento in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(indice + 1). \(medicamento.nombre)")
                                    .font(.body.weight(.semibold))
                                Spacer(minLength: Espaciado.xs)
                                Text("\(medicamento.grupo.grupoNOM) · \(medicamento.grupo.titulo)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.app.textoSecundario)
                            }
                            Text("\(medicamento.dosis). \(medicamento.pauta).")
                        }
                    }
                }
            }
            if !receta.indicaciones.isEmpty {
                seccion("Indicaciones") {
                    Text(receta.indicaciones)
                }
            }
            if receta.requiereRecetaFisica {
                Text("Requiere receta física: incluye medicamentos de los grupos I o II de la NOM-064-ZOO-2000. Este documento digital es informativo y no sustituye la receta impresa y firmada por el médico veterinario.")
                    .font(.footnote.weight(.medium))
                    .padding(Espaciado.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay { Forma.chip.strokeBorder(Color.app.acentoTexto, lineWidth: 1) }
                    .foregroundStyle(Color.app.acentoTexto)
            }
            Spacer(minLength: Espaciado.xl)
            firma
        }
        .font(.body)
        .foregroundStyle(Color.app.textoPrincipal)
        .padding(48)
    }

    private var encabezado: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(receta.negocio?.nombre ?? "Receta médica veterinaria")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("Receta médica veterinaria")
                    .font(.subheadline)
                    .foregroundStyle(Color.app.textoSecundario)
                Text(receta.domicilioVeterinario)
                    .font(.footnote)
                    .foregroundStyle(Color.app.textoSecundario)
            }
            Spacer(minLength: Espaciado.m)
            VStack(alignment: .trailing, spacing: 2) {
                Text("Fecha de expedición")
                    .font(.caption)
                    .foregroundStyle(Color.app.textoSecundario)
                Text(receta.fecha.formatted(.dateTime.day().month(.wide).year().locale(.mx)))
                    .font(.subheadline.weight(.semibold))
                Text("Folio \(receta.id.uuidString.prefix(8))")
                    .font(.caption)
                    .foregroundStyle(Color.app.textoSecundario)
            }
        }
    }

    private var paciente: some View {
        HStack(alignment: .top, spacing: Espaciado.l) {
            dato("Paciente", receta.mascota?.nombre ?? "Sin perfil")
            dato("Especie y raza", receta.mascota.map { $0.resumen(en: receta.fecha) } ?? (receta.cita?.especieEmergencia?.titulo ?? "—"))
            dato("Tutor", receta.mascota?.tutor?.nombre ?? receta.cita?.tutor?.nombre ?? "—")
        }
    }

    private func dato(_ titulo: String, _ valor: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titulo)
                .font(.caption)
                .foregroundStyle(Color.app.textoSecundario)
            Text(valor)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func seccion(_ titulo: String, @ViewBuilder contenido: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Espaciado.xs) {
            Text(titulo.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.app.saludTexto)
            contenido()
        }
    }

    private var firma: some View {
        VStack(alignment: .leading, spacing: Espaciado.xxs) {
            Rectangle()
                .fill(Color.app.textoPrincipal)
                .frame(width: 220, height: 1)
            Text(receta.nombreVeterinario)
                .font(.subheadline.weight(.semibold))
            Text("Médico veterinario · Cédula profesional \(receta.cedulaVeterinario)")
                .font(.footnote)
            Text(receta.domicilioVeterinario)
                .font(.footnote)
                .foregroundStyle(Color.app.textoSecundario)
            Text("Receta expedida conforme a la NOM-064-ZOO-2000.")
                .font(.caption)
                .foregroundStyle(Color.app.textoSecundario)
                .padding(.top, Espaciado.xxs)
        }
    }
}

extension Receta {
    /// Primero los que requieren receta física (grupos I y II), luego por nombre.
    var medicamentosOrdenados: [Medicamento] {
        medicamentos.sorted {
            ($0.grupo.requiereRecetaFisica ? 0 : 1, $0.nombre) < ($1.grupo.requiereRecetaFisica ? 0 : 1, $1.nombre)
        }
    }
}

#Preview("Hoja") {
    if let receta = VistaPrevia.recetaFirulais() {
        ScrollView {
            HojaRecetaPDF(receta: receta)
                .frame(width: GeneradorPDFReceta.anchoCarta)
                .background(.white)
                .environment(\.colorScheme, .light)
        }
    }
}
