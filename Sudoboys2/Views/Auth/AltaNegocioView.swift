import MapKit
import PhotosUI
import SwiftUI

/// Alta de negocio: tipo, especies, ubicación y cédula si es veterinaria.
struct AltaNegocioView: View {
    @Bindable var viewModel: AltaNegocioViewModel

    private var hayError: Binding<Bool> {
        Binding(
            get: { viewModel.mensajeError != nil },
            set: { if !$0 { viewModel.mensajeError = nil } }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.xl) {
                VStack(alignment: .leading, spacing: Espaciado.xs) {
                    Text("Registra tu negocio")
                        .font(Font.app.tituloGrande)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .accessibilityAddTraits(.isHeader)
                    Text("Con estos datos apareces en el mapa de los tutores.")
                        .font(Font.app.cuerpo)
                        .foregroundStyle(Color.app.textoSecundario)
                }

                seccion("Tu negocio") {
                    CampoTexto("Nombre del negocio", marcador: "Ej. Veterinaria San Ángel", texto: $viewModel.nombre)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                    Picker("Tipo de negocio", selection: $viewModel.tipo) {
                        ForEach(TipoNegocio.allCases, id: \.self) { tipo in
                            Text(tipo.tituloCorto).tag(tipo)
                        }
                    }
                    .pickerStyle(.segmented)
                    .sensoryFeedback(.selection, trigger: viewModel.tipo)
                }

                seccion("Especies que atiendes") {
                    HStack(spacing: Espaciado.xs) {
                        ForEach(Especie.allCases, id: \.self) { especie in
                            ChipFiltro(
                                especie.tituloPlural,
                                icono: especie.icono,
                                seleccionado: viewModel.especies.contains(especie)
                            ) {
                                viewModel.alternar(especie)
                            }
                        }
                    }
                }

                seccion("Ubicación") {
                    CampoTexto(
                        "Dirección",
                        marcador: "Calle, número y colonia",
                        icono: "mappin.and.ellipse",
                        texto: $viewModel.direccion
                    )
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    SelectorUbicacion(latitud: $viewModel.latitud, longitud: $viewModel.longitud)
                }

                if viewModel.requiereCedula {
                    seccion("Cédula profesional") {
                        CampoTexto(
                            "Número de cédula",
                            marcador: "7 u 8 dígitos",
                            icono: "checkmark.seal.fill",
                            texto: $viewModel.cedula
                        )
                        .keyboardType(.numberPad)
                        SelectorFotoCedula(foto: $viewModel.fotoCedula)
                        Text("Revisamos tu cédula antes de mostrar la insignia \"Cédula verificada\".")
                            .font(Font.app.nota)
                            .foregroundStyle(Color.app.textoSecundario)
                    }
                    .transition(.opacity)
                }

                VStack(spacing: Espaciado.xs) {
                    BotonPrincipal("Registrar negocio", icono: "checkmark.circle.fill", cargando: viewModel.guardando) {
                        viewModel.guardar()
                    }
                    .disabled(!viewModel.puedeGuardar)
                    if let ayuda = viewModel.ayuda {
                        Text(ayuda)
                            .font(Font.app.nota)
                            .foregroundStyle(Color.app.textoSecundario)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.l)
            .animation(Animation.app.suave, value: viewModel.requiereCedula)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.app.fondo)
        .navigationBarTitleDisplayMode(.inline)
        .alert("No se pudo guardar", isPresented: hayError) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(viewModel.mensajeError ?? "")
        }
    }

    private func seccion(_ titulo: String, @ViewBuilder contenido: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion(titulo)
            contenido()
        }
    }
}

