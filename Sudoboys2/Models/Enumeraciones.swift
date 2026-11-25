import Foundation

nonisolated enum RolUsuario: String, Codable, CaseIterable, Sendable {
    case tutor
    case negocio

    var titulo: String {
        switch self {
        case .tutor: "Tutor"
        case .negocio: "Negocio"
        }
    }

    var otro: RolUsuario {
        switch self {
        case .tutor: .negocio
        case .negocio: .tutor
        }
    }
}

nonisolated enum ProveedorAuth: String, Codable, CaseIterable, Sendable {
    case google
    case apple
    case demo
}

nonisolated enum Especie: String, Codable, CaseIterable, Sendable {
    case perro
    case gato
    case exotico

    var titulo: String {
        switch self {
        case .perro: "Perro"
        case .gato: "Gato"
        case .exotico: "Exótico"
        }
    }

    var tituloPlural: String {
        switch self {
        case .perro: "Perros"
        case .gato: "Gatos"
        case .exotico: "Exóticos"
        }
    }

    var icono: String {
        switch self {
        case .perro: "dog.fill"
        case .gato: "cat.fill"
        case .exotico: "hare.fill"
        }
    }
}

/// Lo que se hace en una cita o servicio.
nonisolated enum TipoServicio: String, Codable, CaseIterable, Sendable {
    case estetica
    case veterinaria

    var titulo: String {
        switch self {
        case .estetica: "Estética"
        case .veterinaria: "Veterinaria"
        }
    }

    var icono: String {
        switch self {
        case .estetica: "scissors"
        case .veterinaria: "stethoscope"
        }
    }
}

nonisolated enum TipoNegocio: String, Codable, CaseIterable, Sendable {
    case estetica
    case veterinaria
    case ambos

    var titulo: String {
        switch self {
        case .estetica: "Estética"
        case .veterinaria: "Veterinaria"
        case .ambos: "Veterinaria y estética"
        }
    }

    var tituloCorto: String {
        switch self {
        case .estetica: "Estética"
        case .veterinaria: "Veterinaria"
        case .ambos: "Ambos"
        }
    }

    var icono: String {
        switch self {
        case .estetica: "scissors"
        case .veterinaria: "stethoscope"
        case .ambos: "cross.case.fill"
        }
    }

    func ofrece(_ servicio: TipoServicio) -> Bool {
        switch (self, servicio) {
        case (.ambos, _), (.estetica, .estetica), (.veterinaria, .veterinaria): true
        default: false
        }
    }
}

nonisolated enum EstadoVerificacion: String, Codable, CaseIterable, Sendable {
    case pendiente
    case enRevision
    case verificado

    var titulo: String {
        switch self {
        case .pendiente: "Pendiente"
        case .enRevision: "En revisión"
        case .verificado: "Verificado"
        }
    }
}

/// Insignia de confianza que muestra un negocio verificado.
nonisolated enum InsigniaNegocio: Sendable {
    /// Veterinaria con cédula profesional verificada.
    case cedulaVerificada
    /// Estética verificada.
    case negocioVerificado
}

nonisolated enum RegistradaPor: String, Codable, CaseIterable, Sendable {
    case tutor
    case veterinario

    var titulo: String {
        switch self {
        case .tutor: "Registrada por el tutor"
        case .veterinario: "Registrada por veterinario"
        }
    }
}

nonisolated enum EstadoCita: String, Codable, CaseIterable, Sendable {
    case programada
    case enCurso
    case terminada
    case cancelada

    var titulo: String {
        switch self {
        case .programada: "Programada"
        case .enCurso: "En curso"
        case .terminada: "Terminada"
        case .cancelada: "Cancelada"
        }
    }
}

nonisolated enum EtapaCita: String, Codable, CaseIterable, Sendable {
    case recibido
    case bano
    case secado
    case corte
    case consulta
    case tratamiento
    case listo

    var titulo: String {
        switch self {
        case .recibido: "Recibido"
        case .bano: "Baño"
        case .secado: "Secado"
        case .corte: "Corte"
        case .consulta: "Consulta"
        case .tratamiento: "Tratamiento"
        case .listo: "Listo"
        }
    }

    var icono: String {
        switch self {
        case .recibido: "checkmark.circle.fill"
        case .bano: "shower.fill"
        case .secado: "wind"
        case .corte: "scissors"
        case .consulta: "stethoscope"
        case .tratamiento: "cross.case.fill"
        case .listo: "pawprint.fill"
        }
    }

    /// Etapas en orden según el tipo de servicio.
    static func flujo(para tipo: TipoServicio) -> [EtapaCita] {
        switch tipo {
        case .estetica: [.recibido, .bano, .secado, .corte, .listo]
        case .veterinaria: [.recibido, .consulta, .tratamiento, .listo]
        }
    }
}

/// Grupos de medicamentos veterinarios según la NOM-064-ZOO-2000.
nonisolated enum GrupoMedicamento: String, Codable, CaseIterable, Sendable {
    /// Grupo III: venta libre.
    case ventaLibre
    /// Grupo II: receta médica simple.
    case recetaSimple
    /// Grupo I: receta médica cuantificada.
    case recetaCuantificada

    var titulo: String {
        switch self {
        case .ventaLibre: "Venta libre"
        case .recetaSimple: "Receta simple"
        case .recetaCuantificada: "Receta cuantificada"
        }
    }

    /// Los grupos I y II solo se surten con la receta física del veterinario.
    var requiereRecetaFisica: Bool {
        self != .ventaLibre
    }
}
