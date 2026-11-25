import Foundation
import Testing
@testable import Sudoboys2

@MainActor
@Suite("RecetaRepository")
struct RecetaRepositoryTests {
    private func datos(_ grupos: [GrupoMedicamento]) -> DatosReceta {
        DatosReceta(
            nombreVeterinario: "Dra. Mariana López",
            cedulaVeterinario: "8123456",
            domicilioVeterinario: "Coyoacán",
            diagnostico: "Dermatitis",
            indicaciones: "Baños medicados",
            medicamentos: grupos.map {
                DatosMedicamento(nombre: "Medicamento \($0.rawValue)", dosis: "1 tableta", cadaHoras: 12, dias: 5, grupo: $0)
            }
        )
    }

    private func cita(en negocio: Negocio, _ entorno: Entorno) throws -> Cita {
        try entorno.repos.citas.reservar(
            en: negocio, fecha: .now, tipo: negocio.tipo == .estetica ? .estetica : .veterinaria,
            servicio: nil, mascota: entorno.mascota("Firulais"), tutor: nil
        )
    }

    @Test func recetaDeEjemploApareceEnElHistorial() throws {
        let entorno = try Entorno()
        let recetas = try entorno.repos.recetas.recetas(de: entorno.mascota("Firulais"))
        let receta = try #require(recetas.first)
        #expect(recetas.count == 1)
        #expect(receta.medicamentos.count == 3)
        #expect(receta.requiereRecetaFisica)
        #expect(try entorno.repos.recetas.receta(id: receta.id) != nil)
    }

    @Test func veterinariaVerificadaEmiteRecetaLigadaALaMascota() throws {
        let entorno = try Entorno()
        let firulais = try entorno.mascota("Firulais")
        let cita = try cita(en: entorno.huellitas(), entorno)

        let receta = try entorno.repos.recetas.emitir(datos([.ventaLibre]), para: cita)

        #expect(receta.mascota?.id == firulais.id)
        #expect(receta.negocio?.nombre == "Clínica Huellitas")
        #expect(cita.receta?.id == receta.id)
        let historial = try entorno.repos.recetas.recetas(de: firulais)
        #expect(historial.count == 2)
        #expect(historial.first?.id == receta.id)
        #expect(throws: ErrorRepositorio.citaYaTieneReceta) {
            try entorno.repos.recetas.emitir(datos([.ventaLibre]), para: cita)
        }
    }

    @Test(arguments: [
        ([GrupoMedicamento.ventaLibre], false),
        ([GrupoMedicamento.ventaLibre, .recetaSimple], true),
        ([GrupoMedicamento.recetaCuantificada], true),
    ])
    func requiereRecetaFisicaSegunElGrupo(grupos: [GrupoMedicamento], esperado: Bool) throws {
        let entorno = try Entorno()
        let receta = try entorno.repos.recetas.emitir(datos(grupos), para: cita(en: entorno.huellitas(), entorno))
        #expect(receta.requiereRecetaFisica == esperado)
    }

    @Test func soloVeterinariasVerificadasEmitenRecetas() throws {
        let entorno = try Entorno()
        let negocios = try entorno.repos.negocios.todos()
        let estetica = try #require(negocios.first { $0.tipo == .estetica && $0.estaVerificado })
        let sinVerificar = try #require(negocios.first { $0.tipo == .veterinaria && !$0.estaVerificado })

        for negocio in [estetica, sinVerificar] {
            let cita = try cita(en: negocio, entorno)
            #expect(throws: ErrorRepositorio.negocioNoAutorizadoParaRecetas) {
                try entorno.repos.recetas.emitir(datos([.ventaLibre]), para: cita)
            }
        }
        #expect(try entorno.contar(Receta.self) == 1)
    }
}
