import Foundation
import SwiftData
import Testing
@testable import Sudoboys2

@MainActor
@Suite("Datos de ejemplo")
struct SeedDataTests {
    @Test func siembraEntre20Y30Negocios() throws {
        let entorno = try Entorno()
        let negocios = try entorno.repos.negocios.todos()
        #expect((20...30).contains(negocios.count))
        #expect(Set(negocios.map(\.tipo)) == Set(TipoNegocio.allCases))
        #expect(Set(negocios.map(\.estadoVerificacion)) == Set(EstadoVerificacion.allCases))
        #expect(negocios.allSatisfy { !$0.servicios.isEmpty })
        // Sur de CDMX
        #expect(negocios.allSatisfy { (19.25...19.37).contains($0.latitud) && (-99.22 ... -99.11).contains($0.longitud) })
    }

    @Test func tutorDemoTieneAFirulaisYMochi() throws {
        let entorno = try Entorno()
        let tutor = try entorno.tutor()
        #expect(tutor.rol == .tutor)
        #expect(Set(tutor.mascotas.map(\.nombre)) == ["Firulais", "Mochi"])

        let firulais = try entorno.mascota("Firulais")
        #expect(firulais.especie == .perro)
        #expect(!firulais.vacunas.isEmpty)
        #expect(firulais.recetas.count == 1)
        #expect(firulais.proximaVacuna()?.nombre == "Antirrábica")

        let mochi = try entorno.mascota("Mochi")
        #expect(mochi.especie == .exotico)
        #expect(mochi.detalleEspecie == "Conejo")
        #expect(!mochi.vacunas.isEmpty)
    }

    @Test func clinicaHuellitasEsAmbosYVerificada() throws {
        let entorno = try Entorno()
        let huellitas = try entorno.huellitas()
        #expect(huellitas.nombre == "Clínica Huellitas")
        #expect(huellitas.tipo == .ambos)
        #expect(huellitas.estaVerificado)
        #expect(huellitas.puedeEmitirRecetas)
        #expect(huellitas.insignia == .cedulaVerificada)
        #expect(huellitas.resenas.count == 2)
    }

    @Test func sembrarDosVecesNoDuplica() throws {
        let entorno = try Entorno()
        let negocios = try entorno.contar(Negocio.self)
        let usuarios = try entorno.contar(Usuario.self)
        try SeedData.sembrarSiHaceFalta(en: entorno.contexto)
        #expect(try entorno.contar(Negocio.self) == negocios)
        #expect(try entorno.contar(Usuario.self) == usuarios)
        #expect(usuarios == 2)
    }
}
