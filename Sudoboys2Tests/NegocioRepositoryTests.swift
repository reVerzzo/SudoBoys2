import Foundation
import Testing
@testable import Sudoboys2

@MainActor
@Suite("NegocioRepository")
struct NegocioRepositoryTests {
    /// Miércoles 25 de noviembre de 2026 a la hora indicada, hora local.
    private func miercoles(hora: Int) throws -> Date {
        let fecha = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: hora))
        return try #require(fecha)
    }

    @Test func sinFiltroDevuelveTodosPorNombre() throws {
        let entorno = try Entorno()
        let todos = try entorno.repos.negocios.todos()
        let filtrados = try entorno.repos.negocios.buscar(FiltroNegocios(), fecha: .now)
        #expect(filtrados.count == todos.count)
        #expect(todos.map(\.nombre) == todos.map(\.nombre).sorted())
    }

    @Test(arguments: TipoServicio.allCases)
    func filtraPorServicio(servicio: TipoServicio) throws {
        let entorno = try Entorno()
        let resultado = try entorno.repos.negocios.buscar(FiltroNegocios(servicio: servicio), fecha: .now)
        #expect(!resultado.isEmpty)
        #expect(resultado.allSatisfy { $0.tipo.ofrece(servicio) })
        // Un negocio "ambos" aparece en los dos filtros.
        #expect(resultado.contains { $0.tipo == .ambos })
    }

    @Test(arguments: Especie.allCases)
    func filtraPorEspecie(especie: Especie) throws {
        let entorno = try Entorno()
        let resultado = try entorno.repos.negocios.buscar(FiltroNegocios(especie: especie), fecha: .now)
        #expect(!resultado.isEmpty)
        #expect(resultado.allSatisfy { $0.especiesAtendidas.contains(especie) })
    }

    @Test func combinaVerificadoDisponibleYCalificacion() throws {
        let entorno = try Entorno()
        let filtro = FiltroNegocios(soloVerificados: true, disponibleHoy: true, calificacionMinima: 4.5)
        let resultado = try entorno.repos.negocios.buscar(filtro, fecha: .now)
        #expect(!resultado.isEmpty)
        #expect(resultado.count < (try entorno.repos.negocios.todos().count))
        #expect(resultado.allSatisfy { $0.estaVerificado && $0.disponibilidadHoy > 0 && $0.calificacion >= 4.5 })
    }

    @Test func abiertoAhoraDependeDeLaHora() throws {
        let entorno = try Entorno()
        let filtro = FiltroNegocios(abiertoAhora: true)
        let mediodia = try entorno.repos.negocios.buscar(filtro, fecha: miercoles(hora: 12))
        let madrugada = try entorno.repos.negocios.buscar(filtro, fecha: miercoles(hora: 3))

        #expect(mediodia.count > madrugada.count)
        // De madrugada solo quedan los de 24 horas, entre ellos Clínica Huellitas.
        #expect(!madrugada.isEmpty)
        #expect(madrugada.allSatisfy { $0.horarioTexto == "Abierto 24 horas" })
        #expect(madrugada.contains { $0.nombre == "Clínica Huellitas" })
    }

    @Test func aprobarCedulaVerificaElNegocio() throws {
        let entorno = try Entorno(sembrado: false)
        let negocio = Negocio(
            nombre: "Vet Nueva", tipo: .veterinaria, especiesAtendidas: [.perro],
            latitud: 19.33, longitud: -99.18, direccion: "CU"
        )
        try entorno.repos.negocios.crear(negocio, propietario: nil)
        #expect(!negocio.puedeEmitirRecetas)
        #expect(negocio.insignia == nil)

        try entorno.repos.negocios.actualizarVerificacion(de: negocio, a: .enRevision, cedula: "1234567")
        #expect(!negocio.puedeEmitirRecetas)

        try entorno.repos.negocios.actualizarVerificacion(de: negocio, a: .verificado, cedula: nil)
        #expect(negocio.puedeEmitirRecetas)
        #expect(negocio.insignia == .cedulaVerificada)
        #expect(try entorno.repos.negocios.negocio(id: negocio.id)?.cedula == "1234567")
    }
}
