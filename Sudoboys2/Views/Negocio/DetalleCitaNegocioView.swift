import PhotosUI
import SwiftUI

/// Una cita vista por el negocio: datos de la mascota, check-in, etapas y foto final.
struct DetalleCitaNegocioView: View {
    let viewModel: AgendaViewModel
    let cita: Cita

    @State private var seleccion: PhotosPickerItem?
    @State private var fotoFinal: Data?
    @State private var mostrandoCamara = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.l) {
                paciente
                progreso
                if cita.estado == .enCurso, viewModel.siguienteEsListo(cita) {
                    foto
                        .transition(.opacity)
                }
                if cita.estado == .terminada, let datos = cita.fotoFinal, let imagen = UIImage(data: datos) {
                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        EncabezadoSeccion("Foto final")
                        imagenFinal(imagen)
                    }
                }
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.m)
            .animation(Animation.app.resorte, value: cita.etapaActual)
        }
        .background(Color.app.fondo)
        .navigationTitle(cita.nombreMascota)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { accion }
        .task(id: seleccion) {
            guard let seleccion else { return }
            if let datos = try? await seleccion.loadTransferable(type: Data.self) {
                fotoFinal = viewModel.prepararFoto(datos)
            }
        }
        .fullScreenCover(isPresented: $mostrandoCamara) {
            CamaraFoto { datos in
                if let datos { fotoFinal = viewModel.prepararFoto(datos) }
                mostrandoCamara = false
            }
            .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: viewModel.avances)
    }

    // MARK: - Secciones

    private var paciente: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.s) {
                HStack(spacing: Espaciado.s) {
                    AvatarMascota(
                        imagen: cita.mascota?.imagen,
                        nombre: cita.nombreMascota,
                        iconoRespaldo: cita.especie?.icono ?? "pawprint.fill",
                        tamano: 64
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cita.nombreMascota)
                            .font(Font.app.titulo3)
                            .foregroundStyle(Color.app.textoPrincipal)
                        Text(cita.mascota?.resumen() ?? "Cita de emergencia, sin perfil")
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.textoSecundario)
                    }
                }
                fila("clock.fill", "\(cita.fecha.fechaCita) · \(cita.servicio?.nombre ?? cita.tipoServicio.titulo)")
                if let tutor = cita.tutor?.nombre {
                    fila("person.fill", "Tutor: \(tutor)")
                }
                if let mascota = cita.mascota {
                    if !mascota.alergias.isEmpty {
                        fila("exclamationmark.triangle.fill", "Alergia: \(mascota.alergias)", color: Color.app.acentoTexto)
                    }
                    if !mascota.notasComportamiento.isEmpty {
                        fila("text.bubble.fill", mascota.notasComportamiento)
                    }
                } else {
                    if let motivo = cita.motivoEmergencia, !motivo.isEmpty {
                        fila("cross.case.fill", "Motivo: \(motivo)", color: Color.app.acentoTexto)
                    }
                    if let telefono = cita.telefonoEmergencia, !telefono.isEmpty {
                        fila("phone.fill", telefono)
                    }
                }
            }
        }
    }

    private func fila(_ icono: String, _ texto: String, color: Color = Color.app.textoPrincipal) -> some View {
        Label {
            Text(texto).foregroundStyle(color)
        } icon: {
            Image(systemName: icono).foregroundStyle(color == Color.app.textoPrincipal ? Color.app.primarioTinte : color)
        }
        .font(Font.app.cuerpo)
    }

    private var progreso: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Etapas")
            TarjetaApp {
                VStack(alignment: .leading, spacing: Espaciado.s) {
                    ProgresoEtapas(etapas: cita.etapas, actual: cita.etapaActual)
                    Text(textoEstado)
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                        .contentTransition(.opacity)
                }
            }
        }
    }

    private var textoEstado: String {
        switch cita.estado {
        case .programada: "Aún no llega. Registra su llegada para avisarle al tutor."
        case .enCurso: "Listo aprox. \(cita.horaEstimadaListo.horaCorta) · El tutor ve este avance en su pantalla de bloqueo"
        case .terminada: "Listo para recoger. Ya le avisamos al tutor."
        case .cancelada: "Esta cita se canceló."
        }
    }

    private var foto: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Foto final")
            if let fotoFinal, let imagen = UIImage(data: fotoFinal) {
                imagenFinal(imagen)
            } else {
                Text("Al tutor le encanta ver cómo quedó. Es opcional.")
                    .font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
            }
            HStack(spacing: Espaciado.s) {
                if CamaraFoto.disponible {
                    BotonSecundario("Tomar foto", icono: "camera.fill") { mostrandoCamara = true }
                }
                PhotosPicker(selection: $seleccion, matching: .images) {
                    Label(fotoFinal == nil ? "Elegir foto" : "Cambiar foto", systemImage: "photo.fill")
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .padding(.horizontal, Espaciado.m)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Color.app.superficieElevada, in: Forma.control)
                }
                .buttonStyle(.presionable)
            }
        }
    }

    private func imagenFinal(_ imagen: UIImage) -> some View {
        Image(uiImage: imagen)
            .resizable()
            .scaledToFill()
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipShape(Forma.tarjeta)
            .accessibilityLabel("Foto final de \(cita.nombreMascota)")
    }

    // MARK: - Acción principal

    @ViewBuilder
    private var accion: some View {
        Group {
            switch cita.estado {
            case .programada:
                BotonPrincipal("Registrar llegada", icono: "checkmark.circle.fill") {
                    viewModel.registrarLlegada(cita)
                }
            case .enCurso:
                if let siguiente = cita.siguienteEtapa {
                    if siguiente == .listo {
                        BotonAcento("Marcar como listo", icono: siguiente.icono) {
                            viewModel.avanzar(cita, fotoFinal: fotoFinal)
                        }
                    } else {
                        BotonPrincipal("Avanzar a \(siguiente.titulo)", icono: siguiente.icono) {
                            viewModel.avanzar(cita)
                        }
                    }
                }
            case .terminada:
                Label("Listo para recoger", systemImage: "pawprint.fill")
                    .font(Font.app.encabezado)
                    .foregroundStyle(Color.app.saludTexto)
                    .frame(maxWidth: .infinity, minHeight: 52)
            case .cancelada:
                EmptyView()
            }
        }
        // El botón cambia de texto sin fundido: así no se enciman las dos etiquetas.
        .animation(nil, value: cita.etapaActual)
        .padding(.horizontal, Espaciado.margenPantalla)
        .padding(.vertical, Espaciado.s)
        .background(Color.app.fondo)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.app.borde).frame(height: 1)
        }
    }
}

#Preview("Claro") {
    if let agenda = VistaPrevia.agenda(), let cita = agenda.citas.first {
        NavigationStack { DetalleCitaNegocioView(viewModel: agenda, cita: cita) }
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let agenda = VistaPrevia.agenda(), let cita = agenda.citas.first {
        NavigationStack { DetalleCitaNegocioView(viewModel: agenda, cita: cita) }
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
