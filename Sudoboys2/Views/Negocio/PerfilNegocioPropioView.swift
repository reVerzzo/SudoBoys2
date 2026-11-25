import SwiftUI

/// Perfil del negocio de la sesión: datos básicos y estado de verificación.
struct PerfilNegocioPropioView: View {
    let negocio: Negocio
    @Bindable var viewModel: VerificacionViewModel
    @State private var cargandoCedula = false
    @State private var formularioServicio: FormularioServicioViewModel?
    @Environment(\.repositorios) private var repositorios

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
                        }
                    }

                    seccionVerificacion

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
                                        Button {
                                            editar(servicio)
                                        } label: {
                                            HStack(spacing: Espaciado.xs) {
                                                Label {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(servicio.nombre)
                                                            .font(Font.app.cuerpo)
                                                            .foregroundStyle(Color.app.textoPrincipal)
                                                        Text("\(servicio.etapas.count) etapas · \(servicio.duracionMinutos) min")
                                                            .font(Font.app.nota)
                                                            .foregroundStyle(Color.app.textoSecundario)
                                                    }
                                                } icon: {
                                                    Image(systemName: servicio.tipo.icono)
                                                        .foregroundStyle(Color.app.primarioTinte)
                                                }
                                                Spacer(minLength: Espaciado.xs)
                                                Text(servicio.precio, format: .currency(code: "MXN").precision(.fractionLength(0)))
                                                    .font(Font.app.cuerpo)
                                                    .foregroundStyle(Color.app.textoSecundario)
                                                    .monospacedDigit()
                                                Image(systemName: "chevron.right")
                                                    .font(Font.app.nota.weight(.semibold))
                                                    .foregroundStyle(Color.app.textoSecundario)
                                                    .accessibilityHidden(true)
                                            }
                                            .multilineTextAlignment(.leading)
                                            .frame(minHeight: 44)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.presionable)
                                        .accessibilityHint("Edita el servicio y sus etapas")
                                    }
                                }
                            }
                        }
                        BotonSecundario("Agregar servicio", icono: "plus.circle.fill") {
                            editar(nil)
                        }
                    }
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.l)
            }
            .background(Color.app.fondo)
            .navigationTitle("Perfil")
            .sheet(item: $formularioServicio) { formulario in
                FormularioServicioView(viewModel: formulario)
            }
            .sheet(isPresented: $cargandoCedula) {
                CargaCedulaView(viewModel: viewModel)
            }
            .alert("Algo salió mal", isPresented: Binding(
                get: { viewModel.mensajeError != nil && !cargandoCedula },
                set: { if !$0 { viewModel.mensajeError = nil } }
            )) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(viewModel.mensajeError ?? "")
            }
            .animation(Animation.app.resorte, value: viewModel.estado)
            .sensoryFeedback(.success, trigger: viewModel.cambios)
        }
    }

    private func editar(_ servicio: Servicio?) {
        guard let repositorios else { return }
        formularioServicio = FormularioServicioViewModel(
            servicio: servicio, negocio: negocio, negocios: repositorios.negocios
        )
    }

    // MARK: - Verificación

    private var seccionVerificacion: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Verificación")
            TarjetaApp {
                VStack(alignment: .leading, spacing: Espaciado.s) {
                    estadoVerificacion
                    if viewModel.requiereCedula, viewModel.estado != .enRevision {
                        if viewModel.estado == .verificado {
                            Button("Actualizar cédula") { cargandoCedula = true }
                                .font(Font.app.subtitulo.weight(.semibold))
                                .foregroundStyle(Color.app.primarioTinte)
                        } else {
                            BotonAcento("Subir cédula profesional", icono: "person.text.rectangle.fill") {
                                cargandoCedula = true
                            }
                        }
                    }
                    if viewModel.puedeAprobar {
                        Divider().overlay(Color.app.borde)
                        BotonSecundario("Aprobar como administrador", icono: "checkmark.shield.fill") {
                            viewModel.aprobarComoAdministrador()
                        }
                        Text("Simula la revisión del equipo: en la demo no hay servidor.")
                            .font(Font.app.nota)
                            .foregroundStyle(Color.app.textoSecundario)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var estadoVerificacion: some View {
        switch viewModel.estado {
        case .verificado:
            VStack(alignment: .leading, spacing: Espaciado.xs) {
                InsigniaVerificado(viewModel.requiereCedula ? .cedula : .negocio)
                if viewModel.requiereCedula {
                    Text([negocio.nombreVeterinario, negocio.cedula.map { "Cédula profesional \($0)" }].compactMap { $0 }.joined(separator: " · "))
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                    Label("Ya puedes emitir recetas desde tus citas.", systemImage: "pills.fill")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.saludTexto)
                }
            }
        case .enRevision:
            estado(
                "hourglass", "En revisión",
                viewModel.requiereCedula
                    ? "Recibimos tu cédula\(negocio.cedula.map { " \($0)" } ?? ""). Te avisamos cuando esté aprobada."
                    : "Estamos revisando tu negocio."
            )
        case .pendiente:
            estado(
                "exclamationmark.circle.fill", "Verificación pendiente",
                viewModel.requiereCedula
                    ? "Sube tu cédula profesional para mostrar la insignia y emitir recetas."
                    : "Al verificarte, los tutores ven la insignia de negocio verificado."
            )
        }
    }

    private func estado(_ icono: String, _ titulo: String, _ mensaje: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(Font.app.encabezado)
                    .foregroundStyle(Color.app.textoPrincipal)
                Text(mensaje)
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
            }
        } icon: {
            Image(systemName: icono)
                .font(.title3)
                .foregroundStyle(Color.app.acentoTexto)
        }
    }
}

#Preview("Claro") {
    if let verificacion = VistaPrevia.verificacion() {
        PerfilNegocioPropioView(negocio: verificacion.negocio, viewModel: verificacion)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let verificacion = VistaPrevia.verificacion() {
        PerfilNegocioPropioView(negocio: verificacion.negocio, viewModel: verificacion)
            .preferredColorScheme(.dark)
    }
}
