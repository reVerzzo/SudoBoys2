import Foundation
import Observation
import UIKit

/// Alta y edición de una mascota.
@Observable
final class FormularioMascotaViewModel: Identifiable {
    var nombre: String
    var especie: Especie
    var detalleEspecie: String
    var raza: String
    var conoceNacimiento: Bool
    var nacimiento: Date
    var pesoTexto: String
    var alergias: String
    var notas: String
    private(set) var foto: Data?
    var mensajeError: String?

    /// `nil` al dar de alta.
    @ObservationIgnored private let mascota: Mascota?
    @ObservationIgnored private let tutor: Usuario?
    @ObservationIgnored private let repositorio: any MascotaRepository
    @ObservationIgnored private let alGuardar: () -> Void

    init(mascota: Mascota?, tutor: Usuario?, repositorio: any MascotaRepository, alGuardar: @escaping () -> Void) {
        self.mascota = mascota
        self.tutor = tutor
        self.repositorio = repositorio
        self.alGuardar = alGuardar
        nombre = mascota?.nombre ?? ""
        especie = mascota?.especie ?? .perro
        detalleEspecie = mascota?.detalleEspecie ?? ""
        raza = mascota?.raza ?? ""
        conoceNacimiento = mascota?.nacimiento != nil
        nacimiento = mascota?.nacimiento ?? Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
        pesoTexto = mascota?.pesoKg.map { $0.formatted(.number.precision(.fractionLength(0...1)).locale(.mx)) } ?? ""
        alergias = mascota?.alergias ?? ""
        notas = mascota?.notasComportamiento ?? ""
        foto = mascota?.foto
    }

    var esEdicion: Bool { mascota != nil }
    var titulo: String { esEdicion ? "Editar mascota" : "Nueva mascota" }

    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// `nil` si está vacío o no es un número mayor que cero.
    private var peso: Double? {
        let texto = pesoTexto.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let valor = Double(texto), valor > 0 else { return nil }
        return valor
    }

    var pesoValido: Bool { pesoTexto.trimmingCharacters(in: .whitespaces).isEmpty || peso != nil }
    var puedeGuardar: Bool { !nombreLimpio.isEmpty && pesoValido }

    /// Guarda la foto elegida, reducida para que la tarjeta cargue rápido.
    func usarFoto(_ datos: Data) {
        guard let imagen = UIImage(data: datos),
              let reducida = imagen.reducida(ladoMaximo: 900).jpegData(compressionQuality: 0.8) else {
            mensajeError = "No pudimos usar esa foto. Prueba con otra."
            return
        }
        foto = reducida
    }

    func quitarFoto() {
        foto = nil
    }

    /// Devuelve `true` si se guardó.
    func guardar() -> Bool {
        guard puedeGuardar else { return false }
        do {
            let destino = mascota ?? Mascota(nombre: nombreLimpio, especie: especie)
            destino.nombre = nombreLimpio
            destino.especie = especie
            destino.detalleEspecie = especie == .exotico ? detalleEspecie.trimmingCharacters(in: .whitespacesAndNewlines) : ""
            destino.raza = raza.trimmingCharacters(in: .whitespacesAndNewlines)
            destino.nacimiento = conoceNacimiento ? nacimiento : nil
            destino.pesoKg = peso
            destino.alergias = alergias.trimmingCharacters(in: .whitespacesAndNewlines)
            destino.notasComportamiento = notas.trimmingCharacters(in: .whitespacesAndNewlines)
            destino.foto = foto
            if mascota == nil {
                guard let tutor else {
                    mensajeError = "Inicia sesión para agregar una mascota."
                    return false
                }
                try repositorio.agregar(destino, a: tutor)
            } else {
                try repositorio.guardar()
            }
            alGuardar()
            return true
        } catch {
            mensajeError = "No pudimos guardar los datos. Inténtalo de nuevo."
            return false
        }
    }
}
