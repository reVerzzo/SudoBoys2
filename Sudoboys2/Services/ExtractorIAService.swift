import Foundation
import FoundationModels
import OSLog

/// Vacuna leída de una cartilla, antes de que el tutor la confirme.
nonisolated struct VacunaDetectada: Equatable, Sendable {
    var nombre: String
    var fechaAplicacion: Date?
    var proximaDosis: Date?
}

nonisolated enum MetodoExtraccion: Sendable {
    /// Foundation Models en el dispositivo.
    case appleIntelligence
    /// Expresiones regulares: cuando Apple Intelligence no está disponible.
    case respaldo
}

nonisolated struct ResultadoExtraccion: Sendable {
    var vacunas: [VacunaDetectada]
    var metodo: MetodoExtraccion
}

/// Convierte el texto de una cartilla en vacunas con fechas.
protocol ExtractorIAService {
    /// Nunca falla: si la IA no está disponible o se equivoca, usa el respaldo.
    func extraer(de texto: String) async -> ResultadoExtraccion
}

@Generable
nonisolated struct CartillaGenerada {
    @Guide(description: "Vacunas aplicadas que aparecen en el texto de la cartilla, sin inventar ninguna")
    var vacunas: [VacunaGenerada]
}

@Generable
nonisolated struct VacunaGenerada {
    @Guide(description: "Nombre de la vacuna tal como aparece, por ejemplo Antirrábica o Múltiple")
    var nombre: String
    @Guide(description: "Fecha de aplicación en formato AAAA-MM-DD. Cadena vacía si no aparece")
    var fechaAplicacion: String
    @Guide(description: "Fecha de la próxima dosis o refuerzo en formato AAAA-MM-DD. Cadena vacía si no aparece")
    var proximaDosis: String
}

/// Foundation Models con salida guiada; cae a expresiones regulares si hace falta.
struct ExtractorIAFoundationModels: ExtractorIAService {
    private let respaldo = ExtractorVacunasRegex()
    private let registro = Logger(subsystem: "Sudoboys2", category: "ExtractorIA")

    func extraer(de texto: String) async -> ResultadoExtraccion {
        let porRespaldo = ResultadoExtraccion(vacunas: respaldo.vacunas(en: texto), metodo: .respaldo)
        guard case .available = SystemLanguageModel.default.availability else { return porRespaldo }
        do {
            let sesion = LanguageModelSession(instructions: """
                Eres un asistente que lee cartillas de vacunación de mascotas en México. \
                Las fechas suelen venir como día/mes/año. Extrae solo las vacunas que aparecen en el texto.
                """)
            let respuesta = try await sesion.respond(
                to: "Extrae las vacunas y sus fechas de esta cartilla:\n\n\(texto.prefix(4000))",
                generating: CartillaGenerada.self
            )
            let deLaIA = respuesta.content.vacunas.compactMap(Self.detectada)
            let vacunas = Self.combinar(ia: deLaIA, respaldo: porRespaldo.vacunas)
            return vacunas.isEmpty ? porRespaldo : ResultadoExtraccion(vacunas: vacunas, metodo: .appleIntelligence)
        } catch {
            registro.error("Foundation Models falló, se usa el respaldo: \(error.localizedDescription, privacy: .public)")
            return porRespaldo
        }
    }

    private static func detectada(_ generada: VacunaGenerada) -> VacunaDetectada? {
        let nombre = generada.nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nombre.isEmpty else { return nil }
        return VacunaDetectada(
            nombre: nombre,
            fechaAplicacion: fecha(generada.fechaAplicacion),
            proximaDosis: fecha(generada.proximaDosis)
        )
    }

    /// Fecha "AAAA-MM-DD" al mediodía local, para que no se recorra un día por la zona horaria.
    nonisolated static func fecha(_ texto: String) -> Date? {
        let partes = texto.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "-").compactMap { Int($0) }
        guard partes.count == 3 else { return nil }
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = .current
        let componentes = DateComponents(calendar: calendario, year: partes[0], month: partes[1], day: partes[2], hour: 12)
        return componentes.isValidDate ? componentes.date : nil
    }

    /// Cruza lo que entendió el modelo con lo que dice el texto: las fechas leídas tal cual
    /// del renglón mandan sobre las del modelo, y se agregan las vacunas que el modelo omitió.
    nonisolated static func combinar(ia: [VacunaDetectada], respaldo: [VacunaDetectada]) -> [VacunaDetectada] {
        func clave(_ nombre: String) -> String {
            nombre.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_MX")).lowercased()
        }
        func coinciden(_ a: String, _ b: String) -> Bool {
            let a = clave(a), b = clave(b)
            return a.contains(b) || b.contains(a)
        }
        var pendientes = respaldo
        var resultado: [VacunaDetectada] = ia.map { vacuna in
            var vacuna = vacuna
            if let indice = pendientes.firstIndex(where: { coinciden($0.nombre, vacuna.nombre) }) {
                let delTexto = pendientes.remove(at: indice)
                if delTexto.fechaAplicacion != nil {
                    vacuna.fechaAplicacion = delTexto.fechaAplicacion
                    vacuna.proximaDosis = delTexto.proximaDosis
                }
            }
            // La próxima dosis siempre es posterior a la aplicación.
            if let aplicacion = vacuna.fechaAplicacion, let proxima = vacuna.proximaDosis, proxima <= aplicacion {
                vacuna.proximaDosis = nil
            }
            return vacuna
        }
        resultado += pendientes
        return resultado
    }
}

