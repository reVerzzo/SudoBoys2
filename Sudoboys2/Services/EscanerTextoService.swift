import CoreGraphics
import Foundation
import Vision

/// Lee el texto de las páginas escaneadas de una cartilla.
protocol EscanerTextoService {
    /// Texto reconocido, un renglón de la cartilla por línea.
    func texto(en imagenes: [CGImage]) async throws -> String
}

/// Implementación con Vision, en el dispositivo.
struct EscanerTextoVision: EscanerTextoService {
    func texto(en imagenes: [CGImage]) async throws -> String {
        var solicitud = RecognizeTextRequest()
        solicitud.recognitionLevel = .accurate
        solicitud.usesLanguageCorrection = true
        solicitud.recognitionLanguages = [Locale.Language(identifier: "es-MX"), Locale.Language(identifier: "en-US")]

        var renglones: [String] = []
        for imagen in imagenes {
            let observaciones = try await solicitud.perform(on: imagen)
            let fragmentos = observaciones.compactMap { observacion -> Fragmento? in
                guard let texto = observacion.topCandidates(1).first?.string else { return nil }
                return Fragmento(texto: texto, caja: observacion.boundingBox.cgRect)
            }
            renglones += Self.renglones(de: fragmentos)
        }
        return renglones.joined(separator: "\n")
    }

    nonisolated struct Fragmento {
        let texto: String
        /// Coordenadas normalizadas con origen abajo a la izquierda.
        let caja: CGRect
    }

    /// Une en un renglón las celdas que están a la misma altura: en una cartilla
    /// el nombre de la vacuna y sus fechas van en columnas de la misma fila.
    nonisolated static func renglones(de fragmentos: [Fragmento]) -> [String] {
        var filas: [[Fragmento]] = []
        for fragmento in fragmentos.sorted(by: { $0.caja.midY > $1.caja.midY }) {
            if let referencia = filas.last?.first,
               abs(referencia.caja.midY - fragmento.caja.midY) < max(referencia.caja.height, fragmento.caja.height) * 0.6 {
                filas[filas.count - 1].append(fragmento)
            } else {
                filas.append([fragmento])
            }
        }
        return filas.map { fila in
            fila.sorted { $0.caja.minX < $1.caja.minX }.map(\.texto).joined(separator: "  ")
        }
    }
}
