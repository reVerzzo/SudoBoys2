import SwiftUI

/// Perfil del negocio de la sesión: datos básicos y estado de verificación.
struct PerfilNegocioPropioView: View {
    let negocio: Negocio

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.l) {
                    TarjetaApp {
                        VStack(alignment: .leading, spacing: Espaciado.s) {
                            HStack(alignment: .top, spacing: Espaciado.s) {
                                AvatarMascota(nombre: negocio.nombre, iconoRespaldo: negocio.tipo.icono)
                                VStack(alignment: .leading, spacing: Espaciado.xxs) {
                                    Text(negocio.nombre)
                                        .font(Font.app.titulo3)
                                        .foregroundStyle(Color.app.textoPrincipal)
                                    Text(negocio.tipo.titulo)
                                        .font(Font.app.subtitulo)
                                        .foregroundStyle(Color.app.textoSecundario)
                                    if negocio.calificacion > 0 {
                                        Calificacion(negocio.calificacion, resenas: negocio.resenas.count)
                                    }
                                }
                            }
                            verificacion
                        }
                    }

                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        EncabezadoSeccion("Datos")
                        TarjetaApp {
                            VStack(alignment: .leading, spacing: Espaciado.s) {
                                Label(negocio.direccion, systemImage: "mappin.and.ellipse")
                                Label(negocio.horarioTexto, systemImage: "clock.fill")
                                Label(
                                    negocio.especiesAtendidas.map(\.tituloPlural).listaEnEspanol,
                                    systemImage: "pawprint.fill"
                                )
                            }
                            .font(Font.app.cuerpo)
                            .foregroundStyle(Color.app.textoPrincipal)
                        }
                    }

                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        EncabezadoSeccion("Servicios")
                        if negocio.servicios.isEmpty {
                            TarjetaApp {
                                Label("Aún no agregas servicios ni precios.", systemImage: "tag")
                                    .font(Font.app.subtitulo)
                                    .foregroundStyle(Color.app.textoSecundario)
                            }
                        } else {
                            TarjetaApp {
                                VStack(spacing: Espaciado.s) {
                                    ForEach(negocio.servicios.sorted { $0.nombre < $1.nombre }) { servicio in
                                        HStack {
                                            Label(servicio.nombre, systemImage: servicio.tipo.icono)
                                                .foregroundStyle(Color.app.textoPrincipal)
                                            Spacer(minLength: Espaciado.xs)
                                            Text(servicio.precio, format: .currency(code: "MXN").precision(.fractionLength(0)))
                                                .foregroundStyle(Color.app.textoSecundario)
                                                .monospacedDigit()
                                        }
                                        .font(Font.app.cuerpo)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.l)
            }
            .background(Color.app.fondo)
            .navigationTitle("Perfil")
        }
    }

    @ViewBuilder
    private var verificacion: some View {
        switch negocio.insignia {
        case .cedulaVerificada:
            InsigniaVerificado(.cedula)
        case .negocioVerificado:
            InsigniaVerificado(.negocio)
        case nil:
            Label(
                negocio.estadoVerificacion == .enRevision ? "Cédula en revisión" : "Verificación pendiente",
                systemImage: negocio.estadoVerificacion == .enRevision ? "hourglass" : "exclamationmark.circle"
            )
            .font(Font.app.etiqueta)
            .foregroundStyle(Color.app.acentoTexto)
        }
    }
}

#Preview("Claro") {
    if let negocio = VistaPrevia.appState(rol: .negocio).negocioActual {
        PerfilNegocioPropioView(negocio: negocio)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let negocio = VistaPrevia.appState(rol: .negocio).negocioActual {
        PerfilNegocioPropioView(negocio: negocio)
            .preferredColorScheme(.dark)
    }
}
