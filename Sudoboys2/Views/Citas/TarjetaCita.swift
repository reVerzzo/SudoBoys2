import SwiftUI

extension Date {
    /// "Hoy, 5:00 p.m." / "Mañana, 10:30 a.m." / "vie 27 nov, 10:30 a.m.".
    var fechaCita: String {
        let hora = formatted(.dateTime.hour().minute().locale(.mx))
        let calendario = Calendar.current
        if calendario.isDateInToday(self) { return "Hoy, \(hora)" }
        if calendario.isDateInTomorrow(self) { return "Mañana, \(hora)" }
        return formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(.mx)) + ", \(hora)"
    }

    var horaCorta: String { formatted(.dateTime.hour().minute().locale(.mx)) }
}

extension String {
    /// "miércoles, 25 de noviembre" → "Miércoles, 25 de noviembre".
    var primeraMayuscula: String { prefix(1).uppercased() + dropFirst() }
}

extension EstadoCita {
    var color: Color {
        switch self {
        case .programada: Color.app.primarioTinte
        case .enCurso: Color.app.acentoTexto
        case .terminada: Color.app.saludTexto
        case .cancelada: Color.app.textoSecundario
        }
    }
}

/// Tarjeta de una cita. `paraNegocio` muestra a la mascota al frente; si no, al negocio.
struct TarjetaCita: View {
    let cita: Cita
    var paraNegocio = false

    private var titulo: String {
        paraNegocio ? cita.nombreMascota : (cita.negocio?.nombre ?? "Cita")
    }

    private var subtitulo: String {
        let servicio = cita.servicio?.nombre ?? cita.tipoServicio.titulo
        return paraNegocio ? servicio : "\(cita.nombreMascota) · \(servicio)"
    }

    var body: some View {
        TarjetaApp {
            VStack(alignment: .leading, spacing: Espaciado.s) {
                HStack(alignment: .top, spacing: Espaciado.s) {
                    AvatarMascota(
                        imagen: cita.mascota?.imagen,
                        nombre: cita.nombreMascota,
                        iconoRespaldo: cita.especie?.icono ?? "pawprint.fill",
                        tamano: 48
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titulo)
                            .font(Font.app.encabezado)
                            .foregroundStyle(Color.app.textoPrincipal)
                            .lineLimit(2)
                        Text(subtitulo)
                            .font(Font.app.subtitulo)
                            .foregroundStyle(Color.app.textoSecundario)
                            .lineLimit(2)
                        Label(cita.fecha.fechaCita, systemImage: "clock")
                            .font(Font.app.nota)
                            .foregroundStyle(Color.app.textoSecundario)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .trailing, spacing: Espaciado.xxs) {
                        Text(cita.estado.titulo)
                            .font(Font.app.etiqueta)
                            .foregroundStyle(cita.estado.color)
                            .contentTransition(.opacity)
                        if cita.esUrgencia {
                            Label("Urgencia", systemImage: "cross.case.fill")
                                .font(Font.app.etiqueta)
                                .foregroundStyle(Color.app.acentoTexto)
                        }
                    }
                }
                if cita.estado == .enCurso || cita.estado == .terminada {
                    ProgresoEtapas(etapas: cita.etapas, actual: cita.etapaActual)
                }
                if cita.estado == .enCurso {
                    Label("Listo aprox. \(cita.horaEstimadaListo.horaCorta)", systemImage: "timer")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
            }
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }
}