/// Vista previa fija de la ubicación; el pin se ajusta en una hoja aparte
/// para que el mapa no robe el gesto de desplazar el formulario.
private struct SelectorUbicacion: View {
    @Binding var latitud: Double
    @Binding var longitud: Double
    @State private var ajustando = false

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitud, longitude: longitud),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )
    }

    var body: some View {
        Button {
            ajustando = true
        } label: {
            Map(position: .constant(.region(region)), interactionModes: []) {
                Marker("Tu negocio", systemImage: "pawprint.fill", coordinate: region.center)
                    .tint(Color.app.acentoTexto)
            }
            .allowsHitTesting(false)
            .frame(height: 180)
            .clipShape(Forma.tarjeta)
            .overlay(alignment: .bottomTrailing) {
                Label("Ajustar pin", systemImage: "hand.draw.fill")
                    .font(Font.app.subtitulo.weight(.semibold))
                    .foregroundStyle(Color.app.textoPrincipal)
                    .padding(.horizontal, Espaciado.s)
                    .padding(.vertical, Espaciado.xs)
                    .glassEffect()
                    .padding(Espaciado.s)
            }
            .overlay {
                Forma.tarjeta.strokeBorder(Color.app.borde, lineWidth: 1)
            }
            // El mapa no recibe toques; toda la tarjeta es el área del botón.
            .contentShape(Forma.tarjeta)
        }
        .buttonStyle(.presionable)
        .accessibilityLabel("Ubicación en el mapa")
        .accessibilityHint("Abre el mapa para ajustar el pin")
        .sheet(isPresented: $ajustando) {
            AjustarUbicacionView(latitud: $latitud, longitud: $longitud)
        }
    }
}

/// Mapa a pantalla completa con un pin fijo al centro: la ubicación es el centro del mapa.
private struct AjustarUbicacionView: View {
    @Binding var latitud: Double
    @Binding var longitud: Double
    @Environment(\.dismiss) private var cerrar
    @State private var posicion: MapCameraPosition
    @State private var centro: CLLocationCoordinate2D

    init(latitud: Binding<Double>, longitud: Binding<Double>) {
        _latitud = latitud
        _longitud = longitud
        // Semilla de una sola vez: dentro de la hoja el mapa manda sobre las coordenadas.
        let inicio = CLLocationCoordinate2D(latitude: latitud.wrappedValue, longitude: longitud.wrappedValue)
        _centro = State(initialValue: inicio)
        _posicion = State(initialValue: .region(MKCoordinateRegion(
            center: inicio,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )))
    }

    var body: some View {
        NavigationStack {
            Map(position: $posicion)
                .onMapCameraChange(frequency: .onEnd) { contexto in
                    centro = contexto.region.center
                }
                .overlay {
                    Image(systemName: "mappin")
                        .font(.largeTitle)
                        .foregroundStyle(Color.app.acentoTexto)
                        .offset(y: -16)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .safeAreaInset(edge: .bottom) {
                    BotonPrincipal("Usar esta ubicación", icono: "checkmark.circle.fill") {
                        latitud = centro.latitude
                        longitud = centro.longitude
                        cerrar()
                    }
                    .padding(Espaciado.margenPantalla)
                }
                .navigationTitle("Mueve el mapa bajo el pin")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { cerrar() }
                    }
                }
        }
    }
}

/// Elegir la foto de la cédula desde la fototeca (no pide permisos).
private struct SelectorFotoCedula: View {
    @Binding var foto: Data?
    @State private var seleccion: PhotosPickerItem?

    private var lista: Bool { foto != nil }

    var body: some View {
        PhotosPicker(selection: $seleccion, matching: .images) {
            HStack(spacing: Espaciado.s) {
                Image(systemName: lista ? "checkmark.circle.fill" : "camera.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(lista ? Color.app.saludTexto : Color.app.primarioTinte)
                    .accessibilityHidden(true)
                Text(lista ? "Foto de la cédula lista" : "Subir foto de la cédula")
                    .font(Font.app.cuerpoDestacado)
                    .foregroundStyle(Color.app.textoPrincipal)
                Spacer(minLength: 0)
                Text(lista ? "Cambiar" : "Elegir")
                    .font(Font.app.subtitulo.weight(.semibold))
                    .foregroundStyle(Color.app.primarioTinte)
            }
            .padding(Espaciado.m)
            .background(Color.app.superficieElevada, in: Forma.control)
        }
        .buttonStyle(.presionable)
        .sensoryFeedback(.success, trigger: lista) { _, ahora in ahora }
        .task(id: seleccion) {
            guard let seleccion else { return }
            if let datos = try? await seleccion.loadTransferable(type: Data.self) {
                foto = datos
            }
        }
    }
}

#Preview("Claro") {
    NavigationStack {
        AltaNegocioView(viewModel: VistaPrevia.inicioSesion().altaNegocio)
    }
    .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    NavigationStack {
        AltaNegocioView(viewModel: VistaPrevia.inicioSesion().altaNegocio)
    }
    .preferredColorScheme(.dark)
}
