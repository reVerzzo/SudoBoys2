import SwiftUI

/// Botón destacado: fondo `acento` con texto oscuro (nunca blanco, por contraste).
/// Úsalo con moderación: es el 10 % de la paleta.
struct BotonAcento: View {
    let titulo: String
    var icono: String?
    var cargando = false
    let accion: () -> Void

    init(_ titulo: String, icono: String? = nil, cargando: Bool = false, accion: @escaping () -> Void) {
        self.titulo = titulo
        self.icono = icono
        self.cargando = cargando
        self.accion = accion
    }

    var body: some View {
        BotonRelleno(
            titulo: titulo,
            icono: icono,
            cargando: cargando,
            fondo: Color.app.acento,
            colorTexto: Color.app.textoSobreAcento,
            accion: accion
        )
    }
}

#Preview("Claro") {
    VistaPreviaBotonAcento()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaBotonAcento()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaBotonAcento: View {
    var body: some View {
        VStack(spacing: Espaciado.m) {
            BotonAcento("Urgencia ahora", icono: "cross.case.fill") {}
            BotonAcento("Buscando…", cargando: true) {}
            BotonAcento("No disponible") {}
                .disabled(true)
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
