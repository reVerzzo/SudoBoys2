import SwiftUI

/// Botones de entrada para el rol elegido: Google, Apple (próximamente) y cuenta demo.
struct InicioSesionView: View {
    @Bindable var viewModel: InicioSesionViewModel
    let rol: RolUsuario

    private var titulo: String {
        switch rol {
        case .tutor: "Soy tutor"
        case .negocio: "Soy estética o veterinaria"
        }
    }

    private var detalle: String {
        switch rol {
        case .tutor: "Entra para reservar citas y llevar la cartilla de tus mascotas."
        case .negocio: "Entra para ver tu agenda y atender a tus pacientes."
        }
    }

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
                    Text(titulo)
                        .font(Font.app.tituloGrande)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .accessibilityAddTraits(.isHeader)
                    Text(detalle)
                        .font(Font.app.cuerpo)
                        .foregroundStyle(Color.app.textoSecundario)
                }

                VStack(spacing: Espaciado.s) {
                    BotonSecundario(
                        "Continuar con Google",
                        icono: "g.circle.fill",
                        cargando: viewModel.cargandoGoogle
                    ) {
                        Task { await viewModel.entrarConGoogle(rol: rol) }
                    }

                    VStack(spacing: Espaciado.xxs) {
                        BotonSecundario("Continuar con Apple", icono: "apple.logo") {}
                            .disabled(true)
                            .accessibilityHint("Disponible próximamente")
                        Text("Disponible próximamente")
                            .font(Font.app.nota)
                            .foregroundStyle(Color.app.textoSecundario)
                            .accessibilityHidden(true)
                    }

                    separador

                    BotonPrincipal("Entrar con cuenta demo", icono: "sparkles") {
                        viewModel.entrarConDemo(rol: rol)
                    }
                    Text("Funciona sin internet, con datos de ejemplo.")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }

                if rol == .negocio {
                    TarjetaApp {
                        VStack(alignment: .leading, spacing: Espaciado.s) {
                            Text("¿Tu negocio es nuevo aquí?")
                                .font(Font.app.encabezado)
                                .foregroundStyle(Color.app.textoPrincipal)
                            Text("Regístralo con su tipo, especies, ubicación y cédula si es veterinaria.")
                                .font(Font.app.subtitulo)
                                .foregroundStyle(Color.app.textoSecundario)
                            BotonAcento("Registrar mi negocio", icono: "plus.circle.fill") {
                                viewModel.registrarNegocio()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.l)
        }
        .background(Color.app.fondo)
        .navigationBarTitleDisplayMode(.inline)
        .alert("No se pudo iniciar sesión", isPresented: hayError) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(viewModel.mensajeError ?? "")
        }
    }

    private var separador: some View {
        HStack(spacing: Espaciado.s) {
            Rectangle().fill(Color.app.borde).frame(height: 1)
            Text("o")
                .font(Font.app.nota)
                .foregroundStyle(Color.app.textoSecundario)
            Rectangle().fill(Color.app.borde).frame(height: 1)
        }
        .padding(.vertical, Espaciado.xxs)
        .accessibilityHidden(true)
    }
}

#Preview("Tutor · Claro") {
    NavigationStack {
        InicioSesionView(viewModel: VistaPrevia.inicioSesion(), rol: .tutor)
    }
    .preferredColorScheme(.light)
}

#Preview("Negocio · Oscuro") {
    NavigationStack {
        InicioSesionView(viewModel: VistaPrevia.inicioSesion(), rol: .negocio)
    }
    .preferredColorScheme(.dark)
}
