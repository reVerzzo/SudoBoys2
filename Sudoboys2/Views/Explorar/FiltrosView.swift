import SwiftUI

/// Hoja de filtros de Explorar. Los cambios se aplican al momento y el contador se actualiza.
struct FiltrosView: View {
    @Bindable var viewModel: ExplorarViewModel
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.l) {
                    seccion("Servicio") {
                        ForEach(ExplorarViewModel.OpcionServicio.allCases, id: \.self) { opcion in
                            ChipFiltro(opcion.titulo, icono: opcion.icono, seleccionado: viewModel.servicio == opcion) {
                                viewModel.servicio = opcion
                            }
                        }
                    }
                    seccion("Especie") {
                        ForEach(Especie.allCases, id: \.self) { especie in
                            ChipFiltro(
                                especie.tituloPlural,
                                icono: especie.icono,
                                seleccionado: viewModel.filtro.especie == especie
                            ) {
                                viewModel.alternar(especie)
                            }
                        }
                    }
                    seccion("Confianza y horario") {
                        ChipFiltro(
                            "Verificado",
                            icono: "checkmark.seal.fill",
                            seleccionado: viewModel.filtro.soloVerificados
                        ) {
                            viewModel.filtro.soloVerificados.toggle()
                        }
                        ChipFiltro(
                            "Disponible hoy",
                            icono: "calendar",
                            seleccionado: viewModel.filtro.disponibleHoy
                        ) {
                            viewModel.filtro.disponibleHoy.toggle()
                        }
                        ChipFiltro(
                            "Abierto ahora",
                            icono: "clock.fill",
                            seleccionado: viewModel.filtro.abiertoAhora
                        ) {
                            viewModel.filtro.abiertoAhora.toggle()
                        }
                    }
                    seccion("Calificación") {
                        ForEach(ExplorarViewModel.calificacionesMinimas, id: \.self) { minima in
                            ChipFiltro(
                                "\(minima.formatted(.number.precision(.fractionLength(1)))) o más",
                                icono: "star.fill",
                                seleccionado: viewModel.filtro.calificacionMinima == minima
                            ) {
                                viewModel.alternarCalificacion(minima)
                            }
                        }
                    }
                    seccion("Distancia desde \(ExplorarViewModel.nombreReferencia)") {
                        ForEach(ExplorarViewModel.distanciasMaximasKm, id: \.self) { maxima in
                            ChipFiltro(
                                "Hasta \(Int(maxima)) km",
                                icono: "location.fill",
                                seleccionado: viewModel.distanciaMaximaKm == maxima
                            ) {
                                viewModel.alternarDistancia(maxima)
                            }
                        }
                    }
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.m)
            }
            .background(Color.app.fondo)
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Limpiar") { viewModel.limpiarFiltros() }
                        .disabled(viewModel.filtrosActivos == 0)
                }
            }
            .safeAreaInset(edge: .bottom) {
                barraDeResultados
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var barraDeResultados: some View {
        HStack(spacing: Espaciado.m) {
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.resultados.count, format: .number)
                    .font(Font.app.titulo)
                    .foregroundStyle(Color.app.textoPrincipal)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(viewModel.resultados.count)))
                Text(viewModel.resultados.count == 1 ? "negocio" : "negocios")
                    .font(Font.app.nota)
                    .foregroundStyle(Color.app.textoSecundario)
            }
            .animation(Animation.app.resorte, value: viewModel.resultados.count)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(viewModel.resultados.count) negocios")

            BotonPrincipal("Ver resultados") { cerrar() }
        }
        .padding(.horizontal, Espaciado.margenPantalla)
        .padding(.vertical, Espaciado.s)
        .background(Color.app.superficie)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.app.borde).frame(height: 1)
        }
    }

    private func seccion(_ titulo: String, @ViewBuilder chips: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            Text(titulo)
                .font(Font.app.encabezado)
                .foregroundStyle(Color.app.textoPrincipal)
                .accessibilityAddTraits(.isHeader)
            FilaDeChips() { chips() }
        }
    }
}

/// Acomoda los chips en renglones, pasando al siguiente cuando no caben.
private struct FilaDeChips: Layout {
    var espacio: CGFloat = Espaciado.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let renglones = acomodar(ancho: proposal.width ?? .infinity, subviews: subviews)
        let alto = renglones.last.map { $0.y + $0.alto } ?? 0
        let ancho = renglones.map(\.ancho).max() ?? 0
        return CGSize(width: proposal.width ?? ancho, height: alto)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for renglon in acomodar(ancho: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for indice in renglon.indices {
                let medida = subviews[indice].sizeThatFits(.unspecified)
                subviews[indice].place(
                    at: CGPoint(x: x, y: bounds.minY + renglon.y),
                    proposal: ProposedViewSize(medida)
                )
                x += medida.width + espacio
            }
        }
    }

    private struct Renglon {
        var indices: [Int] = []
        var y: CGFloat = 0
        var alto: CGFloat = 0
        var ancho: CGFloat = 0
    }

    private func acomodar(ancho: CGFloat, subviews: Subviews) -> [Renglon] {
        var renglones: [Renglon] = []
        var actual = Renglon()
        for indice in subviews.indices {
            let medida = subviews[indice].sizeThatFits(.unspecified)
            let anchoNuevo = actual.indices.isEmpty ? medida.width : actual.ancho + espacio + medida.width
            if anchoNuevo > ancho, !actual.indices.isEmpty {
                renglones.append(actual)
                actual = Renglon(y: actual.y + actual.alto + espacio)
                actual.indices = [indice]
                actual.ancho = medida.width
                actual.alto = medida.height
            } else {
                actual.indices.append(indice)
                actual.ancho = anchoNuevo
                actual.alto = max(actual.alto, medida.height)
            }
        }
        if !actual.indices.isEmpty { renglones.append(actual) }
        return renglones
    }
}

#Preview("Claro") {
    Color.app.fondo
        .sheet(isPresented: .constant(true)) {
            FiltrosView(viewModel: VistaPrevia.explorar())
        }
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    Color.app.fondo
        .sheet(isPresented: .constant(true)) {
            FiltrosView(viewModel: VistaPrevia.explorar())
        }
        .preferredColorScheme(.dark)
}
