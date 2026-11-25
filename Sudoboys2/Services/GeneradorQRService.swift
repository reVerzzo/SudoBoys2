import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins

/// Genera el código QR de la tarjeta de la mascota.
protocol GeneradorQRService {
    /// Imagen del QR con `texto`; `nil` si no se pudo generar.
    func imagenQR(para texto: String) -> CGImage?
}

/// Implementación con Core Image: funciona sin internet.
struct GeneradorQRCoreImage: GeneradorQRService {
    private let contexto = CIContext()

    func imagenQR(para texto: String) -> CGImage? {
        let filtro = CIFilter.qrCodeGenerator()
        filtro.message = Data(texto.utf8)
        filtro.correctionLevel = "M"
        guard let salida = filtro.outputImage else { return nil }
        // Se amplía sin suavizar para que los módulos queden nítidos.
        let ampliada = salida.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        return contexto.createCGImage(ampliada, from: ampliada.extent)
    }
}
