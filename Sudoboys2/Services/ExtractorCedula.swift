import Foundation

/// Nombre y número leídos de la foto de una cédula profesional.
nonisolated struct DatosCedula: Equatable, Sendable {
    var nombre: String?
    var numero: String?
}

/// Busca el número (7 u 8 dígitos) y el nombre del titular en el texto del OCR.
nonisolated struct ExtractorCedula {
    /// Palabras impresas en la cédula que no son parte del nombre.
    private static let ajenas = [
        "SECRETAR", "EDUCACI", "PÚBLICA", "PUBLICA", "CÉDULA", "CEDULA", "PROFESIONAL", "DIRECCI",
        "GENERAL", "PROFESIONES", "ESTADOS", "UNIDOS", "MEXICANOS", "MÉXICO", "MEXICO", "LICENCIA",
        "MÉDIC", "MEDIC", "VETERINARI", "ZOOTECNI", "FIRMA", "TITULAR", "CURP", "NOMBRE", "EFECTOS",
        "PATENTE", "NIVEL", "UNIVERSIDAD", "FACULTAD", "MUESTRA", "PRUEBA", "TÍTULO", "TITULO",
    ]

    func extraer(de texto: String) -> DatosCedula {
        let lineas = texto
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return DatosCedula(nombre: nombre(en: lineas), numero: numero(en: lineas))
    }

    private func numero(en lineas: [String]) -> String? {
        func candidatos(_ linea: String) -> [String] {
            linea.matches(of: /\b\d{7,8}\b/).map { String($0.output) }
        }
        // Primero el renglón que menciona la cédula (o el siguiente); si no, el primero que aparezca.
        for (indice, linea) in lineas.enumerated() where linea.localizedCaseInsensitiveContains("dula") {
            if let numero = candidatos(linea).first { return numero }
            if indice + 1 < lineas.count, let numero = candidatos(lineas[indice + 1]).first { return numero }
        }
        return lineas.lazy.compactMap { candidatos($0).first }.first
    }

    private func nombre(en lineas: [String]) -> String? {
        // "NOMBRE: MARIANA LÓPEZ" o el renglón que sigue a "NOMBRE".
        for (indice, linea) in lineas.enumerated() where linea.uppercased().hasPrefix("NOMBRE") {
            let resto = linea.dropFirst("NOMBRE".count).trimmingCharacters(in: CharacterSet(charactersIn: ":.- ").union(.whitespaces))
            if esNombre(resto) { return formato(resto) }
            if indice + 1 < lineas.count, esNombre(lineas[indice + 1]) { return formato(lineas[indice + 1]) }
        }
        // Si no, el renglón más largo que parezca un nombre propio.
        return lineas
            .filter { esNombre($0) && !contieneAjenas($0) }
            .max { $0.count < $1.count }
            .map(formato)
    }

    private func contieneAjenas(_ linea: String) -> Bool {
        let mayusculas = linea.uppercased()
        return Self.ajenas.contains { mayusculas.contains($0) }
    }

    private func esNombre(_ linea: String) -> Bool {
        let palabras = linea.split(separator: " ")
        guard (2...6).contains(palabras.count) else { return false }
        return linea.allSatisfy { $0.isLetter || $0 == " " || $0 == "." }
    }

    private func formato(_ linea: String) -> String {
        linea.lowercased().capitalized(with: Locale(identifier: "es_MX"))
    }
}
