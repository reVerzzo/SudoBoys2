import MapKit
import SwiftUI

/// Explorar: negocios en mapa o lista, con filtros y acceso al perfil.
struct ExplorarView: View {
    @Bindable var viewModel: ExplorarViewModel
    @Namespace private var zoom
    @State private var camara: MapCameraPosition = .region(ExplorarView.regionInicial)
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @Environment(AppState.self) private var appState: AppState?
    @Environment(\.repositorios) private var repositorios
    @Environment(\.serviciosCitas) private var serviciosCitas
    @State private var urgencia: UrgenciaViewModel?

    /// Sur de la Ciudad de México: Coyoacán, CU y Tlalpan.
    private static let regionInicial = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.3180, longitude: -99.1640),
        span: MKCoordinateSpan(latitudeDelta: 0.115, longitudeDelta: 0.115)
    )

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.modo {
                case .mapa:
                    mapa.transition(.opacity)
                case .lista:
                    lista.transition(.opacity)
                }
            }
            .animation(Animation.app.suave, value: viewModel.modo)
            .background(Color.app.fondo)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let perfil = viewModel.perfil(para: id) {
                    PerfilNegocioView(viewModel: perfil)
                        .navigationTransition(.zoom(sourceID: id, in: zoom))
                }
            }
            .sheet(isPresented: $viewModel.mostrandoFiltros) {
                FiltrosView(viewModel: viewModel)
            }
            .sheet(item: $urgencia) { urgencia in
                UrgenciaView(viewModel: urgencia)
            }
            .sensoryFeedback(.selection, trigger: viewModel.modo)
            .sensoryFeedback(.selection, trigger: viewModel.idSeleccionado)
            .task {
                viewModel.pedirUbicacion()
                viewModel.cargar()
            }
            // Al llegar la ubicación real, las distancias se vuelven a medir desde ahí.
            .onChange(of: viewModel.origen) { viewModel.cargar() }
        }
    }

    // MARK: - Mapa

    private var mapa: some View {
        Map(position: $camara, selection: $viewModel.idSeleccionado) {
            ForEach(viewModel.resultados) { resultado in
                Annotation(
                    resultado.negocio.nombre,
                    coordinate: CLLocationCoordinate2D(
                        latitude: resultado.negocio.latitud,
                        longitude: resultado.negocio.longitud
                    ),
                    anchor: .bottom
                ) {
                    PinSeleccionable(
                        viewModel: viewModel,
                        id: resultado.id,
                        nombre: resultado.negocio.nombre,
                        tipo: resultado.negocio.tipo,
                        verificado: resultado.negocio.estaVerificado
                    )
                }
                .tag(resultado.id)
                .annotationTitles(.hidden)
            }
            UserAnnotation()
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        // Color del punto del usuario: durazno, para que no se confunda con los pines.
        .tint(Color.app.acento)
        .safeAreaInset(edge: .top) {
            ControlesExplorar(viewModel: viewModel, alCentrar: centrar, alIrAMiUbicacion: irAMiUbicacion)
        }
        // Superpuesta (no `safeAreaInset`) para que el mapa no se recorra al aparecer la tarjeta.
        .overlay(alignment: .bottom) {
            if viewModel.seleccionado == nil {
                botonUrgencia
                    .padding(.bottom, Espaciado.s)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if let seleccionado = viewModel.seleccionado {
                NavigationLink(value: seleccionado.id) {
                    TarjetaNegocio(resultado: seleccionado, ahora: viewModel.ahora)
                }
                .buttonStyle(.presionable)
                .matchedTransitionSource(id: seleccionado.id, in: zoom)
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.bottom, Espaciado.s)
                .id(seleccionado.id)
                .transition(reducirMovimiento ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Animation.app.resorte, value: viewModel.idSeleccionado)
    }

    private var botonUrgencia: some View {
        Button {
            abrirUrgencia()
        } label: {
            Label("Urgencia", systemImage: "cross.case.fill")
                .font(Font.app.encabezado)
                .foregroundStyle(Color.app.acentoTexto)
                .padding(.horizontal, Espaciado.l)
                .frame(minHeight: 52)
                .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.presionable)
        .accessibilityHint("Avisa a una veterinaria abierta ahora que vas en camino")
    }

    private func abrirUrgencia() {
        guard let repositorios else { return }
        urgencia = UrgenciaViewModel(
            tutor: appState?.usuarioActual,
            origen: viewModel.origen,
            negocios: repositorios.negocios,
            citas: repositorios.citas,
            mascotas: repositorios.mascotas,
            servicios: serviciosCitas ?? ServiciosCitas()
        )
    }

    /// Centra el mapa en el usuario; sin ubicación, en el punto de respaldo.
    private func irAMiUbicacion() {
        viewModel.pedirUbicacion()
        let punto = viewModel.origen
        withAnimation(Animation.app.suave) {
            camara = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: punto.latitud, longitude: punto.longitud),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))
        }
    }

    /// Encadra todos los resultados actuales.
    private func centrar() {
        let puntos = viewModel.resultados.map(\.negocio)
        guard let primero = puntos.first else { return }
        var minLat = primero.latitud, maxLat = primero.latitud
        var minLon = primero.longitud, maxLon = primero.longitud
        for negocio in puntos {
            minLat = min(minLat, negocio.latitud)
            maxLat = max(maxLat, negocio.latitud)
            minLon = min(minLon, negocio.longitud)
            maxLon = max(maxLon, negocio.longitud)
        }
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.02),
                longitudeDelta: max((maxLon - minLon) * 1.5, 0.02)
            )
        )
        withAnimation(Animation.app.suave) {
            camara = .region(region)
        }
    }

    // MARK: - Lista

    private var lista: some View {
        ScrollView {
            if viewModel.resultados.isEmpty {
                EstadoVacio(
                    icono: "magnifyingglass",
                    titulo: "Sin resultados",
                    mensaje: "Ningún negocio cumple todos los filtros. Prueba quitando alguno.",
                    tituloAccion: "Limpiar filtros"
                ) {
                    viewModel.limpiarFiltros()
                }
                .padding(.top, Espaciado.xl)
            } else {
                LazyVStack(spacing: Espaciado.m) {
                    ForEach(viewModel.resultados) { resultado in
                        NavigationLink(value: resultado.id) {
                            TarjetaNegocio(resultado: resultado, ahora: viewModel.ahora)
                        }
                        .buttonStyle(.presionable)
                        .matchedTransitionSource(id: resultado.id, in: zoom)
                        .scrollTransition { contenido, fase in
                            contenido
                                .opacity(fase.isIdentity ? 1 : 0.6)
                                .scaleEffect(fase.isIdentity ? 1 : 0.96)
                        }
                    }
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.s)
            }
        }
        .safeAreaInset(edge: .top) {
            // Fondo sólido: las tarjetas no pasan por detrás de los controles al desplazar.
            ControlesExplorar(viewModel: viewModel, alCentrar: nil, alIrAMiUbicacion: nil)
                .background(Color.app.fondo)
        }
        .safeAreaInset(edge: .bottom) {
            botonUrgencia.padding(.bottom, Espaciado.s)
        }
    }
}

