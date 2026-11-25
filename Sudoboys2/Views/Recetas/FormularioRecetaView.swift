import SwiftUI

/// Formulario para emitir una receta desde una cita.
struct FormularioRecetaView: View {
    @Bindable var viewModel: FormularioRecetaViewModel
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.l) {
                    quienReceta
                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        EncabezadoSeccion("Diagnóstico")
                        CampoTexto("Diagnóstico", marcador: "Por ejemplo: otitis externa", icono: "stethoscope", texto: $viewModel.diagnostico)
                        campoLargo("Indicaciones", marcador: "Cuidados, dieta, próxima revisión…", texto: $viewModel.indicaciones)
                    }
                    medicamentos
                    if viewModel.requiereRecetaFisica {
                        Label {
                            Text("Requiere receta física: hay medicamentos de grupo I o II. Entrega también la receta impresa y firmada.")
                                .font(Font.app.subtitulo)
                        } icon: {
                            Image(systemName: "doc.text.fill")
                        }
                        .foregroundStyle(Color.app.textoSobreAcento)
                        .padding(Espaciado.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.app.acento, in: Forma.tarjeta)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.m)
                .animation(Animation.app.resorte, value: viewModel.requiereRecetaFisica)
                .animation(Animation.app.resorte, value: viewModel.medicamentos.map(\.id))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.app.fondo)
            .navigationTitle("Emitir receta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                }
            }
            .safeAreaInset(edge: .bottom) { barraEmitir.ocultarConTeclado() }
            .alert("Algo salió mal", isPresented: Binding(
                get: { viewModel.mensajeError != nil },
                set: { if !$0 { viewModel.mensajeError = nil } }
            )) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(viewModel.mensajeError ?? "")
            }
            .onChange(of: viewModel.emitida) {
                if viewModel.emitida { cerrar() }
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.medicamentos.count)
        // Con datos capturados, la hoja solo se cierra con "Cancelar" para no perderlos por un arrastre.
        .interactiveDismissDisabled(viewModel.tieneCambios)
        .environment(\.locale, .mx)
    }

    // MARK: - Secciones

    private var quienReceta: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            TarjetaApp {
                HStack(spacing: Espaciado.s) {
                    AvatarMascota(
                        imagen: viewModel.cita.mascota?.imagen,
                        nombre: viewModel.cita.nombreMascota,
                        iconoRespaldo: viewModel.cita.especie?.icono ?? "pawprint.fill",
                        tamano: 48
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Receta para \(viewModel.cita.nombreMascota)")
                            .font(Font.app.encabezado)
                            .foregroundStyle(Color.app.textoPrincipal)
                        if let alergias = viewModel.cita.mascota?.alergias, !alergias.isEmpty {
                            Label("Alergia: \(alergias)", systemImage: "exclamationmark.triangle.fill")
                                .font(Font.app.etiqueta)
                                .foregroundStyle(Color.app.acentoTexto)
                        } else if let resumen = viewModel.cita.mascota?.resumen() {
                            Text(resumen)
                                .font(Font.app.subtitulo)
                                .foregroundStyle(Color.app.textoSecundario)
                        }
                    }
                }
            }
            CampoTexto("Médico veterinario", marcador: "Nombre completo", icono: "person.fill", texto: $viewModel.nombreVeterinario)
                .textContentType(.name)
            HStack(spacing: Espaciado.xs) {
                InsigniaVerificado(.cedula, compacta: true)
                Text("Cédula \(viewModel.cedula) · \(viewModel.domicilio)")
                    .font(Font.app.nota)
                    .foregroundStyle(Color.app.textoSecundario)
            }
        }
    }

    private var medicamentos: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Medicamentos")
            ForEach($viewModel.medicamentos) { $medicamento in
                TarjetaMedicamento(medicamento: $medicamento, puedeQuitar: viewModel.medicamentos.count > 1) {
                    viewModel.quitar(medicamento)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
            BotonSecundario("Agregar medicamento", icono: "plus") {
                viewModel.agregarMedicamento()
            }
        }
    }

    private func campoLargo(_ titulo: String, marcador: String, texto: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Espaciado.xxs) {
            Text(titulo)
                .font(Font.app.etiqueta)
                .foregroundStyle(Color.app.textoSecundario)
            TextField(marcador, text: texto, axis: .vertical)
                .lineLimit(3...6)
                .font(Font.app.cuerpo)
                .foregroundStyle(Color.app.textoPrincipal)
                .padding(Espaciado.m)
                .background(Color.app.superficieElevada, in: Forma.control)
                .accessibilityLabel(titulo)
        }
    }

    private var barraEmitir: some View {
        VStack(spacing: Espaciado.xs) {
            if let pendiente = viewModel.pendiente {
                Text(pendiente)
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            BotonPrincipal("Emitir receta", icono: "checkmark.seal.fill") {
                viewModel.emitir()
            }
            .disabled(!viewModel.puedeEmitir)
        }
        .padding(.horizontal, Espaciado.margenPantalla)
        .padding(.vertical, Espaciado.s)
        .background(Color.app.fondo)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.app.borde).frame(height: 1)
        }
    }
}

