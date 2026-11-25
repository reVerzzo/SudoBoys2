import SwiftUI

/// Genera el PDF de una receta con `ImageRenderer`, en una hoja tamaño carta.
struct GeneradorPDFReceta {
    static let anchoCarta: CGFloat = 612
    static let altoCarta: CGFloat = 792

    /// Archivo temporal con el PDF; `nil` si no se pudo generar.
    func pdf(de receta: Receta) -> URL? {
        let hoja = HojaRecetaPDF(receta: receta)
            .frame(width: Self.anchoCarta)
            .frame(minHeight: Self.altoCarta, alignment: .top)
            .background(Color.white)
            .environment(\.colorScheme, .light)
            .environment(\.locale, .mx)
            .dynamicTypeSize(.medium)

        let renderizador = ImageRenderer(content: hoja)
        renderizador.proposedSize = ProposedViewSize(width: Self.anchoCarta, height: nil)

        let mascota = (receta.mascota?.nombre ?? "mascota")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        let fecha = receta.fecha.formatted(.iso8601.year().month().day())
        let destino = FileManager.default.temporaryDirectory
            .appendingPathComponent("Receta-\(mascota)-\(fecha).pdf")

        var generado = false
        renderizador.render { tamano, dibujar in
            var caja = CGRect(origin: .zero, size: tamano)
            guard let contexto = CGContext(destino as CFURL, mediaBox: &caja, nil) else { return }
            contexto.beginPDFPage(nil)
            dibujar(contexto)
            contexto.endPDFPage()
            contexto.closePDF()
            generado = true
        }
        return generado ? destino : nil
    }
}
