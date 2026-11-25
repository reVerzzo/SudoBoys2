import SwiftUI

/// Perfil de un negocio para el tutor: confianza, servicios, reseñas y reservar.
struct PerfilNegocioView: View {
    let viewModel: PerfilNegocioViewModel

    @Environment(AppState.self) private var appState: AppState?
    @Environment(\.repositorios) private var repositorios
    @Environment(\.serviciosCitas) private var serviciosCitas
    @State private var reserva: ReservarViewModel?

    private var negocio: Negocio { viewModel.negocio }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.l) {
                encabezado
                datos
                servicios
                resenas
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.top, Espaciado.m)
            .padding(.bottom, Espaciado.l)
        }
        .barraAlDesplazar(titulo: negocio.nombre, umbral: 120)
        .background(alignment: .top) {
            FondoMalla()
                .frame(height: 320)
                .ignoresSafeArea()
        }
        .background(Color.app.fondo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            BotonPrincipal("Reservar", icono: "calendar.badge.plus") {
                abrirReserva()
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.s)
            .background(Color.app.fondo)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.app.borde).frame(height: 1)
            }
        }
        .sheet(item: $reserva) { reserva in
            ReservarView(viewModel: reserva)
        }
    }

    private func abrirReserva() {
        guard let repositorios else { return }
        reserva = ReservarViewModel(
            negocio: negocio,
            tutor: appState?.usuarioActual,
            citas: repositorios.citas,
            mascotas: repositorios.mascotas,
            servicios: serviciosCitas ?? ServiciosCitas()
        )
    }

    // MARK: - Secciones

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            Image(systemName: negocio.tipo.icono)
                .font(.title)
                .foregroundStyle(negocio.tipo.colorIcono)
                .frame(width: 72, height: 72)
                .background(negocio.tipo.colorFondo, in: Forma.tarjeta)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Espaciado.xxs) {
                Text(negocio.nombre)
                    .font(Font.app.titulo)
                    .foregroundStyle(Color.app.textoPrincipal)
                    .accessibilityAddTraits(.isHeader)
                Text(negocio.tipo.titulo)
                    .font(Font.app.cuerpo)
                    .foregroundStyle(Color.app.textoSecundario)
            }
            Calificacion(
                negocio.calificacion,
                resenas: viewModel.resenas.isEmpty ? nil : viewModel.resenas.count,
                estilo: .completa
            )
            verificacion
        }
    }

    @ViewBuilder
    private var verificacion: some View {
        switch negocio.insignia {
        case .cedulaVerificada:
            VStack(alignment: .leading, spacing: Espaciado.xxs) {
                InsigniaVerificado(.cedula)
                if let cedula = negocio.cedula {
                    Text("Cédula profesional \(cedula)")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            }
        case .negocioVerificado:
            InsigniaVerificado(.negocio)
        case nil:
            Label("Aún sin verificar", systemImage: "exclamationmark.circle")
                .font(Font.app.etiqueta)
                .foregroundStyle(Color.app.textoSecundario)
        }
    }

    private var datos: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.s) {
                fila("mappin.and.ellipse", negocio.direccion)
                fila(
                    "clock.fill",
                    "\(viewModel.estaAbierto ? "Abierto ahora" : "Cerrado ahora") · \(negocio.horarioTexto)",
                    color: viewModel.estaAbierto ? Color.app.saludTexto : Color.app.textoPrincipal
                )
                fila("calendar", viewModel.textoDisponibilidad)
                if let distancia = viewModel.distanciaKm {
                    fila("location.fill", "A \(distancia.distanciaLegible) de \(viewModel.nombreOrigen)")
                }
                fila("pawprint.fill", negocio.especiesAtendidas.map(\.tituloPlural).listaEnEspanol)
            }
        }
    }

    private func fila(_ icono: String, _ texto: String, color: Color = Color.app.textoPrincipal) -> some View {
        Label {
            Text(texto)
                .foregroundStyle(color)
        } icon: {
            Image(systemName: icono)
                .foregroundStyle(Color.app.primarioTinte)
        }
        .font(Font.app.cuerpo)
    }

    private var servicios: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Servicios")
            if viewModel.gruposDeServicios.isEmpty {
                TarjetaApp {
                    Text("Este negocio aún no publica sus servicios.")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            } else {
                ForEach(viewModel.gruposDeServicios, id: \.tipo) { grupo in
                    TarjetaApp {
                        VStack(alignment: .leading, spacing: Espaciado.s) {
                            Label(grupo.tipo.titulo, systemImage: grupo.tipo.icono)
                                .font(Font.app.encabezado)
                                .foregroundStyle(Color.app.textoPrincipal)
                            ForEach(grupo.servicios) { servicio in
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(servicio.nombre)
                                            .font(Font.app.cuerpo)
                                            .foregroundStyle(Color.app.textoPrincipal)
                                        Text("\(servicio.duracionMinutos) min")
                                            .font(Font.app.nota)
                                            .foregroundStyle(Color.app.textoSecundario)
                                    }
                                    Spacer(minLength: Espaciado.xs)
                                    Text(servicio.precio, format: .currency(code: "MXN").precision(.fractionLength(0)))
                                        .font(Font.app.cuerpoDestacado)
                                        .foregroundStyle(Color.app.textoPrincipal)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var resenas: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Reseñas de citas reales")
            if viewModel.resenas.isEmpty {
                TarjetaApp {
                    Label("Aún no tiene reseñas. Solo se publican después de una cita terminada.", systemImage: "star")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            } else {
                ForEach(viewModel.resenas) { resena in
                    TarjetaApp {
                        VStack(alignment: .leading, spacing: Espaciado.xs) {
                            HStack {
                                Calificacion(Double(resena.calificacion), estilo: .completa)
                                Spacer(minLength: Espaciado.xs)
                                Text(resena.fecha, format: .dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_MX")))
                                    .font(Font.app.nota)
                                    .foregroundStyle(Color.app.textoSecundario)
                            }
                            Text(resena.texto)
                                .font(Font.app.cuerpo)
                                .foregroundStyle(Color.app.textoPrincipal)
                            if let mascota = resena.cita?.mascota?.nombre {
                                Label("Tutor de \(mascota)", systemImage: "pawprint.fill")
                                    .font(Font.app.nota)
                                    .foregroundStyle(Color.app.textoSecundario)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview("Claro") {
    if let perfil = VistaPrevia.perfilHuellitas() {
        NavigationStack {
            PerfilNegocioView(viewModel: perfil)
        }
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let perfil = VistaPrevia.perfilHuellitas() {
        NavigationStack {
            PerfilNegocioView(viewModel: perfil)
        }
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
    }
}
