import SwiftUI

/// Fila de una receta en un historial.
struct FilaReceta: View {
    let receta: Receta
    /// En el negocio se muestra a la mascota; en la mascota, al negocio.
    var paraNegocio = false

    var body: some View {
        TarjetaApp {
            HStack(spacing: Espaciado.s) {
                Image(systemName: "pills.fill")
                    .font(.title3)
                    .foregroundStyle(Color.app.textoSobreSalud)
                    .frame(width: 44, height: 44)
                    .background(Color.app.saludTexto, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(receta.diagnostico)
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .lineLimit(2)
                    Text("\(paraNegocio ? (receta.mascota?.nombre ?? "Sin perfil") : (receta.negocio?.nombre ?? receta.nombreVeterinario)) · \(receta.fecha.fechaCorta)")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                    if receta.requiereRecetaFisica {
                        Label("Requiere receta física", systemImage: "doc.text.fill")
                            .font(Font.app.etiqueta)
                            .foregroundStyle(Color.app.acentoTexto)
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

/// Una receta completa, con su PDF para compartir. Se presenta como hoja.
struct DetalleRecetaView: View {
    let receta: Receta
    /// Cambia los textos de ayuda: el negocio entrega la receta, el tutor la recibe.
    var paraNegocio = false
    var generador = GeneradorPDFReceta()

    @Environment(\.dismiss) private var cerrar
    @State private var pdf: URL?
    @State private var generando = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.l) {
                    encabezado
                    avisoRecetaFisica
                    medicamentos
                    if !receta.indicaciones.isEmpty {
                        VStack(alignment: .leading, spacing: Espaciado.s) {
                            EncabezadoSeccion("Indicaciones")
                            TarjetaApp {
                                Text(receta.indicaciones)
                                    .font(Font.app.cuerpo)
                                    .foregroundStyle(Color.app.textoPrincipal)
                            }
                        }
                    }
                    veterinario
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.m)
            }
            .background(Color.app.fondo)
            .navigationTitle("Receta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { cerrar() }
                }
            }
            .safeAreaInset(edge: .bottom) { compartir }
            .task {
                pdf = generador.pdf(de: receta)
                generando = false
            }
        }
    }

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: Espaciado.xxs) {
            Text(receta.diagnostico)
                .font(Font.app.titulo2)
                .foregroundStyle(Color.app.textoPrincipal)
                .accessibilityAddTraits(.isHeader)
            Text("\(receta.mascota?.nombre ?? "Sin perfil") · \(receta.fecha.fechaCorta)")
                .font(Font.app.cuerpo)
                .foregroundStyle(Color.app.textoSecundario)
            if let negocio = receta.negocio?.nombre {
                Label(negocio, systemImage: "cross.case.fill")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
            }
        }
    }

    @ViewBuilder
    private var avisoRecetaFisica: some View {
        if receta.requiereRecetaFisica {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Requiere receta física")
                        .font(Font.app.encabezado)
                    Text(paraNegocio
                         ? "Incluye medicamentos de los grupos I o II (NOM-064-ZOO-2000). Entrega al tutor la receta impresa y firmada."
                         : "Incluye medicamentos de los grupos I o II (NOM-064-ZOO-2000). Para surtirlos, pide a tu veterinario la receta impresa y firmada.")
                        .font(Font.app.subtitulo)
                }
            } icon: {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
            }
            .foregroundStyle(Color.app.textoSobreAcento)
            .padding(Espaciado.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.app.acento, in: Forma.tarjeta)
        } else {
            Label(paraNegocio ? "Medicamentos de venta libre: no requiere receta física." : "Medicamentos de venta libre: no necesitas receta física.", systemImage: "checkmark.seal.fill")
                .font(Font.app.subtitulo)
                .foregroundStyle(Color.app.saludTexto)
        }
    }

    private var medicamentos: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Medicamentos")
            ForEach(receta.medicamentosOrdenados) { medicamento in
                TarjetaApp {
                    VStack(alignment: .leading, spacing: Espaciado.xxs) {
                        Text(medicamento.nombre)
                            .font(Font.app.encabezado)
                            .foregroundStyle(Color.app.textoPrincipal)
                        Text(medicamento.dosis)
                            .font(Font.app.cuerpo)
                            .foregroundStyle(Color.app.textoPrincipal)
                        Label(medicamento.pauta, systemImage: "bell.fill")
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.textoSecundario)
                        Text("\(medicamento.grupo.grupoNOM) · \(medicamento.grupo.titulo)")
                            .font(Font.app.etiqueta)
                            .foregroundStyle(medicamento.grupo.requiereRecetaFisica ? Color.app.acentoTexto : Color.app.saludTexto)
                            .padding(.top, 2)
                    }
                }
            }
            Label(
                paraNegocio
                    ? "El tutor recibe un recordatorio en cada dosis."
                    : "Te recordamos cada dosis con una notificación en este iPhone.",
                systemImage: "bell.badge.fill"
            )
                .font(Font.app.nota)
                .foregroundStyle(Color.app.textoSecundario)
        }
    }

    private var veterinario: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Quién receta")
            TarjetaApp {
                VStack(alignment: .leading, spacing: Espaciado.xs) {
                    Text(receta.nombreVeterinario)
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                    InsigniaVerificado(.cedula)
                    Text("Cédula profesional \(receta.cedulaVeterinario)")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                    Label(receta.domicilioVeterinario, systemImage: "mappin.and.ellipse")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            }
        }
    }

    private var compartir: some View {
        Group {
            if let pdf {
                ShareLink(item: pdf) {
                    etiquetaCompartir("Compartir PDF", icono: "square.and.arrow.up")
                }
                .buttonStyle(.presionable)
            } else {
                etiquetaCompartir(generando ? "Preparando PDF…" : "No se pudo generar el PDF", icono: "doc.fill")
                    .opacity(0.45)
            }
        }
        .padding(.horizontal, Espaciado.margenPantalla)
        .padding(.vertical, Espaciado.s)
        .background(Color.app.fondo)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.app.borde).frame(height: 1)
        }
    }

    private func etiquetaCompartir(_ titulo: String, icono: String) -> some View {
        Label(titulo, systemImage: icono)
            .font(Font.app.encabezado)
            .foregroundStyle(Color.app.textoSobrePrimario)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.app.primario, in: Forma.control)
            .contentShape(Forma.control)
    }
}

