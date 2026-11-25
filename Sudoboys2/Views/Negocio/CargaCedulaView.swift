import PhotosUI
import SwiftUI

/// Carga de la cédula profesional: foto, lectura automática y envío a revisión.
struct CargaCedulaView: View {
    @Bindable var viewModel: VerificacionViewModel
    @Environment(\.dismiss) private var cerrar
    @State private var seleccion: PhotosPickerItem?
    @State private var mostrandoCamara = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.l) {
                    foto
                    if let resultado = viewModel.resultadoLectura {
                        Label(resultado, systemImage: "text.viewfinder")
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.saludTexto)
                            .transition(.opacity)
                    }
                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        CampoTexto("Nombre en la cédula", marcador: "Nombre completo", icono: "person.fill", texto: $viewModel.nombre)
                            .textContentType(.name)
                        CampoTexto("Número de cédula", marcador: "7 u 8 dígitos", icono: "number", texto: $viewModel.cedula)
                            .keyboardType(.numberPad)
                    }
                    .redacted(reason: viewModel.leyendo ? .placeholder : [])
                    Label("Un administrador revisa tu cédula antes de mostrar la insignia y permitirte emitir recetas.", systemImage: "checkmark.shield.fill")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.m)
                .animation(Animation.app.resorte, value: viewModel.resultadoLectura)
                .animation(Animation.app.suave, value: viewModel.leyendo)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.app.fondo)
            .navigationTitle("Cédula profesional")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: Espaciado.xs) {
                    if let pendiente = viewModel.pendiente {
                        Text(pendiente)
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.textoSecundario)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    BotonPrincipal("Enviar a revisión", icono: "paperplane.fill", cargando: viewModel.leyendo) {
                        if viewModel.enviarARevision() { cerrar() }
                    }
                    .disabled(!viewModel.puedeEnviar)
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.s)
                .background(Color.app.fondo)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.app.borde).frame(height: 1)
                }
                .ocultarConTeclado()
            }
            .task(id: seleccion) {
                guard let seleccion else { return }
                if let datos = try? await seleccion.loadTransferable(type: Data.self) {
                    await viewModel.usarFoto(datos)
                }
            }
            .fullScreenCover(isPresented: $mostrandoCamara) {
                CamaraFoto { datos in
                    mostrandoCamara = false
                    if let datos {
                        Task { await viewModel.usarFoto(datos) }
                    }
                }
                .ignoresSafeArea()
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
        .onAppear { viewModel.prepararCarga() }
    }

    private var foto: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            Group {
                if let datos = viewModel.foto, let imagen = UIImage(data: datos) {
                    Image(uiImage: imagen)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 240)
                        .clipShape(Forma.tarjeta)
                        .overlay {
                            if viewModel.leyendo {
                                Forma.tarjeta.fill(.black.opacity(0.35))
                                ProgressView("Leyendo la cédula…")
                                    .tint(.white)
                                    .foregroundStyle(.white)
                            }
                        }
                        .accessibilityLabel("Foto de la cédula")
                } else {
                    VStack(spacing: Espaciado.xs) {
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.app.primarioTinte)
                            .accessibilityHidden(true)
                        Text("Toma o elige una foto de tu cédula")
                            .font(Font.app.encabezado)
                            .foregroundStyle(Color.app.textoPrincipal)
                        Text("Leemos el nombre y el número por ti.")
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.textoSecundario)
                    }
                    .multilineTextAlignment(.center)
                    .padding(Espaciado.l)
                    .frame(maxWidth: .infinity)
                    .background(Color.app.superficieElevada, in: Forma.tarjeta)
                }
            }
            HStack(spacing: Espaciado.s) {
                if CamaraFoto.disponible {
                    BotonSecundario("Tomar foto", icono: "camera.fill") { mostrandoCamara = true }
                }
                PhotosPicker(selection: $seleccion, matching: .images) {
                    Label(viewModel.foto == nil ? "Elegir foto" : "Cambiar foto", systemImage: "photo.fill")
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .padding(.horizontal, Espaciado.m)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Color.app.superficieElevada, in: Forma.control)
                }
                .buttonStyle(.presionable)
            }
        }
    }
}

#Preview("Claro") {
    if let verificacion = VistaPrevia.verificacion() {
        CargaCedulaView(viewModel: verificacion)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let verificacion = VistaPrevia.verificacion() {
        CargaCedulaView(viewModel: verificacion)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
