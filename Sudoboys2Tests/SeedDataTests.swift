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

    @Test func dejaLaCitaDeHoyDeMochiPendienteDeCheckIn() throws {
        let entorno = try Entorno()
        let huellitas = try entorno.huellitas()
        let hoy = try entorno.repos.citas.agenda(de: huellitas, dia: .now)
        let cita = try #require(hoy.first)
        #expect(hoy.count == 1)
        #expect(cita.mascota?.nombre == "Mochi")
        #expect(cita.estado == .programada)
        #expect(cita.indiceEtapa == nil)
        #expect(cita.etapas.map(\.titulo) == ["Recibido", "Revisión", "Diagnóstico", "Listo"])
        #expect(cita.tipoServicio == .veterinaria)
        #expect(cita.tutor?.id == (try entorno.tutor()).id)
        // El QR de Mochi encuentra su cita.
        #expect(huellitas.especiesAtendidas.contains(.exotico))
        #expect(cita.mascota?.id == SeedData.idMochi)
    }

    @Test func otroDiaLaCitaDeLaDemoSeTraeAHoy() throws {
        let entorno = try Entorno()
        let huellitas = try entorno.huellitas()
        let manana = try #require(Calendar.current.date(byAdding: .day, value: 1, to: .now))

        try SeedData.asegurarCitaDeHoy(en: entorno.contexto, ahora: manana)
        let agenda = try entorno.repos.citas.agenda(de: huellitas, dia: manana)
        #expect(agenda.count == 1)
        #expect(agenda.first?.estado == .programada)
        #expect(try entorno.repos.citas.agenda(de: huellitas, dia: .now).isEmpty)

        // Repetirlo no duplica.
        try SeedData.asegurarCitaDeHoy(en: entorno.contexto, ahora: manana)
        #expect(try entorno.repos.citas.agenda(de: huellitas, dia: manana).count == 1)
    }

    @Test func siLaCitaYaSeAtendioAlDiaSiguienteHayUnaNueva() throws {
        let entorno = try Entorno()
        let huellitas = try entorno.huellitas()
        let citas = entorno.repos.citas
        let deHoy = try #require(try citas.agenda(de: huellitas, dia: .now).first)
        try citas.registrarLlegada(deHoy)

        let manana = try #require(Calendar.current.date(byAdding: .day, value: 1, to: .now))
        try SeedData.asegurarCitaDeHoy(en: entorno.contexto, ahora: manana)
        let nueva = try #require(try citas.agenda(de: huellitas, dia: manana).first)
        #expect(nueva.id != deHoy.id)
        #expect(nueva.estado == .programada)
        #expect(nueva.mascota?.nombre == "Mochi")
    }
}

