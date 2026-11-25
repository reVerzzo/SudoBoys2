import MapKit
import SwiftUI

/// Explorar: negocios en mapa o lista, con filtros y acceso al perfil.
struct ExplorarView: View {
    @Bindable var viewModel: ExplorarViewModel
    @Namespace private var zoom
    @State private var camara: MapCameraPosition = .region(ExplorarView.regionInicial)
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

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
            .sensoryFeedback(.selection, trigger: viewModel.modo)
            .sensoryFeedback(.selection, trigger: viewModel.idSeleccionado)
            .task { viewModel.cargar() }
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
                    PinSeleccionable(viewModel: viewModel, resultado: resultado)
                }
                .tag(resultado.id)
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .safeAreaInset(edge: .top) {
            ControlesExplorar(viewModel: viewModel, alCentrar: centrar)
        }
        // Superpuesta (no `safeAreaInset`) para que el mapa no se recorra al aparecer la tarjeta.
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
            ControlesExplorar(viewModel: viewModel, alCentrar: nil)
                .background(Color.app.fondo)
        }
    }
}

/// Pin del mapa. Lee la selección en su propio `body`: el contenido de una anotación
/// no se vuelve a dibujar cuando cambia el estado observado desde el `Map`.
private struct PinSeleccionable: View {
    let viewModel: ExplorarViewModel
    let resultado: ResultadoNegocio

    private var seleccionado: Bool { viewModel.idSeleccionado == resultado.id }

    var body: some View {
        Button {
            viewModel.idSeleccionado = resultado.id
        } label: {
            PinNegocio(
                tipo: resultado.negocio.tipo,
                verificado: resultado.negocio.estaVerificado,
                seleccionado: seleccionado
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(resultado.negocio.nombre), \(resultado.negocio.tipo.titulo)")
        .accessibilityAddTraits(seleccionado ? .isSelected : [])
    }
}

/// Controles flotantes de vidrio: filtros, contador de resultados, centrar y mapa/lista.
private struct ControlesExplorar: View {
    @Bindable var viewModel: ExplorarViewModel
    /// `nil` en la lista: no hay mapa que centrar.
    let alCentrar: (() -> Void)?

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
                    Text(viewModel.resultados.count == 1 ? "negocio" : "negocios")
                }
                .font(Font.app.subtitulo.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(Color.app.textoPrincipal)
                .padding(.horizontal, Espaciado.s)
                .frame(height: 44)
                .glassEffect(.regular, in: .capsule)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)

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
