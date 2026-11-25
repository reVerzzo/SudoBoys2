import SwiftUI

/// Mis mascotas: una tarjeta por mascota, con zoom al detalle.
struct MisMascotasView: View {
    @Bindable var viewModel: MisMascotasViewModel
    @Namespace private var zoom
    @State private var formulario: FormularioMascotaViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.mascotas.isEmpty {
                    EstadoVacio(
                        icono: "pawprint.fill",
                        titulo: "Aún no hay mascotas",
                        mensaje: "Agrega a tu mascota para tener su tarjeta, su QR y su cartilla siempre a la mano.",
                        tituloAccion: "Agregar mascota"
                    ) {
                        formulario = viewModel.formularioNuevaMascota()
                    }
                    .padding(.top, Espaciado.xl)
                } else {
                    LazyVStack(spacing: Espaciado.m) {
                        ForEach(viewModel.mascotas) { mascota in
                            NavigationLink(value: mascota.id) {
                                TarjetaMascota(mascota: mascota)
                            }
                            .buttonStyle(.presionable)
                            .matchedTransitionSource(id: mascota.id, in: zoom)
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
            .background(Color.app.fondo)
            .navigationTitle("Mis mascotas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Agregar mascota", systemImage: "plus") {
                        formulario = viewModel.formularioNuevaMascota()
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let detalle = viewModel.detalle(para: id) {
                    DetalleMascotaView(viewModel: detalle)
                        .navigationTransition(.zoom(sourceID: id, in: zoom))
                }
            }
            .sheet(item: $formulario) { formulario in
                FormularioMascotaView(viewModel: formulario)
            }
            .animation(Animation.app.resorte, value: viewModel.mascotas.count)
            .sensoryFeedback(.success, trigger: viewModel.mascotas.count) { antes, ahora in ahora > antes }
            .task { viewModel.cargar() }
        }
    }
}

#Preview("Claro") {
    MisMascotasView(viewModel: VistaPrevia.misMascotas())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    MisMascotasView(viewModel: VistaPrevia.misMascotas())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
