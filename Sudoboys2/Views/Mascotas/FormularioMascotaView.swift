import PhotosUI
import SwiftUI

/// Alta y edición de una mascota, con foto desde la fototeca (no pide permisos).
struct FormularioMascotaView: View {
    @Bindable var viewModel: FormularioMascotaViewModel
    @Environment(\.dismiss) private var cerrar
    @State private var seleccion: PhotosPickerItem?

    private var imagen: Image? {
        guard let foto = viewModel.foto, let imagen = UIImage(data: foto) else { return nil }
        return Image(uiImage: imagen)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.l) {
                    foto
                    CampoTexto("Nombre", marcador: "¿Cómo se llama?", icono: "pawprint.fill", texto: $viewModel.nombre)
                    especie
                    CampoTexto("Raza", marcador: "Opcional", texto: $viewModel.raza)
                    nacimiento
                    VStack(alignment: .leading, spacing: Espaciado.xxs) {
                        CampoTexto("Peso en kilos", marcador: "Opcional", icono: "scalemass.fill", texto: $viewModel.pesoTexto)
                            .keyboardType(.decimalPad)
                        if !viewModel.pesoValido {
                            Text("Escribe solo el número, por ejemplo 18.5")
                                .font(Font.app.nota)
                                .foregroundStyle(Color.app.acentoTexto)
                        }
                    }
                    CampoTexto("Alergias", marcador: "Por ejemplo: pollo", icono: "exclamationmark.triangle.fill", texto: $viewModel.alergias)
                    notas
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.m)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.app.fondo)
            .navigationTitle(viewModel.titulo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if viewModel.guardar() { cerrar() }
                    }
                    .disabled(!viewModel.puedeGuardar)
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
            .task(id: seleccion) {
                guard let seleccion else { return }
                if let datos = try? await seleccion.loadTransferable(type: Data.self) {
                    viewModel.usarFoto(datos)
                }
            }
        }
        .environment(\.locale, .mx)
    }

    private var foto: some View {
        VStack(spacing: Espaciado.s) {
            PhotosPicker(selection: $seleccion, matching: .images) {
                AvatarMascota(imagen: imagen, nombre: viewModel.nombre, iconoRespaldo: viewModel.especie.icono, tamano: 120)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.textoSobrePrimario)
                            .padding(Espaciado.xs)
                            .background(Color.app.primario, in: Circle())
                            .accessibilityHidden(true)
                    }
            }
            .buttonStyle(.presionable)
            .accessibilityLabel(viewModel.foto == nil ? "Elegir foto" : "Cambiar foto")
            if viewModel.foto != nil {
                Button("Quitar foto") {
                    seleccion = nil
                    viewModel.quitarFoto()
                }
                .font(Font.app.subtitulo.weight(.semibold))
                .foregroundStyle(Color.app.primarioTinte)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(Animation.app.resorte, value: viewModel.foto == nil)
    }

    private var especie: some View {
        VStack(alignment: .leading, spacing: Espaciado.xs) {
            Text("Especie")
                .font(Font.app.etiqueta)
                .foregroundStyle(Color.app.textoSecundario)
            HStack(spacing: Espaciado.xs) {
                ForEach(Especie.allCases, id: \.self) { especie in
                    ChipFiltro(especie.titulo, icono: especie.icono, seleccionado: viewModel.especie == especie) {
                        viewModel.especie = especie
                    }
                }
            }
            if viewModel.especie == .exotico {
                CampoTexto("¿Qué animal es?", marcador: "Conejo, ave, hurón…", texto: $viewModel.detalleEspecie)
                    .transition(.opacity)
            }
        }
        .animation(Animation.app.suave, value: viewModel.especie)
    }

    private var nacimiento: some View {
        VStack(alignment: .leading, spacing: Espaciado.xs) {
            Toggle("Sé su fecha de nacimiento", isOn: $viewModel.conoceNacimiento)
                .font(Font.app.cuerpo)
                .foregroundStyle(Color.app.textoPrincipal)
                .tint(Color.app.salud)
            if viewModel.conoceNacimiento {
                DatePicker("Nacimiento", selection: $viewModel.nacimiento, in: ...Date.now, displayedComponents: .date)
                    .font(Font.app.cuerpo)
                    .foregroundStyle(Color.app.textoPrincipal)
                    .transition(.opacity)
            }
        }
        .padding(Espaciado.m)
        .background(Color.app.superficieElevada, in: Forma.control)
        .animation(Animation.app.suave, value: viewModel.conoceNacimiento)
    }

    private var notas: some View {
        VStack(alignment: .leading, spacing: Espaciado.xxs) {
            Text("Notas de comportamiento")
                .font(Font.app.etiqueta)
                .foregroundStyle(Color.app.textoSecundario)
            TextField("Lo que conviene saber al atenderle", text: $viewModel.notas, axis: .vertical)
                .lineLimit(3...6)
                .font(Font.app.cuerpo)
                .foregroundStyle(Color.app.textoPrincipal)
                .padding(Espaciado.m)
                .background(Color.app.superficieElevada, in: Forma.control)
                .accessibilityLabel("Notas de comportamiento")
        }
    }
}

#Preview("Alta · Claro") {
    FormularioMascotaView(viewModel: VistaPrevia.misMascotas().formularioNuevaMascota())
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Edición · Oscuro") {
    if let detalle = VistaPrevia.detalleFirulais() {
        FormularioMascotaView(viewModel: detalle.formularioEdicion())
            .tint(Color.app.primarioTinte)
            .preferredColorScheme(.dark)
    }
}
