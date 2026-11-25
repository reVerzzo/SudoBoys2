import SwiftUI

/// Ajustes: cuenta, apariencia, cambio rápido de rol demo y cerrar sesión.
struct AjustesView: View {
    @Bindable var viewModel: AjustesViewModel
    @State private var confirmandoRestablecer = false

    private var hayError: Binding<Bool> {
        Binding(
            get: { viewModel.mensajeError != nil },
            set: { if !$0 { viewModel.mensajeError = nil } }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.xl) {
                    if let usuario = viewModel.usuario {
                        TarjetaApp {
                            HStack(spacing: Espaciado.s) {
                                AvatarMascota(
                                    nombre: usuario.nombre,
                                    iconoRespaldo: usuario.rol == .tutor ? "person.fill" : "storefront.fill"
                                )
                                VStack(alignment: .leading, spacing: Espaciado.xxs) {
                                    Text(usuario.nombre)
                                        .font(Font.app.titulo3)
                                        .foregroundStyle(Color.app.textoPrincipal)
                                    Text(usuario.esDemo ? "Cuenta demo · \(usuario.rol.titulo)" : usuario.rol.titulo)
                                        .font(Font.app.subtitulo)
                                        .foregroundStyle(Color.app.textoSecundario)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        EncabezadoSeccion("Apariencia")
                        SelectorApariencia()
                    }

                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        EncabezadoSeccion("Cuenta")
                        BotonAcento(viewModel.tituloCambioDeRol, icono: viewModel.iconoCambioDeRol) {
                            viewModel.cambiarACuentaDemoDelOtroRol()
                        }
                        Text("Prueba los dos lados de la app en este mismo iPhone.")
                            .font(Font.app.nota)
                            .foregroundStyle(Color.app.textoSecundario)
                        BotonSecundario("Cerrar sesión", icono: "rectangle.portrait.and.arrow.right") {
                            viewModel.cerrarSesion()
                        }
                        .padding(.top, Espaciado.xs)
                    }

                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        EncabezadoSeccion("Presentación")
                        TarjetaApp {
                            Toggle(isOn: $viewModel.modoDemo) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Modo demo")
                                        .font(Font.app.cuerpoDestacado)
                                        .foregroundStyle(Color.app.textoPrincipal)
                                    Text("El primer recordatorio de dosis llega 1 minuto después de emitir la receta.")
                                        .font(Font.app.nota)
                                        .foregroundStyle(Color.app.textoSecundario)
                                }
                            }
                            .tint(Color.app.salud)
                            .sensoryFeedback(.selection, trigger: viewModel.modoDemo)
                        }
                        BotonSecundario("Restablecer datos de demo", icono: "arrow.counterclockwise") {
                            confirmandoRestablecer = true
                        }
                        Text("Borra todo y vuelve a cargar los datos de ejemplo, con la cita de hoy de Mochi lista para el check-in.")
                            .font(Font.app.nota)
                            .foregroundStyle(Color.app.textoSecundario)
                    }

                    NavigationLink {
                        CatalogoDisenoView()
                    } label: {
                        Label("Catálogo de diseño", systemImage: "paintpalette.fill")
                            .font(Font.app.subtitulo.weight(.semibold))
                            .foregroundStyle(Color.app.primarioTinte)
                    }
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.l)
            }
            .background(Color.app.fondo)
            .navigationTitle("Ajustes")
            .confirmationDialog(
                "¿Restablecer los datos de demo?",
                isPresented: $confirmandoRestablecer,
                titleVisibility: .visible
            ) {
                Button("Borrar todo y restablecer", role: .destructive) {
                    Task { await viewModel.restablecerDatosDemo() }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se borran las citas, mascotas y recetas de este iPhone y vuelven los datos de ejemplo.")
            }
            .alert("Algo salió mal", isPresented: hayError) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(viewModel.mensajeError ?? "")
            }
        }
    }
}

#Preview("Tutor · Claro") {
    AjustesView(viewModel: VistaPrevia.ajustes(rol: .tutor))
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Negocio · Oscuro") {
    AjustesView(viewModel: VistaPrevia.ajustes(rol: .negocio))
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
