import SwiftUI

/// Tarjeta de un negocio en la lista de Explorar y bajo el mapa.
struct TarjetaNegocio: View {
    let resultado: ResultadoNegocio
    let ahora: Date

    private var negocio: Negocio { resultado.negocio }
    private var abierto: Bool { negocio.estaAbierto(en: ahora) }

    var body: some View {
        TarjetaApp {
            HStack(alignment: .top, spacing: Espaciado.s) {
                Image(systemName: negocio.tipo.icono)
                    .font(.title3)
                    .foregroundStyle(negocio.tipo.colorIcono)
                    .frame(width: 52, height: 52)
                    .background(negocio.tipo.colorFondo, in: Forma.control)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Espaciado.xxs) {
                    Text(negocio.nombre)
                        .font(Font.app.encabezado)
                        .foregroundStyle(Color.app.textoPrincipal)
                        .multilineTextAlignment(.leading)
                    Text("\(negocio.tipo.titulo) · \(resultado.distanciaKm.distanciaLegible)")
                        .font(Font.app.subtitulo)
                        .foregroundStyle(Color.app.textoSecundario)
                    HStack(spacing: Espaciado.xs) {
                        Calificacion(negocio.calificacion)
                        Text(abierto ? "Abierto" : "Cerrado")
                            .font(Font.app.etiqueta)
                            .foregroundStyle(abierto ? Color.app.saludTexto : Color.app.textoSecundario)
                        if negocio.disponibleHoy {
                            Text("· Lugares hoy")
                                .font(Font.app.etiqueta)
                                .foregroundStyle(Color.app.textoSecundario)
                        }
                    }
                    if let insignia = negocio.insignia {
                        InsigniaVerificado(insignia == .cedulaVerificada ? .cedula : .negocio)
                            .padding(.top, Espaciado.xxs)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(Font.app.subtitulo.weight(.semibold))
                    .foregroundStyle(Color.app.textoSecundario)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Claro") {
    VistaPreviaTarjetaNegocio()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaTarjetaNegocio()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaTarjetaNegocio: View {
    private let resultados = VistaPrevia.explorar().resultados.prefix(3)

    var body: some View {
        ScrollView {
            VStack(spacing: Espaciado.m) {
                ForEach(resultados) { resultado in
                    TarjetaNegocio(resultado: resultado, ahora: .now)
                }
            }
            .padding(Espaciado.margenPantalla)
        }
        .background(Color.app.fondo)
    }
}
