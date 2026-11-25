import SwiftUI

/// Tarjeta completa de la mascota: datos, QR y cartilla de vacunación.
struct DetalleMascotaView: View {
    @Bindable var viewModel: DetalleMascotaViewModel
    @State private var formulario: FormularioMascotaViewModel?
    @State private var escaneo: EscaneoCartillaViewModel?
    @State private var agregandoVacuna = false

    private var mascota: Mascota { viewModel.mascota }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.l) {
                encabezado
                datos
                TarjetaQR(nombre: mascota.nombre, imagen: viewModel.imagenQR)
                cartilla
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.top, Espaciado.s)
            .padding(.bottom, Espaciado.xl)
        }
        .background(alignment: .top) {
            FondoMalla()
                .frame(height: 320)
                .ignoresSafeArea()
        }
        .background(Color.app.fondo)
        .navigationTitle(mascota.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Editar") { formulario = viewModel.formularioEdicion() }
            }
        }
        .sheet(item: $formulario) { formulario in
            FormularioMascotaView(viewModel: formulario)
        }
        .sheet(item: $escaneo) { escaneo in
            EscaneoCartillaView(viewModel: escaneo)
        }
        .sheet(isPresented: $agregandoVacuna) {
            FormularioVacunaView { nombre, fecha, proxima in
                viewModel.agregarVacuna(nombre: nombre, fechaAplicacion: fecha, proximaDosis: proxima)
            }
        }
        .alert("Algo salió mal", isPresented: Binding(
            get: { viewModel.mensajeError != nil },
            set: { if !$0 { viewModel.mensajeError = nil } }
        )) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(viewModel.mensajeError ?? "")
        }
        .sensoryFeedback(.success, trigger: viewModel.guardados)
        .animation(Animation.app.resorte, value: viewModel.vacunas.map(\.id))
        .task { viewModel.cargar() }
    }

    // MARK: - Secciones

    private var encabezado: some View {
        VStack(spacing: Espaciado.xs) {
            AvatarMascota(imagen: mascota.imagen, nombre: mascota.nombre, iconoRespaldo: mascota.especie.icono, tamano: 120)
            Text(mascota.nombre)
                .font(Font.app.tituloGrande)
                .foregroundStyle(Color.app.textoPrincipal)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(mascota.resumen())
                .font(Font.app.cuerpo)
                .foregroundStyle(Color.app.textoSecundario)
                .multilineTextAlignment(.center)
            if let proxima = viewModel.proximaVacuna, let fecha = proxima.proximaDosis {
                InsigniaSalud("Próxima vacuna: \(fecha.fechaCorta)")
                    .padding(.top, Espaciado.xxs)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var datos: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.s) {
                if let nacimiento = mascota.nacimiento {
                    fila("birthday.cake.fill", "Nacimiento", nacimiento.fechaCorta)
                }
                if let peso = mascota.pesoKg {
                    fila("scalemass.fill", "Peso", peso.formatted(.number.precision(.fractionLength(0...1)).locale(.mx)) + " kg")
                }
                fila(
                    "exclamationmark.triangle.fill",
                    "Alergias",
                    mascota.alergias.isEmpty ? "Ninguna registrada" : mascota.alergias,
                    color: mascota.alergias.isEmpty ? Color.app.textoPrincipal : Color.app.acentoTexto
                )
                if !mascota.notasComportamiento.isEmpty {
                    fila("heart.text.square.fill", "Comportamiento", mascota.notasComportamiento)
                }
            }
        }
    }

    private func fila(_ icono: String, _ titulo: String, _ valor: String, color: Color = Color.app.textoPrincipal) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(Font.app.etiqueta)
                    .foregroundStyle(Color.app.textoSecundario)
                Text(valor)
                    .font(Font.app.cuerpo)
                    .foregroundStyle(color)
            }
        } icon: {
            Image(systemName: icono)
                .foregroundStyle(Color.app.primarioTinte)
        }
        .accessibilityElement(children: .combine)
    }

    private var cartilla: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion("Cartilla de vacunación", tituloAccion: "Agregar") {
                agregandoVacuna = true
            }
            BotonAcento("Escanear cartilla", icono: "doc.viewfinder") {
                escaneo = viewModel.nuevoEscaneo()
            }
            if viewModel.vacunas.isEmpty {
                TarjetaApp {
                    Label("Aún no hay vacunas. Escanea su cartilla de papel o agrégalas a mano.", systemImage: "syringe")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            } else {
                ForEach(viewModel.vacunas) { vacuna in
                    FilaVacuna(vacuna: vacuna)
                        .contextMenu {
                            Button("Eliminar", systemImage: "trash", role: .destructive) {
                                viewModel.eliminar(vacuna)
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
    }
}

/// QR con el id de la mascota. Siempre sobre blanco para que cualquier lector lo lea.
private struct TarjetaQR: View {
    let nombre: String
    let imagen: CGImage?

    var body: some View {
        TarjetaApp {
            HStack(spacing: Espaciado.m) {
                Group {
                    if let imagen {
                        Image(decorative: imagen, scale: 1)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "qrcode")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.black)
                            .redacted(reason: .placeholder)
                    }
                }
                .frame(width: 120, height: 120)
                .padding(Espaciado.xs)
                .background(.white, in: Forma.control)
                .overlay { Forma.control.strokeBorder(Color.app.borde, lineWidth: 1) }
                .accessibilityLabel("Código QR de \(nombre)")
                .accessibilityAddTraits(.isImage)

                VStack(alignment: .leading, spacing: Espaciado.xxs) {
                    Label("Tarjeta de \(nombre)", systemImage: "qrcode")
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                    Text("Muéstralo al llegar a tu cita: el negocio lo escanea y hace el check-in al instante.")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            }
        }
    }
}

#Preview("Claro") {
    if let detalle = VistaPrevia.detalleFirulais() {
        NavigationStack {
            DetalleMascotaView(viewModel: detalle)
        }
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
    }
}

#Preview("Oscuro") {
    if let detalle = VistaPrevia.detalleFirulais() {
        NavigationStack {
            DetalleMascotaView(viewModel: detalle)
        }
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
    }
}
