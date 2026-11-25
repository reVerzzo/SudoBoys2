import SwiftUI

/// Calificación con estrellas. El número cambia con transición numérica.
struct Calificacion: View {
    enum Estilo {
        /// Una estrella y el número: para listas y pines.
        case compacta
        /// Cinco estrellas y el número: para el perfil del negocio.
        case completa
    }

    let valor: Double
    var resenas: Int?
    var estilo: Estilo = .compacta

    init(_ valor: Double, resenas: Int? = nil, estilo: Estilo = .compacta) {
        self.valor = valor
        self.resenas = resenas
        self.estilo = estilo
    }

    private var valorAcotado: Double { min(max(valor, 0), 5) }

    var body: some View {
        HStack(spacing: Espaciado.xxs) {
            estrellas
                .foregroundStyle(Color.app.estrellas)
            Text(valorAcotado, format: .number.precision(.fractionLength(1)))
                .fontWeight(.semibold)
                .foregroundStyle(Color.app.textoPrincipal)
                .monospacedDigit()
                .contentTransition(.numericText(value: valorAcotado))
            if let resenas {
                Text("(\(resenas))")
                    .foregroundStyle(Color.app.textoSecundario)
                    .contentTransition(.numericText(value: Double(resenas)))
            }
        }
        .font(Font.app.subtitulo)
        .animation(Animation.app.resorte, value: valorAcotado)
        .animation(Animation.app.resorte, value: resenas)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(etiquetaAccesible)
    }

    @ViewBuilder
    private var estrellas: some View {
        switch estilo {
        case .compacta:
            Image(systemName: "star.fill")
        case .completa:
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { posicion in
                    Image(systemName: simbolo(para: posicion))
                        .contentTransition(.symbolEffect(.replace))
                }
            }
        }
    }

    private func simbolo(para posicion: Int) -> String {
        let diferencia = valorAcotado - Double(posicion - 1)
        if diferencia >= 0.75 { return "star.fill" }
        if diferencia >= 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }

    private var etiquetaAccesible: String {
        let numero = valorAcotado.formatted(.number.precision(.fractionLength(1)))
        guard let resenas else { return "\(numero) de 5 estrellas" }
        return "\(numero) de 5 estrellas, \(resenas) reseñas"
    }
}

#Preview("Claro") {
    VistaPreviaCalificacion()
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    VistaPreviaCalificacion()
        .preferredColorScheme(.dark)
}

private struct VistaPreviaCalificacion: View {
    @State private var valor = 4.5

    var body: some View {
        VStack(spacing: Espaciado.l) {
            Calificacion(valor, resenas: 128)
            Calificacion(valor, resenas: 128, estilo: .completa)
            Calificacion(0, estilo: .completa)
            Slider(value: $valor, in: 0...5, step: 0.1)
        }
        .padding(Espaciado.margenPantalla)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.app.fondo)
    }
}
