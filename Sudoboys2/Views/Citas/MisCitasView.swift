import SwiftUI

/// Citas del tutor: seguimiento de etapas en vivo e historial.
struct MisCitasView: View {
    @Bindable var viewModel: MisCitasViewModel
    @State private var porCancelar: Cita?

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.activas.isEmpty && viewModel.anteriores.isEmpty {
                    EstadoVacio(
                        icono: "calendar",
                        titulo: "Aún no tienes citas",
                        mensaje: "Busca una veterinaria o estética en Explorar y reserva en un par de toques."
                    )
                    .padding(.top, Espaciado.xl)
                } else {
                    LazyVStack(alignment: .leading, spacing: Espaciado.m) {
                        if !viewModel.activas.isEmpty {
                            EncabezadoSeccion("Próximas")
                            ForEach(viewModel.activas) { cita in
                                TarjetaCita(cita: cita)
                                    .contextMenu {
                                        if cita.estado == .programada {
                                            Button("Cancelar cita", systemImage: "xmark.circle", role: .destructive) {
                                                porCancelar = cita
                                            }
                                        }
                                    }
                            }
                        }
                        if !viewModel.anteriores.isEmpty {
                            EncabezadoSeccion("Anteriores")
                                .padding(.top, Espaciado.xs)
                            ForEach(viewModel.anteriores) { cita in
                                VStack(spacing: Espaciado.xs) {
                                    TarjetaCita(cita: cita)
                                    if let foto = cita.fotoFinal, let imagen = UIImage(data: foto) {
                                        Image(uiImage: imagen)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 180)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(Forma.tarjeta)
                                            .accessibilityLabel("Foto final de \(cita.nombreMascota)")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Espaciado.margenPantalla)
                    .padding(.vertical, Espaciado.s)
                }
            }
            .background(Color.app.fondo)
            .navigationTitle("Citas")
            .confirmationDialog(
                "¿Cancelar esta cita?",
                isPresented: Binding(get: { porCancelar != nil }, set: { if !$0 { porCancelar = nil } }),
                titleVisibility: .visible
            ) {
                Button("Cancelar cita", role: .destructive) {
                    if let porCancelar { viewModel.cancelar(porCancelar) }
                    porCancelar = nil
                }
                Button("Conservarla", role: .cancel) { porCancelar = nil }
            }
            .animation(Animation.app.resorte, value: viewModel.activas.count)
            .onAppear { viewModel.cargar() }
        }
    }
}

#Preview("Claro") {
    MisCitasView(viewModel: VistaPrevia.misCitas())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    MisCitasView(viewModel: VistaPrevia.misCitas())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