@MainActor
@Suite("Restablecer datos de demo")
struct DatosDemoTests {
    @Test func borraTodoYVuelveASembrar() throws {
        let entorno = try Entorno()
        let negocios = try entorno.contar(Negocio.self)
        let citasIniciales = try entorno.contar(Cita.self)
        let huellitas = try entorno.huellitas()

        // Cambios de una demo: check-in, cita sin perfil y una mascota nueva.
        let citas = entorno.repos.citas
        try citas.registrarLlegada(try #require(try citas.agenda(de: huellitas, dia: .now).first))
        _ = try citas.reservarSinPerfil(
            en: huellitas, fecha: .now, tipo: .veterinaria,
            datos: DatosEmergencia(especie: .gato, motivo: "Vómito", telefono: "5512345678"), tutor: nil
        )
        try entorno.repos.mascotas.agregar(Mascota(nombre: "Nube", especie: .gato), a: try entorno.tutor())

        try DatosDemoSwiftData(contexto: entorno.contexto).restablecer()

        #expect(try entorno.contar(Negocio.self) == negocios)
        #expect(try entorno.contar(Usuario.self) == 2)
        #expect(try entorno.contar(Mascota.self) == 2)
        #expect(try entorno.contar(Cita.self) == citasIniciales)
        let agenda = try citas.agenda(de: try entorno.huellitas(), dia: .now)
        #expect(agenda.count == 1)
        #expect(agenda.first?.estado == .programada)
        #expect(agenda.first?.mascota?.id == SeedData.idMochi)
    }

    @Test func ajustesRestableceYConservaElRol() async throws {
        let entorno = try Entorno()
        let almacen = try #require(UserDefaults(suiteName: "pruebas-\(UUID().uuidString)"))
        let estado = AppState(usuarios: entorno.repos.usuarios, almacen: almacen)
        try estado.iniciarSesionDemo(rol: .negocio)
        let vm = AjustesViewModel(
            appState: estado, auth: AuthServiceLocal(),
            datosDemo: DatosDemoSwiftData(contexto: entorno.contexto), almacen: almacen
        )

        vm.espera = .zero
        await vm.restablecerDatosDemo()

        #expect(vm.mensajeError == nil)
        #expect(estado.rol == .negocio)
        #expect(estado.generacionDatos == 1)
        #expect(estado.negocioActual?.nombre == SeedData.nombreNegocioDemo)
    }

    @Test func modoDemoSeGuardaYAdelantaElPrimerRecordatorio() throws {
        let entorno = try Entorno()
        let almacen = try #require(UserDefaults(suiteName: "pruebas-\(UUID().uuidString)"))
        let estado = AppState(usuarios: entorno.repos.usuarios, almacen: almacen)
        let vm = AjustesViewModel(appState: estado, auth: AuthServiceLocal(), almacen: almacen)
        #expect(!vm.modoDemo)
        vm.modoDemo = true
        #expect(almacen.bool(forKey: PreferenciasDemo.claveModoDemo))

        let receta = try #require(try entorno.mascota("Firulais").recetas.first)
        let normales = receta.recordatoriosDeDosis(modoDemo: false)
        let demo = receta.recordatoriosDeDosis(modoDemo: true)
        // Sin modo demo la primera dosis llega a las 12 horas.
        #expect(normales.first?.segundos == 12 * 3600)
        #expect(demo.first?.segundos == 60)
        #expect(demo.first?.medicamento == normales.first?.medicamento)
        // Las demás conservan su horario.
        #expect(Array(demo.dropFirst()) == Array(normales.dropFirst()))
        #expect(demo.count == normales.count)
    }
}

@MainActor
@Suite("Perfil desde una cita sin perfil")
struct PerfilDesdeCitaTests {
    @Test func alTerminarSeOfreceYLigaLaMascotaALaCita() throws {
        let entorno = try Entorno()
        let almacen = try #require(UserDefaults(suiteName: "pruebas-\(UUID().uuidString)"))
        let estado = AppState(usuarios: entorno.repos.usuarios, almacen: almacen)
        try estado.iniciarSesionDemo(rol: .tutor)
        let citas = entorno.repos.citas
        let cita = try citas.reservarSinPerfil(
            en: try entorno.huellitas(), fecha: .now, tipo: .veterinaria,
            datos: DatosEmergencia(especie: .gato, motivo: "Vómito", telefono: "5512345678"),
            tutor: try entorno.tutor()
        )
        let vm = MisCitasViewModel(appState: estado, citas: citas, mascotas: entorno.repos.mascotas)

        // Mientras no termina, no se ofrece.
        #expect(!vm.ofrecePerfil(cita))
        #expect(vm.formularioPerfil(para: cita) == nil)

        try citas.registrarLlegada(cita)
        while cita.estado == .enCurso { try citas.avanzarEtapa(cita, fotoFinal: nil) }
        #expect(vm.ofrecePerfil(cita))

        let formulario = try #require(vm.formularioPerfil(para: cita))
        #expect(formulario.especie == .gato)
        formulario.nombre = "Nube"
        #expect(formulario.guardar())

        #expect(cita.mascota?.nombre == "Nube")
        #expect(cita.mascota?.tutor?.id == (try entorno.tutor()).id)
        #expect(!vm.ofrecePerfil(cita))
        #expect(vm.perfilesCreados == 1)
        #expect(vm.anteriores.contains { $0.id == cita.id })
    }
}
