import SwiftUI

/// Agenda del día del negocio: citas de hoy y acceso al check-in por QR o lista.
struct AgendaView: View {
    @Bindable var viewModel: AgendaViewModel
    @State private var ruta: [UUID] = []
    @State private var identificando = false

    var body: some View {
        NavigationStack(path: $ruta) {
            ScrollView {
                if viewModel.citas.isEmpty {
                    EstadoVacio(
                        icono: "calendar",
                        titulo: "Sin citas hoy",
                        mensaje: "Cuando un tutor reserve contigo, su cita aparecerá aquí."
                    )
                    .padding(.top, Espaciado.xl)
                } else {
                    LazyVStack(alignment: .leading, spacing: Espaciado.m) {
                        VStack(alignment: .leading, spacing: Espaciado.xxs) {
                            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.mx)).primeraMayuscula)
                                .font(Font.app.titulo3)
                                .foregroundStyle(Color.app.textoPrincipal)
                            Text(viewModel.resumen)
                                .font(Font.app.subtitulo)
                                .foregroundStyle(Color.app.textoSecundario)
                                .contentTransition(.numericText())
                        }
                        if !viewModel.urgencias.isEmpty {
                            VStack(alignment: .leading, spacing: Espaciado.s) {
                                Label("Urgencias en camino", systemImage: "cross.case.fill")
                                    .font(Font.app.encabezado)
                                    .foregroundStyle(Color.app.acentoTexto)
                                    .accessibilityAddTraits(.isHeader)
                                ForEach(viewModel.urgencias) { cita in
                                    NavigationLink(value: cita.id) {
                                        TarjetaUrgencia(cita: cita)
                                    }
                                    .buttonStyle(.presionable)
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }
                        ForEach(viewModel.citasDelDia) { cita in
                            NavigationLink(value: cita.id) {
                                TarjetaCita(cita: cita, paraNegocio: true)
                            }
                            .buttonStyle(.presionable)
                        }
                    }
                    .padding(.horizontal, Espaciado.margenPantalla)
                    .padding(.vertical, Espaciado.s)
                }
            }
            .background(Color.app.fondo)
            .navigationTitle("Agenda")
            .safeAreaInset(edge: .bottom) {
                Button {
                    identificando = true
                } label: {
                    Label("Escanear QR", systemImage: "qrcode.viewfinder")
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .padding(.horizontal, Espaciado.l)
                        .padding(.vertical, Espaciado.s)
                        .frame(minHeight: 52)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.presionable)
                .padding(.bottom, Espaciado.s)
                .accessibilityHint("Identifica a la mascota para registrar su llegada")
            }
            .navigationDestination(for: UUID.self) { id in
                if let cita = viewModel.cita(id: id) {
                    DetalleCitaNegocioView(viewModel: viewModel, cita: cita)
                }
            }
            .sheet(isPresented: $identificando) {
                IdentificarMascotaView(viewModel: viewModel) { id in
                    ruta = [id]
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
            .animation(Animation.app.resorte, value: viewModel.avances)
            .animation(Animation.app.resorte, value: viewModel.urgencias.map(\.id))
            .sensoryFeedback(.success, trigger: viewModel.avances)
            .sensoryFeedback(.warning, trigger: viewModel.avisosUrgencia)
            .onAppear { viewModel.cargar() }
        }
    }
}

/// Urgencia que viene en camino: resaltada en durazno, con especie, motivo y tiempo de llegada.
private struct TarjetaUrgencia: View {
    let cita: Cita

    private var especie: String { cita.mascota?.especieTexto ?? cita.especieEmergencia?.titulo ?? "Mascota" }

    var body: some View {
        HStack(alignment: .top, spacing: Espaciado.s) {
            Image(systemName: "cross.case.fill")
                .font(.title3)
                .foregroundStyle(Color.app.textoSobreAcento)
                .frame(width: 48, height: 48)
                .background(Color.app.acento, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(cita.mascota.map { "\($0.nombre) · \(especie)" } ?? "\(especie) sin perfil")
                    .font(Font.app.encabezado)
                    .foregroundStyle(Color.app.textoPrincipal)
                if let motivo = cita.motivoEmergencia, !motivo.isEmpty {
                    Text(motivo)
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .lineLimit(3)
                }
                if let telefono = cita.telefonoEmergencia, !telefono.isEmpty {
                    Label(telefono, systemImage: "phone.fill")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let minutos = cita.minutosLlegada {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("~\(minutos) min")
                        .font(Font.app.cuerpoDestacado)
                        .foregroundStyle(Color.app.acentoTexto)
                        .monospacedDigit()
                    Text("para llegar")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            }
        }
        .multilineTextAlignment(.leading)
        .padding(Espaciado.m)
        .background(Color.app.acento.opacity(0.14), in: Forma.tarjeta)
        .background(Color.app.superficie, in: Forma.tarjeta)
        .overlay {
            Forma.tarjeta.strokeBorder(Color.app.acento, lineWidth: 2)
        }
        .contentShape(Forma.tarjeta)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(TextoUrgencia.aviso(especie: especie, motivo: cita.motivoEmergencia ?? "", minutos: cita.minutosLlegada))
    }
}

#Preview("Claro") {
    if let agenda = VistaPrevia.agenda() {
        AgendaView(viewModel: agenda)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let agenda = VistaPrevia.agenda() {
        AgendaView(viewModel: agenda)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