private struct TarjetaMedicamento: View {
    @Binding var medicamento: FormularioRecetaViewModel.BorradorMedicamento
    let puedeQuitar: Bool
    let alQuitar: () -> Void

    var body: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.s) {
                CampoTexto("Medicamento", marcador: "Por ejemplo: Meloxicam 1 mg", icono: "pills.fill", texto: $medicamento.nombre)
                CampoTexto("Dosis", marcador: "Por ejemplo: 1 tableta con alimento", texto: $medicamento.dosis)
                VStack(spacing: Espaciado.xs) {
                    HStack {
                        Text("Frecuencia")
                        Spacer(minLength: Espaciado.xs)
                        Picker("Frecuencia", selection: $medicamento.cadaHoras) {
                            ForEach(FormularioRecetaViewModel.frecuencias, id: \.self) { horas in
                                Text("Cada \(horas) h").tag(horas)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Stepper(value: $medicamento.dias, in: 1...30) {
                        HStack {
                            Text("Duración")
                            Spacer(minLength: Espaciado.xs)
                            Text("\(medicamento.dias) \(medicamento.dias == 1 ? "día" : "días")")
                                .foregroundStyle(Color.app.textoSecundario)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        }
                    }
                    HStack {
                        Text("Grupo")
                        Spacer(minLength: Espaciado.xs)
                        Picker("Grupo según la NOM-064", selection: $medicamento.grupo) {
                            ForEach(GrupoMedicamento.allCases, id: \.self) { grupo in
                                Text("\(grupo.grupoNOM) · \(grupo.titulo)").tag(grupo)
                            }
                        }
                        .pickerStyle(.menu)
                        .lineLimit(1)
                        .fixedSize()
                    }
                }
                .font(Font.app.cuerpo)
                .foregroundStyle(Color.app.textoPrincipal)
                .animation(Animation.app.rapida, value: medicamento.dias)

                HStack {
                    if medicamento.grupo.requiereRecetaFisica {
                        Label("Requiere receta física", systemImage: "doc.text.fill")
                            .font(Font.app.etiqueta)
                            .foregroundStyle(Color.app.acentoTexto)
                    }
                    Spacer(minLength: 0)
                    if puedeQuitar {
                        Button("Quitar", systemImage: "trash", role: .destructive, action: alQuitar)
                            .font(Font.app.subtitulo)
                    }
                }
            }
        }
    }
}

#Preview("Claro") {
    if let formulario = VistaPrevia.formularioReceta() {
        FormularioRecetaView(viewModel: formulario)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let formulario = VistaPrevia.formularioReceta() {
        FormularioRecetaView(viewModel: formulario)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