/// Pin del mapa. Lee la selección en su propio `body`: el contenido de una anotación
/// no se vuelve a dibujar cuando cambia el estado observado desde el `Map`.
/// Recibe copias de los datos, no el `Negocio`: MapKit puede volver a medir un pin después
/// de que el modelo se borró (al restablecer los datos de demo) y leerlo tronaría la app.
private struct PinSeleccionable: View {
    let viewModel: ExplorarViewModel
    let id: UUID
    let nombre: String
    let tipo: TipoNegocio
    let verificado: Bool

    private var seleccionado: Bool { viewModel.idSeleccionado == id }

    var body: some View {
        Button {
            viewModel.idSeleccionado = id
        } label: {
            PinNegocio(tipo: tipo, verificado: verificado, seleccionado: seleccionado)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(nombre), \(tipo.titulo)")
        .accessibilityAddTraits(seleccionado ? .isSelected : [])
    }
}

/// Controles flotantes de vidrio: filtros, contador de resultados, centrar y mapa/lista.
private struct ControlesExplorar: View {
    @Bindable var viewModel: ExplorarViewModel
    /// `nil` en la lista: no hay mapa que centrar.
    let alCentrar: (() -> Void)?
    let alIrAMiUbicacion: (() -> Void)?

    private var enMapa: Bool { viewModel.modo == .mapa }

