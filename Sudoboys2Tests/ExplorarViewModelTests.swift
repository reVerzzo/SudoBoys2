import Foundation
import Testing
@testable import Sudoboys2

@MainActor
@Suite("Explorar")
struct ExplorarViewModelTests {
    /// Miércoles 25 de noviembre de 2026 a la hora indicada.
    private func miercoles(hora: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: hora)))
    }

    private func explorar(_ entorno: Entorno, hora: Int = 12) throws -> ExplorarViewModel {
        let fecha = try miercoles(hora: hora)
        let viewModel = ExplorarViewModel(negocios: entorno.repos.negocios, reloj: { fecha })
        viewModel.cargar()
        return viewModel
    }

    @Test func sinFiltrosMuestraTodosDelMasCercanoAlMasLejano() throws {
        // El entorno debe seguir vivo: es dueño del contenedor de SwiftData.
        let entorno = try Entorno()
        let vm = try explorar(entorno)
        #expect(vm.resultados.count == 24)
        #expect(vm.filtrosActivos == 0)
        #expect(vm.resultados.map(\.distanciaKm) == vm.resultados.map(\.distanciaKm).sorted())
        // Todo queda a menos de 12 km de Ciudad Universitaria.
        #expect(vm.resultados.allSatisfy { $0.distanciaKm < 12 })
    }

    @Test(arguments: ExplorarViewModel.OpcionServicio.allCases)
    func filtraPorServicio(opcion: ExplorarViewModel.OpcionServicio) throws {
        // El entorno debe seguir vivo: es dueño del contenedor de SwiftData.
        let entorno = try Entorno()
        let vm = try explorar(entorno)
        vm.servicio = opcion
        #expect(vm.servicio == opcion)
        #expect(!vm.resultados.isEmpty)
        #expect(vm.filtrosActivos == (opcion == .todos ? 0 : 1))
        let tipos = Set(vm.resultados.map(\.negocio.tipo))
        switch opcion {
        case .todos: #expect(tipos == Set(TipoNegocio.allCases))
        case .estetica: #expect(tipos == [.estetica, .ambos])
        case .veterinaria: #expect(tipos == [.veterinaria, .ambos])
        case .ambos: #expect(tipos == [.ambos])
        }
    }

    @Test func losChipsSeAlternanYElContadorCambia() throws {
        // El entorno debe seguir vivo: es dueño del contenedor de SwiftData.
        let entorno = try Entorno()
        let vm = try explorar(entorno)
        vm.alternar(.exotico)
        let exoticos = vm.resultados.count
        #expect(exoticos < 24)
        #expect(vm.resultados.allSatisfy { $0.negocio.especiesAtendidas.contains(.exotico) })

        vm.filtro.soloVerificados = true
        vm.alternarCalificacion(4.5)
        #expect(vm.resultados.count < exoticos)
        #expect(vm.filtrosActivos == 3)
        #expect(vm.resultados.allSatisfy { $0.negocio.estaVerificado && $0.negocio.calificacion >= 4.5 })

        vm.alternar(.exotico)
        vm.alternarCalificacion(4.5)
        #expect(vm.filtro.especie == nil)
        #expect(vm.filtro.calificacionMinima == nil)
        #expect(vm.filtrosActivos == 1)
    }

    @Test(arguments: ExplorarViewModel.distanciasMaximasKm)
    func filtraPorDistancia(maxima: Double) throws {
        // El entorno debe seguir vivo: es dueño del contenedor de SwiftData.
        let entorno = try Entorno()
        let vm = try explorar(entorno)
        vm.alternarDistancia(maxima)
        #expect(!vm.resultados.isEmpty)
        #expect(vm.resultados.allSatisfy { $0.distanciaKm <= maxima })
        #expect(vm.filtrosActivos == 1)
    }

    @Test func abiertoAhoraYDisponibleHoy() throws {
        let entorno = try Entorno()
        let madrugada = try explorar(entorno, hora: 3)
        madrugada.filtro.abiertoAhora = true
        #expect(!madrugada.resultados.isEmpty)
        #expect(madrugada.resultados.allSatisfy { $0.negocio.horarioTexto == "Abierto 24 horas" })

        let mediodia = try explorar(entorno, hora: 12)
        mediodia.filtro.abiertoAhora = true
        #expect(mediodia.resultados.count > madrugada.resultados.count)
        mediodia.filtro.disponibleHoy = true
        #expect(mediodia.resultados.allSatisfy { $0.negocio.disponibilidadHoy > 0 })
    }

    @Test func limpiarRestauraTodoYLaSeleccionSeQuitaSiYaNoCumple() throws {
        // El entorno debe seguir vivo: es dueño del contenedor de SwiftData.
        let entorno = try Entorno()
        let vm = try explorar(entorno)
        let estetica = try #require(vm.resultados.first { $0.negocio.tipo == .estetica })
        vm.idSeleccionado = estetica.id
        #expect(vm.seleccionado?.id == estetica.id)

        vm.servicio = .veterinaria
        #expect(vm.idSeleccionado == nil)

        vm.alternarDistancia(2)
        vm.filtro.soloVerificados = true
        vm.limpiarFiltros()
        #expect(vm.resultados.count == 24)
        #expect(vm.filtrosActivos == 0)
        #expect(vm.distanciaMaximaKm == nil)
    }

    @Test func perfilDeHuellitasConServiciosYResenas() throws {
        // El entorno debe seguir vivo: es dueño del contenedor de SwiftData.
        let entorno = try Entorno()
        let vm = try explorar(entorno)
        let huellitas = try #require(vm.resultados.first { $0.negocio.nombre == "Clínica Huellitas" })
        let perfil = try #require(vm.perfil(para: huellitas.id))

        #expect(perfil === vm.perfil(para: huellitas.id))
        #expect(perfil.estaAbierto)
        #expect(perfil.gruposDeServicios.map(\.tipo) == [.estetica, .veterinaria])
        #expect(perfil.gruposDeServicios.allSatisfy { $0.servicios.map(\.precio) == $0.servicios.map(\.precio).sorted() })
        #expect(perfil.resenas.count == 2)
        #expect(perfil.textoDisponibilidad == "5 lugares hoy")
        #expect(perfil.distanciaKm == huellitas.distanciaKm)

        perfil.reservar()
        #expect(perfil.mostrandoAvisoReserva)
    }

    @Test func distanciasLegibles() {
        #expect(0.84.distanciaLegible == "850 m")
        #expect(2.44.distanciaLegible == "2.4 km")
        let cu = ExplorarViewModel.referencia
        #expect(cu.distanciaKm(a: cu) == 0)
    }
}
