import UIKit

extension UIImage {
    /// Copia derecha (sin orientación EXIF) cuyo lado mayor no pasa de `ladoMaximo`.
    func reducida(ladoMaximo: CGFloat) -> UIImage {
        let mayor = max(size.width, size.height)
        guard mayor > 0 else { return self }
        let escala = min(1, ladoMaximo / mayor)
        let tamano = CGSize(width: (size.width * escala).rounded(), height: (size.height * escala).rounded())
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: tamano, format: formato).image { _ in
            draw(in: CGRect(origin: .zero, size: tamano))
        }
    }
}