/// Respaldo sin IA: busca nombres de vacunas conocidas y las fechas de su renglón.
nonisolated struct ExtractorVacunasRegex {
    /// Clave sin acentos y en minúsculas → nombre que se muestra. El orden importa: gana la primera.
    private static let catalogo: [(clave: String, nombre: String)] = [
        ("antirrabica", "Antirrábica"), ("rabia", "Antirrábica"),
        ("triple felina", "Triple felina"), ("leucemia", "Leucemia felina"),
        ("sextuple", "Séxtuple"), ("quintuple", "Quíntuple"), ("multiple", "Múltiple"),
        ("polivalente", "Polivalente"), ("dhpp", "Múltiple"), ("puppy", "Puppy"),
        ("parvovirus", "Parvovirus"), ("moquillo", "Moquillo"), ("bordetella", "Bordetella"),
        ("leptospir", "Leptospirosis"), ("giardia", "Giardia"), ("coronavirus", "Coronavirus"),
        ("influenza", "Influenza"), ("mixomatosis", "Mixomatosis"), ("hemorragica", "Hemorrágica vírica"),
        ("triple", "Triple"),
    ]

    private static let meses = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]

    func vacunas(en texto: String) -> [VacunaDetectada] {
        let lineas = texto
            .components(separatedBy: .newlines)
            .map { $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_MX")).lowercased() }

        var resultado: [VacunaDetectada] = []
        for (indice, linea) in lineas.enumerated() {
            guard let nombre = Self.nombre(en: linea) else { continue }
            var fechas = fechas(en: linea)
            // Si el lector separó las columnas, las fechas quedan en los renglones siguientes.
            var siguiente = indice + 1
            while fechas.isEmpty, siguiente < lineas.count, siguiente <= indice + 2, Self.nombre(en: lineas[siguiente]) == nil {
                fechas = self.fechas(en: lineas[siguiente])
                siguiente += 1
            }
            let ordenadas = fechas.sorted()
            let vacuna = VacunaDetectada(
                nombre: nombre,
                fechaAplicacion: ordenadas.first,
                proximaDosis: ordenadas.count > 1 ? ordenadas.last : nil
            )
            if !resultado.contains(vacuna) { resultado.append(vacuna) }
        }
        return resultado
    }

    private static func nombre(en linea: String) -> String? {
        catalogo.first { linea.contains($0.clave) }?.nombre
    }

    /// Fechas de la línea (ya sin acentos y en minúsculas), en el orden en que aparecen.
    func fechas(en linea: String) -> [Date] {
        var encontradas: [(posicion: String.Index, fecha: Date)] = []

        // 12/03/2024, 12-03-24, 12.03.2024
        let numerica = /\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4}|\d{2})\b/
        for coincidencia in linea.matches(of: numerica) {
            if let fecha = fecha(dia: coincidencia.1, mes: Int(coincidencia.2), anio: coincidencia.3) {
                encontradas.append((coincidencia.range.lowerBound, fecha))
            }
        }

        // 12 de marzo de 2024, 12 mar 2024, 12/mar/24
        let textual = /\b(\d{1,2})[\s\/\-.]*(?:de\s+)?(ene|feb|mar|abr|may|jun|jul|ago|sep|set|oct|nov|dic)[a-z]*[\s\/\-.]*(?:de\s+|del\s+)?(\d{4}|\d{2})\b/
        for coincidencia in linea.matches(of: textual) {
            let clave = coincidencia.2 == "set" ? "sep" : String(coincidencia.2)
            let mes = Self.meses.firstIndex(of: clave).map { $0 + 1 }
            if let fecha = fecha(dia: coincidencia.1, mes: mes, anio: coincidencia.3) {
                encontradas.append((coincidencia.range.lowerBound, fecha))
            }
        }
        return encontradas.sorted { $0.posicion < $1.posicion }.map(\.fecha)
    }

    private func fecha(dia: Substring, mes: Int?, anio: Substring) -> Date? {
        guard let dia = Int(dia), let mes, var anio = Int(anio) else { return nil }
        if anio < 100 { anio += 2000 }
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = .current
        let partes = DateComponents(calendar: calendario, year: anio, month: mes, day: dia, hour: 12)
        guard partes.isValidDate else { return nil }
        return partes.date
    }
}
