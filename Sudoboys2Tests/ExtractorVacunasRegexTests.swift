import Foundation
import Testing
@testable import Sudoboys2

@Suite("ExtractorVacunasRegex")
struct ExtractorVacunasRegexTests {
    private let extractor = ExtractorVacunasRegex()

    private func partes(_ fecha: Date?) -> [Int?] {
        guard let fecha else { return [] }
        let partes = Calendar(identifier: .gregorian).dateComponents([.day, .month, .year], from: fecha)
        return [partes.day, partes.month, partes.year]
    }

    @Test func leeNombreAplicacionYProximaDosisDelMismoRenglon() {
        let vacunas = extractor.vacunas(en: "Antirrábica  12/03/2025  12/03/2026")
        #expect(vacunas.count == 1)
        #expect(vacunas.first?.nombre == "Antirrábica")
        #expect(partes(vacunas.first?.fechaAplicacion) == [12, 3, 2025])
        #expect(partes(vacunas.first?.proximaDosis) == [12, 3, 2026])
    }

    @Test func leeFechasConMesEnTextoYAnioCorto() {
        let vacunas = extractor.vacunas(en: "PARVOVIRUS 5 de enero de 2024\nBordetella 07-feb-24")
        #expect(vacunas.map(\.nombre) == ["Parvovirus", "Bordetella"])
        #expect(partes(vacunas[0].fechaAplicacion) == [5, 1, 2024])
        #expect(partes(vacunas[1].fechaAplicacion) == [7, 2, 2024])
        #expect(vacunas[0].proximaDosis == nil)
    }

    @Test func buscaLaFechaEnElRenglonSiguiente() {
        let vacunas = extractor.vacunas(en: "Triple felina\n01/02/2025\nMVZ Juan Pérez")
        #expect(vacunas.first?.nombre == "Triple felina")
        #expect(partes(vacunas.first?.fechaAplicacion) == [1, 2, 2025])
    }

    @Test func ignoraTextoSinVacunasYFechasImposibles() {
        #expect(extractor.vacunas(en: "Clínica Huellitas\nTel. 55 1234 5678").isEmpty)
        #expect(extractor.vacunas(en: "Moquillo 45/13/2025").first?.fechaAplicacion == nil)
    }
}

@Suite("ExtractorIA: cruce con el texto")
struct ExtractorIACombinarTests {
    private func dia(_ texto: String) -> Date? { ExtractorIAFoundationModels.fecha(texto) }

    @Test func laFechaNoSeRecorrePorLaZonaHoraria() throws {
        let fecha = try #require(dia("2025-02-14"))
        #expect(Calendar.current.component(.day, from: fecha) == 14)
    }

    @Test func lasFechasDelTextoMandanYSeAgregaLoOmitido() {
        let ia = [VacunaDetectada(nombre: "Parvovirus", fechaAplicacion: dia("2025-02-13"), proximaDosis: dia("2025-02-13"))]
        let texto = [
            VacunaDetectada(nombre: "Parvovirus", fechaAplicacion: dia("2025-02-14"), proximaDosis: dia("2027-02-14")),
            VacunaDetectada(nombre: "Giardia"),
        ]
        let resultado = ExtractorIAFoundationModels.combinar(ia: ia, respaldo: texto)
        #expect(resultado == texto)
    }

    @Test func descartaUnaProximaDosisQueNoEsPosterior() {
        let ia = [VacunaDetectada(nombre: "Vacuna rara", fechaAplicacion: dia("2025-02-14"), proximaDosis: dia("2025-02-14"))]
        #expect(ExtractorIAFoundationModels.combinar(ia: ia, respaldo: []).first?.proximaDosis == nil)
    }
}
