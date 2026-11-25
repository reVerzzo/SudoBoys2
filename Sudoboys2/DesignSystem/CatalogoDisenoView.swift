import SwiftUI

/// Catálogo de diseño: muestra todos los tokens y componentes base.
/// Sirve para revisar el sistema en claro y oscuro antes de armar pantallas.
struct CatalogoDisenoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.xl) {
                SeccionCatalogo("Apariencia") {
                    SelectorApariencia()
                }
                SeccionCatalogo("Colores") {
                    MuestrasDeColor()
                }
                SeccionCatalogo("Tipografía") {
                    MuestrasDeTipografia()
                }
                SeccionCatalogo("Espaciado y radios") {
                    MuestrasDeEspaciado()
                }
                SeccionCatalogo("Botones") {
                    DemoBotones()
                }
                SeccionCatalogo("Chips de filtro") {
                    DemoChips()
                }
                SeccionCatalogo("Insignias") {
                    DemoInsignias()
                }
                SeccionCatalogo("Calificación") {
                    DemoCalificacion()
                }
                SeccionCatalogo("Avatares") {
                    DemoAvatares()
                }
                SeccionCatalogo("Tarjeta") {
                    DemoTarjeta()
                }
                SeccionCatalogo("Estado vacío") {
                    TarjetaApp {
                        EstadoVacio(
                            icono: "calendar",
                            titulo: "Sin citas por ahora",
                            mensaje: "Cuando reserves una cita aparecerá aquí.",
                            tituloAccion: "Explorar negocios"
                        ) {}
                    }
                }
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.l)
        }
        .background(Color.app.fondo)
        .navigationTitle("Catálogo de diseño")
    }
}

// MARK: - Sección

private struct SeccionCatalogo<Contenido: View>: View {
    let titulo: String
    @ViewBuilder let contenido: Contenido

    init(_ titulo: String, @ViewBuilder contenido: () -> Contenido) {
        self.titulo = titulo
        self.contenido = contenido()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            EncabezadoSeccion(titulo)
            contenido
        }
    }
}

// MARK: - Tokens

private struct MuestrasDeColor: View {
    private struct Muestra: Identifiable {
        let nombre: String
        let color: Color
        var id: String { nombre }
    }

    private let muestras: [Muestra] = [
        Muestra(nombre: "fondo", color: Color.app.fondo),
        Muestra(nombre: "superficie", color: Color.app.superficie),
        Muestra(nombre: "superficieElevada", color: Color.app.superficieElevada),
        Muestra(nombre: "borde", color: Color.app.borde),
        Muestra(nombre: "textoPrincipal", color: Color.app.textoPrincipal),
        Muestra(nombre: "textoSecundario", color: Color.app.textoSecundario),
        Muestra(nombre: "primario", color: Color.app.primario),
        Muestra(nombre: "primarioTinte", color: Color.app.primarioTinte),
        Muestra(nombre: "salud", color: Color.app.salud),
        Muestra(nombre: "saludTexto", color: Color.app.saludTexto),
        Muestra(nombre: "acento", color: Color.app.acento),
        Muestra(nombre: "acentoTexto", color: Color.app.acentoTexto),
        Muestra(nombre: "estrellas", color: Color.app.estrellas),
        Muestra(nombre: "textoSobreAcento", color: Color.app.textoSobreAcento),
        Muestra(nombre: "textoSobreSalud", color: Color.app.textoSobreSalud),
    ]

    private let columnas = [GridItem(.adaptive(minimum: 96), spacing: Espaciado.s, alignment: .top)]

