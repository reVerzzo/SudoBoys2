import SwiftUI

/// Botón secundario: fondo `superficieElevada` con texto principal.
/// Para acciones alternas, como los proveedores de inicio de sesión.
struct BotonSecundario: View {
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
            fondo: Color.app.superficieElevada,
            colorTexto: Color.app.textoPrincipal,
            accion: accion
        )
    }
}

#Preview("Claro") {
    VistaPreviaBotonSecundario()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaBotonSecundario()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaBotonSecundario: View {
    var body: some View {
        VStack(spacing: Espaciado.m) {
            BotonSecundario("Continuar con Google", icono: "g.circle.fill") {}
            BotonSecundario("Continuar con Apple", icono: "apple.logo") {}
                .disabled(true)
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