    var body: some View {
        GlassEffectContainer(spacing: Espaciado.xs) {
            HStack(spacing: Espaciado.xs) {
                Button {
                    viewModel.mostrandoFiltros = true
                } label: {
                    HStack(spacing: Espaciado.xxs) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filtros")
                            .lineLimit(1)
                            .fixedSize()
                        if viewModel.filtrosActivos > 0 {
                            Text(viewModel.filtrosActivos, format: .number)
                                .font(Font.app.etiqueta)
                                .monospacedDigit()
                                .contentTransition(.numericText(value: Double(viewModel.filtrosActivos)))
                                .foregroundStyle(Color.app.textoSobrePrimario)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Color.app.primario, in: Circle())
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .font(Font.app.subtitulo.weight(.semibold))
                    .foregroundStyle(Color.app.textoPrincipal)
                    .padding(.horizontal, Espaciado.m)
                    .frame(height: 44)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Filtros")
                .accessibilityValue(viewModel.filtrosActivos == 0 ? "Ninguno" : "\(viewModel.filtrosActivos) activos")

                HStack(spacing: Espaciado.xxs) {
                    Text(viewModel.resultados.count, format: .number)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(viewModel.resultados.count)))
                    // En el mapa van más botones: el contador se queda con el ícono.
                    if enMapa {
                        Image(systemName: "mappin.and.ellipse")
                    } else {
                        Text(viewModel.resultados.count == 1 ? "negocio" : "negocios")
                    }
                }
                .font(Font.app.subtitulo.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(Color.app.textoPrincipal)
                .padding(.horizontal, Espaciado.s)
                .frame(height: 44)
                .glassEffect(.regular, in: .capsule)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(viewModel.resultados.count) \(viewModel.resultados.count == 1 ? "negocio" : "negocios")")

                Spacer(minLength: 0)

                if let alIrAMiUbicacion {
                    BotonCircularDeVidrio(
                        icono: viewModel.ubicacionActual == nil ? "location" : "location.fill",
                        etiqueta: "Ir a mi ubicación",
                        accion: alIrAMiUbicacion
                    )
                }
                if let alCentrar {
                    BotonCircularDeVidrio(icono: "scope", etiqueta: "Mostrar todos en el mapa", accion: alCentrar)
                }
                BotonCircularDeVidrio(
                    icono: enMapa ? "list.bullet" : "map.fill",
                    etiqueta: enMapa ? "Ver lista" : "Ver mapa"
                ) {
                    viewModel.modo = enMapa ? .lista : .mapa
                }
            }
        }
        .animation(Animation.app.resorte, value: viewModel.filtrosActivos)
        .animation(Animation.app.resorte, value: viewModel.resultados.count)
        .padding(.horizontal, Espaciado.margenPantalla)
        .padding(.vertical, Espaciado.xs)
    }
}

private struct BotonCircularDeVidrio: View {
    let icono: String
    let etiqueta: String
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Image(systemName: icono)
                .contentTransition(.symbolEffect(.replace))
                .font(Font.app.cuerpoDestacado)
                .foregroundStyle(Color.app.textoPrincipal)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(etiqueta)
    }
}

#Preview("Mapa · Claro") {
    ExplorarView(viewModel: VistaPrevia.explorar())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Lista · Oscuro") {
    let viewModel = VistaPrevia.explorar()
    viewModel.modo = .lista
    return ExplorarView(viewModel: viewModel)
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
