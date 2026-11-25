import PhotosUI
import SwiftUI

/// Escaneo de cartilla: capturar, leer y confirmar antes de guardar.
struct EscaneoCartillaView: View {
    @Bindable var viewModel: EscaneoCartillaViewModel
    @Environment(\.dismiss) private var cerrar
    @State private var mostrandoCamara = false
    @State private var seleccion: PhotosPickerItem?
    /// Páginas que entregó la cámara, en espera de leerse.
    @State private var paginas: [UIImage] = []

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.estado {
                case .inicio:
                    inicio
                case .procesando:
                    procesando
                case .revision:
                    revision
                case .sinResultados:
                    aviso(
                        icono: "doc.text.magnifyingglass",
                        titulo: "No encontramos vacunas",
                        mensaje: "Prueba con una foto más cercana y con buena luz, o agrégalas a mano."
                    )
                case .error:
                    aviso(
                        icono: "exclamationmark.triangle.fill",
                        titulo: "No pudimos leer la imagen",
                        mensaje: "Inténtalo de nuevo con otra foto."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.app.fondo)
            .animation(Animation.app.suave, value: viewModel.estado)
            .navigationTitle("Escanear cartilla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                }
            }
            .fullScreenCover(isPresented: $mostrandoCamara) {
                EscanerDocumento { imagenes in
                    mostrandoCamara = false
                    paginas = imagenes
                }
                .ignoresSafeArea()
            }
            .task(id: seleccion) {
                guard let seleccion else { return }
                guard let datos = try? await seleccion.loadTransferable(type: Data.self),
                      let imagen = UIImage(data: datos) else { return }
                await leer([imagen])
            }
            .task(id: paginas) {
                guard !paginas.isEmpty else { return }
                await leer(paginas)
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
        .interactiveDismissDisabled(viewModel.estado == .revision)
    }

    private func leer(_ imagenes: [UIImage]) async {
        // Se enderezan y reducen: Vision no necesita más resolución para leer letra impresa.
        await viewModel.procesar(imagenes: imagenes.compactMap { $0.reducida(ladoMaximo: 2400).cgImage })
    }

    // MARK: - Estados

    private var inicio: some View {
        ScrollView {
            VStack(spacing: Espaciado.l) {
                EstadoVacio(
                    icono: "doc.viewfinder",
                    titulo: "Pasa la cartilla de \(viewModel.nombreMascota) a tu iPhone",
                    mensaje: "Toma una foto de la página de vacunas. Leemos los nombres y las fechas, y tú confirmas antes de guardar."
                )
                VStack(spacing: Espaciado.s) {
                    if EscanerDocumento.disponible {
                        BotonPrincipal("Escanear con la cámara", icono: "camera.fill") {
                            mostrandoCamara = true
                        }
                    }
                    PhotosPicker(selection: $seleccion, matching: .images) {
                        Label("Elegir una foto", systemImage: "photo.on.rectangle")
                            .font(Font.app.encabezado)
                            .foregroundStyle(Color.app.textoPrincipal)
                            .padding(.horizontal, Espaciado.l)
                            .padding(.vertical, Espaciado.m)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.app.superficieElevada, in: Forma.control)
                            .contentShape(Forma.control)
                    }
                    .buttonStyle(.presionable)
                }
                Label("Todo se procesa en tu iPhone, sin internet.", systemImage: "lock.fill")
                    .font(Font.app.nota)
                    .foregroundStyle(Color.app.textoSecundario)
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.m)
        }
    }

