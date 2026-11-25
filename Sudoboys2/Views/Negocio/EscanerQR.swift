import AVFoundation
import SwiftUI
import Vision
import VisionKit

/// Lector de QR en vivo con `DataScannerViewController`. Entrega el texto de cada código leído.
struct EscanerQR: UIViewControllerRepresentable {
    let alLeer: (String) -> Void

    /// Falso en el simulador y en equipos sin soporte.
    static var soportado: Bool { DataScannerViewController.isSupported }

    /// Pide permiso de cámara si hace falta y dice si ya se puede escanear.
    static func prepararCamara() async -> Bool {
        guard soportado else { return false }
        guard await AVCaptureDevice.requestAccess(for: .video) else { return false }
        return DataScannerViewController.isAvailable
    }

    func makeCoordinator() -> Coordinador {
        Coordinador(alLeer: alLeer)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controlador = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        controlador.delegate = context.coordinator
        try? controlador.startScanning()
        return controlador
    }

    func updateUIViewController(_ controlador: DataScannerViewController, context: Context) {}

    static func dismantleUIViewController(_ controlador: DataScannerViewController, coordinator: Coordinador) {
        controlador.stopScanning()
    }

    final class Coordinador: NSObject, DataScannerViewControllerDelegate {
        private let alLeer: (String) -> Void
        private var ultimoCodigo: String?
        private var ultimaLectura = Date.distantPast

        init(alLeer: @escaping (String) -> Void) {
            self.alLeer = alLeer
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            procesar(addedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            ultimoCodigo = nil
            procesar([item])
        }

        private func procesar(_ items: [RecognizedItem]) {
            for item in items {
                guard case .barcode(let codigo) = item, let texto = codigo.payloadStringValue else { continue }
                // El mismo código no se repite antes de dos segundos.
                if texto == ultimoCodigo, Date.now.timeIntervalSince(ultimaLectura) < 2 { continue }
                ultimoCodigo = texto
                ultimaLectura = .now
                alLeer(texto)
                return
            }
        }
    }
}

/// Cámara del sistema para la foto final.
struct CamaraFoto: UIViewControllerRepresentable {
    let alTerminar: (Data?) -> Void

    static var disponible: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeCoordinator() -> Coordinador { Coordinador(alTerminar: alTerminar) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controlador = UIImagePickerController()
        controlador.sourceType = .camera
        controlador.delegate = context.coordinator
        return controlador
    }

    func updateUIViewController(_ controlador: UIImagePickerController, context: Context) {}

    final class Coordinador: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let alTerminar: (Data?) -> Void

        init(alTerminar: @escaping (Data?) -> Void) {
            self.alTerminar = alTerminar
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let imagen = info[.originalImage] as? UIImage
            alTerminar(imagen?.jpegData(compressionQuality: 0.9))
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            alTerminar(nil)
        }
    }
}
