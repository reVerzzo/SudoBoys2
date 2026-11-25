import SwiftUI

/// Botón principal de la app: fondo `primario` con texto blanco.
struct BotonPrincipal: View {
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
            fondo: Color.app.primario,
            colorTexto: Color.app.textoSobrePrimario,
            accion: accion
        )
    }
}

/// Base compartida por `BotonPrincipal` y `BotonAcento`: ancho completo,
/// respuesta al presionar con resorte, haptic y estados de carga y deshabilitado.
struct BotonRelleno: View {
    let titulo: String
    let icono: String?
    let cargando: Bool
    let fondo: Color
    let colorTexto: Color
    let accion: () -> Void

    @Environment(\.isEnabled) private var habilitado
    @State private var pulsaciones = 0
    /// Alto común del ícono y del indicador, para que el botón no cambie de alto al cargar.
    @ScaledMetric(relativeTo: .headline) private var altoIcono: CGFloat = 22

    var body: some View {
        Button {
            pulsaciones += 1
            accion()
        } label: {
            HStack(spacing: Espaciado.xs) {
                if cargando {
                    ProgressView()
                        .tint(colorTexto)
                        .frame(height: altoIcono)
                } else if let icono {
                    Image(systemName: icono)
                        .frame(height: altoIcono)
                        .accessibilityHidden(true)
                }
                Text(titulo)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: altoIcono)
            }
            .font(Font.app.encabezado)
            .foregroundStyle(colorTexto)
            .padding(.horizontal, Espaciado.l)
            .padding(.vertical, Espaciado.m)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(fondo, in: Forma.control)
            .contentShape(Forma.control)
            .opacity(habilitado ? 1 : 0.45)
        }
        .buttonStyle(.presionable)
        .allowsHitTesting(!cargando)
        .sensoryFeedback(.impact(weight: .light), trigger: pulsaciones)
        .animation(Animation.app.resorte, value: cargando)
        .accessibilityLabel(titulo)
        .accessibilityValue(cargando ? "Cargando" : "")
    }
}

#Preview("Claro") {
    VistaPreviaBotonPrincipal()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaBotonPrincipal()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaBotonPrincipal: View {
    var body: some View {
        VStack(spacing: Espaciado.m) {
            BotonPrincipal("Reservar cita", icono: "calendar.badge.plus") {}
            BotonPrincipal("Guardando…", cargando: true) {}
            BotonPrincipal("No disponible") {}
                .disabled(true)
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
