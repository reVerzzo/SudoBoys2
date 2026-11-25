import SwiftUI

/// Alta y edición de un servicio: nombre, precio y sus etapas con minutos.
struct FormularioServicioView: View {
    @Bindable var viewModel: FormularioServicioViewModel
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.l) {
                    CampoTexto("Nombre", marcador: "Por ejemplo: Baño medicado", icono: "tag.fill", texto: $viewModel.nombre)
                        .textInputAutocapitalization(.sentences)
                    CampoTexto("Precio en pesos", marcador: "350", icono: "dollarsign.circle.fill", texto: $viewModel.precioTexto)
                        .keyboardType(.decimalPad)
                    if viewModel.eligeTipo {
                        Picker("Tipo de servicio", selection: $viewModel.tipo) {
                            ForEach(TipoServicio.allCases, id: \.self) { tipo in
                                Text(tipo.titulo).tag(tipo)
                            }
                        }
                        .pickerStyle(.segmented)
                        .sensoryFeedback(.selection, trigger: viewModel.tipo)
                    }
                    seccionEtapas
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.m)
                .animation(Animation.app.resorte, value: viewModel.etapas.map(\.id))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.app.fondo)
            .navigationTitle(viewModel.titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if viewModel.guardar() { cerrar() }
                    }
                    .disabled(!viewModel.puedeGuardar)
                }
            }
            .alert("Algo salió mal", isPresented: Binding(
                get: { viewModel.mensajeError != nil },
                set: { if !$0 { viewModel.mensajeError = nil } }
            )) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(viewModel.mensajeError ?? "")
            }
        }
        .environment(\.locale, .mx)
    }

    private var seccionEtapas: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            HStack(alignment: .firstTextBaseline) {
                EncabezadoSeccion("Etapas")
                Spacer(minLength: Espaciado.xs)
                Text("\(viewModel.minutosTotales) min en total")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(viewModel.minutosTotales)))
                    .animation(Animation.app.resorte, value: viewModel.minutosTotales)
            }
            Text("El tutor ve estas etapas en vivo. El tiempo estimado es la suma de las que faltan.")
                .font(Font.app.nota)
                .foregroundStyle(Color.app.textoSecundario)

            ForEach($viewModel.etapas) { $etapa in
                FilaEtapa(etapa: $etapa, puedeQuitar: viewModel.etapas.count > 2) {
                    viewModel.quitar(etapa)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            BotonSecundario("Agregar etapa", icono: "plus.circle.fill") {
                viewModel.agregarEtapa()
            }
            if !viewModel.esEdicion {
                Button("Proponer etapas según el nombre") { viewModel.usarPlantilla() }
                    .font(Font.app.subtitulo.weight(.semibold))
                    .foregroundStyle(Color.app.primarioTinte)
            }
            if let pendiente = viewModel.pendiente {
                Text(pendiente)
                    .font(Font.app.nota)
                    .foregroundStyle(Color.app.acentoTexto)
            }
        }
    }
}

private struct FilaEtapa: View {
    @Binding var etapa: FormularioServicioViewModel.BorradorEtapa
    let puedeQuitar: Bool
    let alQuitar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Espaciado.xs) {
            HStack(spacing: Espaciado.xs) {
                Image(systemName: EtapaCita.icono(para: etapa.titulo))
                    .foregroundStyle(Color.app.saludTexto)
                    .frame(width: 28)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
                TextField("Nombre de la etapa", text: $etapa.titulo)
                    .font(Font.app.cuerpoDestacado)
                    .foregroundStyle(Color.app.textoPrincipal)
                if puedeQuitar {
                    Button(action: alQuitar) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.app.textoSecundario)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Quitar etapa \(etapa.titulo)")
                }
            }
            Stepper(value: $etapa.minutos, in: 0...180, step: 5) {
                Text("\(etapa.minutos) min")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                    .monospacedDigit()
            }
            .sensoryFeedback(.selection, trigger: etapa.minutos)
        }
        .padding(Espaciado.s)
        .background(Color.app.superficieElevada, in: Forma.control)
    }
}

#Preview("Alta · Claro") {
    if let verificacion = VistaPrevia.verificacion() {
        FormularioServicioView(viewModel: FormularioServicioViewModel(
            servicio: nil, negocio: verificacion.negocio, negocios: VistaPrevia.repositorios.negocios
        ))
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
    }
}

#Preview("Edición · Oscuro") {
    if let verificacion = VistaPrevia.verificacion(), let servicio = verificacion.negocio.servicios.first {
        FormularioServicioView(viewModel: FormularioServicioViewModel(
            servicio: servicio, negocio: verificacion.negocio, negocios: VistaPrevia.repositorios.negocios
        ))
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
    }
}
