import SwiftUI

/// Urgencia: sin horario. Paciente, motivo, teléfono y una veterinaria abierta ahora con su tiempo de llegada.
struct UrgenciaView: View {
    @Bindable var viewModel: UrgenciaViewModel
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationStack {
            ZStack {
                if let cita = viewModel.citaConfirmada {
                    ConfirmacionCitaView(cita: cita) { cerrar() }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    formulario.transition(.opacity)
                }
            }
            .animation(Animation.app.resorte, value: viewModel.citaConfirmada == nil)
            .background(Color.app.fondo)
            .navigationTitle(viewModel.citaConfirmada == nil ? "Urgencia" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.citaConfirmada == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { cerrar() }
                    }
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
        .sensoryFeedback(.success, trigger: viewModel.citaConfirmada?.id)
        .sensoryFeedback(.selection, trigger: viewModel.idNegocio)
        .environment(\.locale, .mx)
        .interactiveDismissDisabled(viewModel.citaConfirmada != nil)
        .task { await viewModel.calcularTiempos() }
    }

    private var formulario: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.l) {
                Text("Sin horario: avisa que vas en camino y te atienden al llegar.")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                paciente
                datos
                destino
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.m)
            .animation(Animation.app.resorte, value: viewModel.idMascota)
            .animation(Animation.app.resorte, value: viewModel.opciones.map(\.id))
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { barra.ocultarConTeclado() }
    }

    // MARK: - Secciones

    private var paciente: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("¿Quién necesita atención?")
            ScrollView(.horizontal) {
                HStack(spacing: Espaciado.xs) {
                    ForEach(viewModel.mascotas) { mascota in
                        ChipFiltro(mascota.nombre, icono: mascota.especie.icono, seleccionado: viewModel.idMascota == mascota.id) {
                            viewModel.idMascota = mascota.id
                        }
                    }
                    ChipFiltro("Sin perfil", icono: "cross.case.fill", seleccionado: viewModel.idMascota == nil) {
                        viewModel.idMascota = nil
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            if viewModel.idMascota == nil {
                HStack(spacing: Espaciado.xs) {
                    ForEach(Especie.allCases, id: \.self) { especie in
                        ChipFiltro(especie.titulo, icono: especie.icono, seleccionado: viewModel.especieSinPerfil == especie) {
                            viewModel.especieSinPerfil = especie
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }

    private var datos: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            CampoTexto("Motivo", marcador: "Por ejemplo: vómito desde la mañana", icono: "text.bubble.fill", texto: $viewModel.motivo)
            CampoTexto("Teléfono de contacto", marcador: "55 1234 5678", icono: "phone.fill", texto: $viewModel.telefono)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        }
    }

    private var destino: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Abiertas ahora")
            if viewModel.opciones.isEmpty {
                TarjetaApp {
                    Label(
                        "No hay veterinarias abiertas ahora para \(viewModel.especie.tituloPlural.lowercased()).",
                        systemImage: "moon.zzz.fill"
                    )
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                }
            } else {
                ForEach(viewModel.opciones) { opcion in
                    FilaDestino(opcion: opcion, seleccionada: viewModel.idNegocio == opcion.id) {
                        viewModel.idNegocio = opcion.id
                    }
                }
            }
        }
    }

    private var barra: some View {
        VStack(spacing: Espaciado.xs) {
            Text(viewModel.pendiente ?? resumen)
                .font(Font.app.subtitulo)
                .foregroundStyle(Color.app.textoSecundario)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.opacity)
                .animation(Animation.app.suave, value: viewModel.pendiente)
            BotonAcento("Avisar que voy en camino", icono: "cross.case.fill") {
                viewModel.confirmar()
            }
            .disabled(!viewModel.puedeConfirmar)
        }
        .padding(.horizontal, Espaciado.margenPantalla)
        .padding(.vertical, Espaciado.s)
        .background(Color.app.fondo)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.app.borde).frame(height: 1)
        }
    }

    private var resumen: String {
        guard let opcion = viewModel.seleccionada else { return "" }
        return "\(opcion.negocio.nombre) · llegas en ~\(opcion.minutos) min"
    }
}

private struct FilaDestino: View {
    let opcion: UrgenciaViewModel.Opcion
    let seleccionada: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: Espaciado.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(opcion.negocio.nombre)
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                    Text("\(opcion.distanciaKm.distanciaLegible) · \(opcion.negocio.horarioTexto)")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                    if opcion.negocio.insignia != nil {
                        InsigniaVerificado(.cedula)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("~\(opcion.minutos) min")
                        .font(Font.app.cuerpoDestacado)
                        .foregroundStyle(Color.app.acentoTexto)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(opcion.minutos)))
                    Text(opcion.aproximado ? "aprox." : "en auto")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
                .animation(Animation.app.resorte, value: opcion.minutos)
                Image(systemName: seleccionada ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(seleccionada ? Color.app.saludTexto : Color.app.borde)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
            }
            .multilineTextAlignment(.leading)
            .padding(Espaciado.s)
            .background(Color.app.superficie, in: Forma.control)
            .overlay {
                Forma.control.strokeBorder(seleccionada ? Color.app.saludTexto : Color.app.borde, lineWidth: seleccionada ? 2 : 1)
            }
            .contentShape(Forma.control)
        }
        .buttonStyle(.presionable)
        .animation(Animation.app.resorte, value: seleccionada)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(seleccionada ? .isSelected : [])
    }
}

#Preview("Claro") {
    UrgenciaView(viewModel: VistaPrevia.urgencia())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    UrgenciaView(viewModel: VistaPrevia.urgencia())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
