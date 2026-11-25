import SwiftUI

/// Hoja para reservar: mascota o cita sin perfil, servicio, día y horario.
struct ReservarView: View {
    @Bindable var viewModel: ReservarViewModel
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationStack {
            ZStack {
                if let cita = viewModel.citaConfirmada {
                    ConfirmacionCitaView(cita: cita) { cerrar() }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    formulario
                        .transition(.opacity)
                }
            }
            .animation(Animation.app.resorte, value: viewModel.citaConfirmada == nil)
            .background(Color.app.fondo)
            .navigationTitle(viewModel.citaConfirmada == nil ? "Reservar" : "")
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
        .sensoryFeedback(.selection, trigger: viewModel.horario)
        .sensoryFeedback(.selection, trigger: viewModel.paciente)
        .environment(\.locale, .mx)
        .interactiveDismissDisabled(viewModel.citaConfirmada != nil)
    }

    private var formulario: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.l) {
                Label(viewModel.negocio.nombre, systemImage: viewModel.negocio.tipo.icono)
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                seccionPaciente
                if viewModel.esSinPerfil {
                    seccionEmergencia
                        .transition(.opacity)
                }
                seccionServicio
                seccionCuando
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.m)
            .animation(Animation.app.resorte, value: viewModel.esSinPerfil)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { barraConfirmar }
    }

    // MARK: - Para quién

    private var seccionPaciente: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("¿Para quién?")
            ForEach(viewModel.mascotas) { mascota in
                let atiende = viewModel.atiende(mascota)
                OpcionPaciente(
                    titulo: mascota.nombre,
                    subtitulo: atiende ? mascota.resumen() : "Aquí no atienden \(mascota.especie.tituloPlural.lowercased())",
                    seleccionada: viewModel.paciente == .mascota(mascota.id)
                ) {
                    AvatarMascota(imagen: mascota.imagen, nombre: mascota.nombre, iconoRespaldo: mascota.especie.icono, tamano: 44)
                } accion: {
                    viewModel.paciente = .mascota(mascota.id)
                }
                .disabled(!atiende)
                .opacity(atiende ? 1 : 0.5)
            }
            OpcionPaciente(
                titulo: "Cita sin perfil",
                subtitulo: "Para emergencias: solo especie, motivo y teléfono",
                seleccionada: viewModel.esSinPerfil
            ) {
                Image(systemName: "cross.case.fill")
                    .font(.title3)
                    .foregroundStyle(Color.app.textoSobreAcento)
                    .frame(width: 44, height: 44)
                    .background(Color.app.acento, in: Circle())
                    .accessibilityHidden(true)
            } accion: {
                viewModel.paciente = .sinPerfil
            }
        }
    }

    private var seccionEmergencia: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Datos de la emergencia")
            HStack(spacing: Espaciado.xs) {
                ForEach(viewModel.negocio.especiesAtendidas, id: \.self) { especie in
                    ChipFiltro(especie.titulo, icono: especie.icono, seleccionado: viewModel.especieEmergencia == especie) {
                        viewModel.especieEmergencia = especie
                    }
                }
            }
            CampoTexto("Motivo", marcador: "Por ejemplo: vómito desde la mañana", icono: "text.bubble.fill", texto: $viewModel.motivo)
            CampoTexto("Teléfono de contacto", marcador: "55 1234 5678", icono: "phone.fill", texto: $viewModel.telefono)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        }
    }

    // MARK: - Servicio

    private var seccionServicio: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Servicio")
            if viewModel.eligeTipo {
                HStack(spacing: Espaciado.xs) {
                    ForEach(TipoServicio.allCases, id: \.self) { tipo in
                        ChipFiltro(tipo.titulo, icono: tipo.icono, seleccionado: viewModel.tipo == tipo) {
                            viewModel.tipo = tipo
                        }
                    }
                }
            }
            if viewModel.serviciosDisponibles.isEmpty {
                Text("Se define al llegar, según lo que necesite tu mascota.")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
            } else {
                TarjetaApp(relleno: Espaciado.xs) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.serviciosDisponibles) { servicio in
                            FilaServicio(servicio: servicio, seleccionado: viewModel.servicio?.id == servicio.id) {
                                viewModel.servicio = servicio
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Cuándo

    private var seccionCuando: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("¿Cuándo?")
            if viewModel.dias.isEmpty {
                Text("Este negocio no tiene horarios disponibles esta semana.")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: Espaciado.xs) {
                        ForEach(viewModel.dias, id: \.self) { dia in
                            ChipFiltro(titulo(dia), seleccionado: viewModel.dia == dia) {
                                viewModel.dia = dia
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Espaciado.xs)], spacing: Espaciado.xs) {
                    ForEach(viewModel.horarios, id: \.self) { horario in
                        ChipHorario(
                            titulo: viewModel.esAhora(horario) ? "Ahora" : horario.horaCorta,
                            destacado: viewModel.esAhora(horario),
                            seleccionado: viewModel.horario == horario
                        ) {
                            viewModel.horario = horario
                        }
                    }
                }
                .animation(Animation.app.suave, value: viewModel.dia)
            }
        }
    }

    private func titulo(_ dia: Date) -> String {
        let calendario = Calendar.current
        if calendario.isDateInToday(dia) { return "Hoy" }
        if calendario.isDateInTomorrow(dia) { return "Mañana" }
        return dia.formatted(.dateTime.weekday(.abbreviated).day().locale(.mx)).primeraMayuscula
    }

    // MARK: - Confirmar

    private var barraConfirmar: some View {
        VStack(spacing: Espaciado.xs) {
            HStack {
                Text(viewModel.pendiente ?? viewModel.horario?.fechaCita ?? "")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                    .contentTransition(.opacity)
                Spacer(minLength: Espaciado.xs)
                if let precio = viewModel.servicio?.precio {
                    Text(precio, format: .currency(code: "MXN").precision(.fractionLength(0)))
                        .font(Font.app.cuerpoDestacado)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .animation(Animation.app.resorte, value: viewModel.servicio?.id)
            .animation(Animation.app.suave, value: viewModel.pendiente)
            BotonPrincipal("Confirmar cita", icono: "checkmark.circle.fill") {
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
}

// MARK: - Piezas

private struct OpcionPaciente<Icono: View>: View {
    let titulo: String
    let subtitulo: String
    let seleccionada: Bool
    @ViewBuilder let icono: Icono
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: Espaciado.s) {
                icono
                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo)
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                    Text(subtitulo)
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityAddTraits(seleccionada ? .isSelected : [])
    }
}

private struct FilaServicio: View {
    let servicio: Servicio
    let seleccionado: Bool
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: Espaciado.s) {
                Image(systemName: seleccionado ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(seleccionado ? Color.app.saludTexto : Color.app.borde)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(servicio.nombre)
                        .font(Font.app.cuerpo)
                        .foregroundStyle(Color.app.textoPrincipal)
                    Text("\(servicio.duracionMinutos) min")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(servicio.precio, format: .currency(code: "MXN").precision(.fractionLength(0)))
                    .font(Font.app.cuerpoDestacado)
                    .foregroundStyle(Color.app.textoPrincipal)
                    .monospacedDigit()
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, Espaciado.xs)
            .padding(.vertical, Espaciado.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.presionable)
        .animation(Animation.app.resorte, value: seleccionado)
        .accessibilityAddTraits(seleccionado ? .isSelected : [])
    }
}

private struct ChipHorario: View {
    let titulo: String
    let destacado: Bool
    let seleccionado: Bool
    let accion: () -> Void

    private var fondo: Color {
        if seleccionado { return destacado ? Color.app.acento : Color.app.primario }
        return Color.app.superficieElevada
    }

    private var texto: Color {
        if seleccionado { return destacado ? Color.app.textoSobreAcento : Color.app.textoSobrePrimario }
        return destacado ? Color.app.acentoTexto : Color.app.textoPrincipal
    }

    var body: some View {
        Button(action: accion) {
            Text(titulo)
                .font(Font.app.subtitulo.weight(.medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(texto)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(fondo, in: Forma.chip)
                .contentShape(Forma.chip)
        }
        .buttonStyle(.presionable)
        .animation(Animation.app.rapida, value: seleccionado)
        .accessibilityAddTraits(seleccionado ? .isSelected : [])
    }
}

/// Confirmación de la reserva, con el resumen de la cita.
struct ConfirmacionCitaView: View {
    let cita: Cita
    let alCerrar: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var visible = false

    var body: some View {
        VStack(spacing: Espaciado.l) {
            Spacer(minLength: 0)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .imageScale(.large)
                .foregroundStyle(Color.app.saludTexto)
                .padding(Espaciado.l)
                .background(Color.app.salud.opacity(0.18), in: Circle())
                .scaleEffect(visible || reducirMovimiento ? 1 : 0.6)
                .symbolEffect(.bounce, value: visible)
                .accessibilityHidden(true)
            VStack(spacing: Espaciado.xs) {
                Text(cita.esUrgencia ? "Te esperamos" : "¡Cita confirmada!")
                    .font(Font.app.titulo)
                    .foregroundStyle(Color.app.textoPrincipal)
                Text(cita.esUrgencia
                     ? "\(cita.negocio?.nombre ?? "El negocio") ya sabe que vas en camino."
                     : "Te avisaremos en cada etapa y cuando esté listo para recoger.")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                    .multilineTextAlignment(.center)
            }
            TarjetaCita(cita: cita)
            Spacer(minLength: 0)
            BotonPrincipal("Listo", accion: alCerrar)
        }
        .padding(.horizontal, Espaciado.margenPantalla)
        .padding(.vertical, Espaciado.m)
        .opacity(visible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.35)) { visible = true }
        }
    }
}

#Preview("Claro") {
    if let reserva = VistaPrevia.reservar() {
        ReservarView(viewModel: reserva)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let reserva = VistaPrevia.reservar() {
        ReservarView(viewModel: reserva)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