    var body: some View {
        LazyVGrid(columns: columnas, alignment: .leading, spacing: Espaciado.m) {
            ForEach(muestras) { muestra in
                VStack(alignment: .leading, spacing: Espaciado.xxs) {
                    Forma.control
                        .fill(muestra.color)
                        .frame(height: 56)
                        .overlay {
                            Forma.control.strokeBorder(Color.app.borde, lineWidth: 1)
                        }
                    Text(muestra.nombre)
                        .font(Font.app.etiqueta)
                        .foregroundStyle(Color.app.textoSecundario)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

private struct MuestrasDeTipografia: View {
    var body: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.xs) {
                Text("Título grande").font(Font.app.tituloGrande)
                Text("Título").font(Font.app.titulo)
                Text("Título 2").font(Font.app.titulo2)
                Text("Título 3").font(Font.app.titulo3)
                Text("Encabezado").font(Font.app.encabezado)
                Text("Cuerpo: cuidamos a tu mascota como tú.").font(Font.app.cuerpo)
                Text("Cuerpo destacado").font(Font.app.cuerpoDestacado)
                Text("Subtítulo").font(Font.app.subtitulo)
                    .foregroundStyle(Color.app.textoSecundario)
                Text("Nota").font(Font.app.nota)
                    .foregroundStyle(Color.app.textoSecundario)
                Text("Etiqueta").font(Font.app.etiqueta)
                    .foregroundStyle(Color.app.textoSecundario)
            }
            .foregroundStyle(Color.app.textoPrincipal)
        }
    }
}

private struct MuestrasDeEspaciado: View {
    private struct Paso: Identifiable {
        let nombre: String
        let valor: CGFloat
        var id: String { nombre }
    }

    private let espacios: [Paso] = [
        Paso(nombre: "xxs", valor: Espaciado.xxs),
        Paso(nombre: "xs", valor: Espaciado.xs),
        Paso(nombre: "s", valor: Espaciado.s),
        Paso(nombre: "m", valor: Espaciado.m),
        Paso(nombre: "l", valor: Espaciado.l),
        Paso(nombre: "xl", valor: Espaciado.xl),
    ]

    private let radios: [Paso] = [
        Paso(nombre: "chip", valor: Radio.chip),
        Paso(nombre: "control", valor: Radio.control),
        Paso(nombre: "tarjeta", valor: Radio.tarjeta),
        Paso(nombre: "hoja", valor: Radio.hoja),
    ]

    var body: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.m) {
                VStack(alignment: .leading, spacing: Espaciado.xs) {
                    ForEach(espacios) { paso in
                        HStack(spacing: Espaciado.s) {
                            Capsule()
                                .fill(Color.app.salud)
                                .frame(width: paso.valor * 4, height: 8)
                            Text("\(paso.nombre) · \(Int(paso.valor))")
                                .font(Font.app.etiqueta)
                                .foregroundStyle(Color.app.textoSecundario)
                        }
                    }
                }
                HStack(alignment: .top, spacing: Espaciado.s) {
                    ForEach(radios) { paso in
                        VStack(spacing: Espaciado.xxs) {
                            RoundedRectangle(cornerRadius: paso.valor, style: .continuous)
                                .fill(Color.app.superficieElevada)
                                .frame(height: 56)
                            Text("\(paso.nombre) · \(Int(paso.valor))")
                                .font(Font.app.etiqueta)
                                .foregroundStyle(Color.app.textoSecundario)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Componentes

private struct DemoBotones: View {
    @State private var cargando = false
    @State private var reservas = 0

    var body: some View {
        VStack(spacing: Espaciado.s) {
            BotonPrincipal("Reservar cita", icono: "calendar.badge.plus", cargando: cargando) {
                Task {
                    cargando = true
                    try? await Task.sleep(for: .seconds(1.2))
                    cargando = false
                    reservas += 1
                }
            }
            .sensoryFeedback(.success, trigger: reservas)

            BotonAcento("Urgencia ahora", icono: "cross.case.fill") {}

            BotonPrincipal("Deshabilitado") {}
                .disabled(true)

            BotonPrincipal("Un título muy largo para probar cómo se acomoda el botón en dos líneas") {}
        }
    }
}

private struct DemoChips: View {
    private struct Filtro: Identifiable {
        let titulo: String
        let icono: String?
        var id: String { titulo }
    }

    private let filtros: [Filtro] = [
        Filtro(titulo: "Veterinaria", icono: "stethoscope"),
        Filtro(titulo: "Estética", icono: "scissors"),
        Filtro(titulo: "Perros", icono: "dog.fill"),
        Filtro(titulo: "Gatos", icono: "cat.fill"),
        Filtro(titulo: "Exóticos", icono: "hare.fill"),
        Filtro(titulo: "Verificado", icono: "checkmark.seal.fill"),
        Filtro(titulo: "Abierto ahora", icono: nil),
    ]

    @State private var seleccion: Set<String> = ["Veterinaria"]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Espaciado.xs) {
                ForEach(filtros) { filtro in
                    ChipFiltro(
                        filtro.titulo,
                        icono: filtro.icono,
                        seleccionado: seleccion.contains(filtro.id)
                    ) {
                        if seleccion.contains(filtro.id) {
                            seleccion.remove(filtro.id)
                        } else {
                            seleccion.insert(filtro.id)
                        }
                    }
                }
            }
            .padding(.horizontal, Espaciado.margenPantalla)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -Espaciado.margenPantalla)
    }
}

private struct DemoInsignias: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Espaciado.s) {
            HStack(spacing: Espaciado.xs) {
                InsigniaVerificado(.cedula)
                InsigniaVerificado(.negocio)
                InsigniaVerificado(.cedula, compacta: true)
            }
            HStack(spacing: Espaciado.xs) {
                InsigniaSalud("Vacunas al día")
                InsigniaSalud("Receta activa", icono: "pills.fill")
            }
        }
    }
}

private struct DemoCalificacion: View {
    @State private var valor = 4.8
    @State private var resenas = 128

    var body: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.m) {
                HStack {
                    Calificacion(valor, resenas: resenas)
                    Spacer()
                    Calificacion(valor, estilo: .completa)
                }
                Slider(value: $valor, in: 0...5, step: 0.1) {
                    Text("Calificación de ejemplo")
                }
                .tint(Color.app.salud)
                .onChange(of: valor) {
                    resenas = 100 + Int(valor * 10)
                }
            }
        }
    }
}

private struct DemoAvatares: View {
    var body: some View {
        HStack(spacing: Espaciado.m) {
            AvatarMascota(nombre: "Firulais", iconoRespaldo: "dog.fill", tamano: 40)
            AvatarMascota(nombre: "Mochi", iconoRespaldo: "hare.fill")
            AvatarMascota(nombre: "Michi", iconoRespaldo: "cat.fill", tamano: 72)
            AvatarMascota(tamano: 88)
        }
    }
}

private struct DemoTarjeta: View {
    var body: some View {
        TarjetaApp {
            HStack(alignment: .top, spacing: Espaciado.s) {
                AvatarMascota(nombre: "Clínica Huellitas", iconoRespaldo: "cross.case.fill")
                VStack(alignment: .leading, spacing: Espaciado.xs) {
                    Text("Clínica Huellitas")
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                    Text("Veterinaria y estética · Coyoacán")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                    Calificacion(4.8, resenas: 128)
                    InsigniaVerificado(.cedula)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Claro") {
    NavigationStack {
        CatalogoDisenoView()
    }
    .tint(Color.app.primarioTinte)
    .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    NavigationStack {
        CatalogoDisenoView()
    }
    .tint(Color.app.primarioTinte)
    .preferredColorScheme(.dark)
}
