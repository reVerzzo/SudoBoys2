import SwiftUI

/// Ajustes: cuenta, apariencia, cambio rápido de rol demo y cerrar sesión.
struct AjustesView: View {
    @Bindable var viewModel: AjustesViewModel

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
            .alert("No se pudo cambiar de cuenta", isPresented: hayError) {
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
