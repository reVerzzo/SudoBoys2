import SwiftUI

/// Identifica a la mascota que llega: QR de su tarjeta o, como alternativa, la lista de citas de hoy.
struct IdentificarMascotaView: View {
    let viewModel: AgendaViewModel
    let alElegir: (UUID) -> Void

    @Environment(\.dismiss) private var cerrar
    @State private var camaraLista = false
    @State private var revisandoCamara = true
    @State private var mensaje: String?
    @State private var errores = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.l) {
                    escaner
                    if let mensaje {
                        Label(mensaje, systemImage: "exclamationmark.triangle.fill")
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.acentoTexto)
                            .transition(.opacity)
                    }
                    lista
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.m)
                .animation(Animation.app.suave, value: mensaje)
            }
            .background(Color.app.fondo)
            .navigationTitle("Identificar mascota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { cerrar() }
                }
            }
            .task {
                camaraLista = await EscanerQR.prepararCamara()
                revisandoCamara = false
            }
            .sensoryFeedback(.error, trigger: errores)
        }
    }

    @ViewBuilder
    private var escaner: some View {
        if camaraLista {
            EscanerQR { codigo in
                switch viewModel.identificar(codigo: codigo) {
                case .cita(let id):
                    elegir(id)
                case .error(let texto):
                    mensaje = texto
                    errores += 1
                }
            }
            .frame(height: 300)
            .clipShape(Forma.hoja)
            .overlay(alignment: .bottom) {
                Text("Apunta al QR de la tarjeta de la mascota")
                    .font(Font.app.etiqueta)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Espaciado.s)
                    .padding(.vertical, Espaciado.xs)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(Espaciado.s)
            }
            .accessibilityLabel("Cámara para escanear el QR de la mascota")
        } else {
            VStack(spacing: Espaciado.s) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.largeTitle)
                    .foregroundStyle(Color.app.primarioTinte)
                    .accessibilityHidden(true)
                Text(revisandoCamara ? "Preparando la cámara…" : "El escáner no está disponible aquí")
                    .font(Font.app.encabezado)
                    .foregroundStyle(Color.app.textoPrincipal)
                if !revisandoCamara {
                    Text("Elige a la mascota en la lista de abajo. En un iPhone con cámara puedes escanear el QR de su tarjeta.")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Espaciado.l)
            .frame(maxWidth: .infinity)
            .background(Color.app.superficieElevada, in: Forma.hoja)
        }
    }

    private var lista: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("O elige de la lista")
            if viewModel.pendientes.isEmpty {
                Text("No hay citas pendientes hoy.")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
            } else {
                ForEach(viewModel.pendientes) { cita in
                    Button {
                        elegir(cita.id)
                    } label: {
                        TarjetaCita(cita: cita, paraNegocio: true)
                    }
                    .buttonStyle(.presionable)
                }
            }
        }
    }

    private func elegir(_ id: UUID) {
        cerrar()
        alElegir(id)
    }
}

#Preview("Claro") {
    if let agenda = VistaPrevia.agenda() {
        IdentificarMascotaView(viewModel: agenda) { _ in }
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let agenda = VistaPrevia.agenda() {
        IdentificarMascotaView(viewModel: agenda) { _ in }
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
