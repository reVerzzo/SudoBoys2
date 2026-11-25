import Foundation

extension Sequence where Element == String {
    /// "a, b y c": lista en español de México, sin depender del idioma del dispositivo.
    var listaEnEspanol: String {
        Array(self).formatted(.list(type: .and).locale(Locale(identifier: "es_MX")))
    }
}