    private var procesando: some View {
        VStack(spacing: Espaciado.m) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.app.salud)
            Text("Leyendo la cartilla…")
                .font(Font.app.titulo3)
                .foregroundStyle(Color.app.textoPrincipal)
            Text("Buscamos vacunas y fechas.")
                .font(Font.app.subtitulo)
                .foregroundStyle(Color.app.textoSecundario)
        }
        .padding(Espaciado.l)
        .accessibilityElement(children: .combine)
    }

    private var revision: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.m) {
                VStack(alignment: .leading, spacing: Espaciado.xxs) {
                    Text("Revisa antes de guardar")
                        .font(Font.app.titulo2)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .accessibilityAddTraits(.isHeader)
                    Text("Corrige lo que haga falta y desmarca lo que no sea una vacuna.")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                    Label(viewModel.textoMetodo, systemImage: viewModel.metodo == .appleIntelligence ? "sparkles" : "text.viewfinder")
                        .font(Font.app.etiqueta)
                        .foregroundStyle(Color.app.saludTexto)
                        .padding(.top, Espaciado.xxs)
                }
                ForEach($viewModel.borradores) { $borrador in
                    TarjetaBorrador(borrador: $borrador)
                }
                Button("Escanear otra vez", systemImage: "arrow.counterclockwise") {
                    seleccion = nil
                    paginas = []
                    viewModel.reintentar()
                }
                .font(Font.app.subtitulo.weight(.semibold))
                .foregroundStyle(Color.app.primarioTinte)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.m)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            BotonPrincipal(tituloGuardar, icono: "checkmark") {
                if viewModel.guardar() { cerrar() }
            }
            .disabled(viewModel.cantidadPorGuardar == 0)
            .contentTransition(.numericText(value: Double(viewModel.cantidadPorGuardar)))
            .animation(Animation.app.resorte, value: viewModel.cantidadPorGuardar)
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.s)
            .background(Color.app.fondo)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.app.borde).frame(height: 1)
            }
        }
    }

    private var tituloGuardar: String {
        switch viewModel.cantidadPorGuardar {
        case 0: "Marca al menos una vacuna"
        case 1: "Guardar 1 vacuna"
        default: "Guardar \(viewModel.cantidadPorGuardar) vacunas"
        }
    }

    private func aviso(icono: String, titulo: String, mensaje: String) -> some View {
        EstadoVacio(icono: icono, titulo: titulo, mensaje: mensaje, tituloAccion: "Intentar de nuevo") {
            seleccion = nil
            paginas = []
            viewModel.reintentar()
        }
        .padding(.horizontal, Espaciado.margenPantalla)
    }
}

/// Una vacuna detectada: se puede corregir el nombre y las fechas, o descartarla.
private struct TarjetaBorrador: View {
    @Binding var borrador: EscaneoCartillaViewModel.Borrador

    var body: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.s) {
                HStack(spacing: Espaciado.s) {
                    Button {
                        borrador.incluir.toggle()
                    } label: {
                        Image(systemName: borrador.incluir ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(borrador.incluir ? Color.app.saludTexto : Color.app.textoSecundario)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(borrador.incluir ? "Incluida" : "Descartada")
                    .accessibilityHint("Toca para cambiar")
                    TextField("Nombre de la vacuna", text: $borrador.nombre)
                        .font(Font.app.cuerpoDestacado)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .padding(Espaciado.s)
                        .background(Color.app.superficieElevada, in: Forma.chip)
                }
                if borrador.incluir {
                    VStack(alignment: .leading, spacing: Espaciado.xs) {
                        DatePicker("Aplicada", selection: $borrador.fechaAplicacion, in: ...Date.now, displayedComponents: .date)
                        if borrador.fechaPorRevisar {
                            Label("No leímos bien esta fecha. Revísala.", systemImage: "exclamationmark.circle.fill")
                                .font(Font.app.nota)
                                .foregroundStyle(Color.app.acentoTexto)
                        }
                        Toggle("Próxima dosis", isOn: $borrador.tieneProximaDosis)
                            .tint(Color.app.salud)
                        if borrador.tieneProximaDosis {
                            DatePicker("Fecha", selection: $borrador.proximaDosis, displayedComponents: .date)
                        }
                    }
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoPrincipal)
                    .transition(.opacity)
                }
            }
        }
        .opacity(borrador.incluir ? 1 : 0.6)
        .animation(Animation.app.suave, value: borrador.incluir)
        .animation(Animation.app.suave, value: borrador.tieneProximaDosis)
        .sensoryFeedback(.selection, trigger: borrador.incluir)
    }
}

#Preview("Inicio · Claro") {
    if let detalle = VistaPrevia.detalleFirulais() {
        EscaneoCartillaView(viewModel: detalle.nuevoEscaneo())
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Revisión · Oscuro") {
    if let escaneo = VistaPrevia.escaneoEnRevision() {
        EscaneoCartillaView(viewModel: escaneo)
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
