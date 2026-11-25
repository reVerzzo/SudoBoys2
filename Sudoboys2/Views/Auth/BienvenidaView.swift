import SwiftUI

/// Primera pantalla: elegir entre "Soy tutor" y "Soy estética o veterinaria".
struct BienvenidaView: View {
    let transicion: Namespace.ID
    let alElegir: (RolUsuario) -> Void

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var visible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espaciado.xl) {
                encabezado
                VStack(spacing: Espaciado.m) {
                    ForEach(RolUsuario.allCases, id: \.self) { rol in
                        TarjetaRol(rol: rol) { alElegir(rol) }
                            .matchedTransitionSource(id: rol, in: transicion)
                    }
                }
                Text("Puedes probar los dos roles con las cuentas demo, sin internet.")
                    .font(Font.app.nota)
                    .foregroundStyle(Color.app.textoSecundario)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Espaciado.margenPantalla)
            .padding(.vertical, Espaciado.xl)
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reducirMovimiento ? 0 : 12)
        }
        .background(alignment: .top) {
            FondoMalla()
                .frame(height: 380)
                .ignoresSafeArea()
        }
        .background(Color.app.fondo)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(Animation.app.suave) { visible = true }
        }
    }

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: Espaciado.m) {
            Image(systemName: "pawprint.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.app.textoSobrePrimario)
                .padding(Espaciado.m)
                .background(Color.app.primario, in: Forma.tarjeta)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Espaciado.xs) {
                Text("Te damos la bienvenida")
                    .font(Font.app.tituloGrande)
                    .foregroundStyle(Color.app.textoPrincipal)
                    .accessibilityAddTraits(.isHeader)
                Text("Veterinarias y estéticas de confianza, con disponibilidad real. ¿Cómo quieres entrar?")
                    .font(Font.app.cuerpo)
                    .foregroundStyle(Color.app.textoSecundario)
            }
        }
        .padding(.top, Espaciado.xl)
    }
}

private struct TarjetaRol: View {
    let rol: RolUsuario
    let accion: () -> Void

    private var titulo: String {
        switch rol {
        case .tutor: "Soy tutor"
        case .negocio: "Soy estética o veterinaria"
        }
    }

    private var detalle: String {
        switch rol {
        case .tutor: "Encuentra servicios, reserva citas y lleva la cartilla de tus mascotas."
        case .negocio: "Recibe citas, atiende a tus pacientes y muestra tu verificación."
        }
    }

    private var icono: String {
        switch rol {
        case .tutor: "pawprint.fill"
        case .negocio: "cross.case.fill"
        }
    }

    var body: some View {
        Button(action: accion) {
            TarjetaApp {
                HStack(spacing: Espaciado.m) {
                    Image(systemName: icono)
                        .font(.title2)
                        .foregroundStyle(rol == .tutor ? Color.app.primarioTinte : Color.app.saludTexto)
                        .frame(width: 56, height: 56)
                        .background(Color.app.superficieElevada, in: Forma.control)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Espaciado.xxs) {
                        Text(titulo)
                            .font(Font.app.titulo3)
                            .foregroundStyle(Color.app.textoPrincipal)
                        Text(detalle)
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.textoSecundario)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoSecundario)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.presionable)
    }
}

#Preview("Claro") {
    VistaPreviaBienvenida()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaBienvenida()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaBienvenida: View {
    @Namespace private var transicion

    var body: some View {
        NavigationStack {
            BienvenidaView(transicion: transicion) { _ in }
        }
    }
}