/// Recetas emitidas por el negocio.
struct RecetasNegocioView: View {
    let negocio: Negocio
    @State private var abierta: Receta?

    private var recetas: [Receta] { negocio.recetas.sorted { $0.fecha > $1.fecha } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if !negocio.tipo.ofrece(.veterinaria) {
                    EstadoVacio(
                        icono: "pills.fill",
                        titulo: "Solo para veterinarias",
                        mensaje: "Las recetas las emiten veterinarias con cédula profesional verificada."
                    )
                    .padding(.top, Espaciado.xl)
                } else if recetas.isEmpty {
                    EstadoVacio(
                        icono: "pills.fill",
                        titulo: "Aún no emites recetas",
                        mensaje: negocio.puedeEmitirRecetas
                            ? "Emítelas desde una cita de veterinaria en tu agenda."
                            : "Cuando tu cédula esté verificada podrás emitirlas desde una cita."
                    )
                    .padding(.top, Espaciado.xl)
                } else {
                    LazyVStack(spacing: Espaciado.m) {
                        ForEach(recetas) { receta in
                            Button {
                                abierta = receta
                            } label: {
                                FilaReceta(receta: receta, paraNegocio: true)
                            }
                            .buttonStyle(.presionable)
                        }
                    }
                    .padding(.horizontal, Espaciado.margenPantalla)
                    .padding(.vertical, Espaciado.s)
                }
            }
            .background(Color.app.fondo)
            .navigationTitle("Recetas")
            .sheet(item: $abierta) { receta in
                DetalleRecetaView(receta: receta, paraNegocio: true)
            }
        }
    }
}

#Preview("Claro") {
    if let receta = VistaPrevia.recetaFirulais() {
        DetalleRecetaView(receta: receta)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let receta = VistaPrevia.recetaFirulais() {
        DetalleRecetaView(receta: receta)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
