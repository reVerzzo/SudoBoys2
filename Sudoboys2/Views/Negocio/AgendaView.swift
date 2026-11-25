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
                        ForEach(viewModel.citas) { cita in
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
            .sensoryFeedback(.success, trigger: viewModel.avances)
            .onAppear { viewModel.cargar() }
        }
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
