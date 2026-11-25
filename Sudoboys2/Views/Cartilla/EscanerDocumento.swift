import SwiftUI
import VisionKit

/// Cámara de documentos de VisionKit. Entrega las páginas escaneadas; vacío si se canceló.
struct EscanerDocumento: UIViewControllerRepresentable {
    let alTerminar: ([UIImage]) -> Void

    /// La cámara de documentos no existe en el simulador y necesita el texto de permiso de cámara.
    static var disponible: Bool {
        let permiso = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String ?? ""
        return VNDocumentCameraViewController.isSupported && !permiso.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func makeCoordinator() -> Coordinador {
        Coordinador(alTerminar: alTerminar)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controlador = VNDocumentCameraViewController()
        controlador.delegate = context.coordinator
        return controlador
    }

    func updateUIViewController(_ controlador: VNDocumentCameraViewController, context: Context) {}

    final class Coordinador: NSObject, VNDocumentCameraViewControllerDelegate {
        private let alTerminar: ([UIImage]) -> Void

        init(alTerminar: @escaping ([UIImage]) -> Void) {
            self.alTerminar = alTerminar
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            alTerminar((0..<scan.pageCount).map(scan.imageOfPage(at:)))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            alTerminar([])
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: any Error) {
            alTerminar([])
        }
    }
}
