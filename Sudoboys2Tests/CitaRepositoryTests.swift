import Foundation
import Testing
@testable import Sudoboys2

@MainActor
@Suite("CitaRepository")
struct CitaRepositoryTests {
    @Test func reservaConMascotaYDescuentaUnLugarDeHoy() throws {
        let entorno = try Entorno()
        let huellitas = try entorno.huellitas()
        let firulais = try entorno.mascota("Firulais")
        let lugares = huellitas.disponibilidadHoy

        let cita = try entorno.repos.citas.reservar(
            en: huellitas, fecha: .now, tipo: .veterinaria, servicio: nil, mascota: firulais, tutor: nil
        )

        #expect(cita.estado == .programada)
        #expect(cita.etapaActual == nil)
        #expect(!cita.esSinPerfil)
        #expect(cita.tutor?.id == firulais.tutor?.id)
        #expect(huellitas.disponibilidadHoy == lugares - 1)
        #expect(try entorno.repos.citas.cita(id: cita.id) != nil)
    }

    @Test func citaSinPerfilGuardaLosDatosDeEmergencia() throws {
        let entorno = try Entorno()
        let datos = DatosEmergencia(especie: .gato, motivo: "No come desde ayer", telefono: "5512345678")
        let cita = try entorno.repos.citas.reservarSinPerfil(
            en: entorno.huellitas(), fecha: .now, tipo: .veterinaria, datos: datos, tutor: nil
        )

        #expect(cita.esSinPerfil)
        #expect(cita.esUrgencia)
        #expect(cita.especie == .gato)
        #expect(cita.motivoEmergencia == "No come desde ayer")
        #expect(cita.telefonoEmergencia == "5512345678")

        // Al terminar se puede crear el perfil y ligarlo a la cita.
        let tutor = try entorno.tutor()
        let nueva = Mascota(nombre: "Misha", especie: .gato)
        try entorno.repos.mascotas.agregar(nueva, a: tutor)
        try entorno.repos.citas.asignar(nueva, a: cita)
        #expect(!cita.esSinPerfil)
        #expect(try entorno.repos.citas.citas(de: tutor).contains { $0.id == cita.id })
    }

    @Test func noReservaUnServicioQueElNegocioNoOfrece() throws {
        let entorno = try Entorno()
        let estetica = try #require(try entorno.repos.negocios.todos().first { $0.tipo == .estetica })
        let firulais = try entorno.mascota("Firulais")
        #expect(throws: ErrorRepositorio.servicioNoOfrecido) {
            try entorno.repos.citas.reservar(
                en: estetica, fecha: .now, tipo: .veterinaria, servicio: nil, mascota: firulais, tutor: nil
            )
        }
    }

    @Test(arguments: [
        (TipoServicio.estetica, [EtapaCita.recibido, .bano, .secado, .corte, .listo]),
        (TipoServicio.veterinaria, [EtapaCita.recibido, .consulta, .tratamiento, .listo]),
    ])
    func avanzaLasEtapasSegunElTipo(tipo: TipoServicio, esperadas: [EtapaCita]) throws {
        let entorno = try Entorno()
        let citas = entorno.repos.citas
        let cita = try citas.reservar(
            en: entorno.huellitas(), fecha: .now, tipo: tipo, servicio: nil,
            mascota: entorno.mascota("Firulais"), tutor: nil
        )

        // Sin check-in no avanza.
        #expect(throws: ErrorRepositorio.citaSinLlegada) { try citas.avanzarEtapa(cita, fotoFinal: nil) }

        try citas.registrarLlegada(cita)
        var recorridas = [try #require(cita.etapaActual)]
        while cita.estado == .enCurso {
            recorridas.append(try citas.avanzarEtapa(cita, fotoFinal: Data([1, 2, 3])))
        }

        #expect(recorridas == esperadas)
        #expect(cita.estado == .terminada)
        #expect(cita.fotoFinal == Data([1, 2, 3]))
        #expect(throws: ErrorRepositorio.citaCerrada) { try citas.avanzarEtapa(cita, fotoFinal: nil) }
    }

    @Test func soloSeResenaUnaCitaTerminadaYUnaVez() throws {
        let entorno = try Entorno()
        let citas = entorno.repos.citas
        let huellitas = try entorno.huellitas()
        let cita = try citas.reservar(
            en: huellitas, fecha: .now, tipo: .veterinaria, servicio: nil,
            mascota: entorno.mascota("Firulais"), tutor: nil
        )
        #expect(throws: ErrorRepositorio.citaNoTerminada) {
            try citas.agregarResena(a: cita, calificacion: 5, texto: "Aún no")
        }

        try citas.registrarLlegada(cita)
        while cita.estado == .enCurso { try citas.avanzarEtapa(cita, fotoFinal: nil) }

        let resena = try citas.agregarResena(a: cita, calificacion: 3, texto: "Bien")
        #expect(resena.cita?.id == cita.id)
        #expect(huellitas.resenas.count == 3)
        // Promedio de las reseñas reales: 5, 4 y 3.
        #expect(huellitas.calificacion == 4.0)
        #expect(throws: ErrorRepositorio.citaYaTieneResena) {
            try citas.agregarResena(a: cita, calificacion: 5, texto: "Otra")
        }
    }

    @Test func agendaDelDiaEnOrdenYCancelacion() throws {
        let entorno = try Entorno()
        let citas = entorno.repos.citas
        let huellitas = try entorno.huellitas()

        let hoy = try citas.agenda(de: huellitas, dia: .now)
        #expect(hoy.count == 1)
        #expect(hoy.map(\.fecha) == hoy.map(\.fecha).sorted())

        let cita = try #require(hoy.first)
        try citas.cancelar(cita)
        #expect(cita.estado == .cancelada)
        #expect(throws: ErrorRepositorio.citaCerrada) { try citas.cancelar(cita) }
        #expect(throws: ErrorRepositorio.citaCerrada) { try citas.registrarLlegada(cita) }
    }

    @Test func citasDelTutorDeLaMasRecienteALaMasAntigua() throws {
        let entorno = try Entorno()
        let citas = try entorno.repos.citas.citas(de: entorno.tutor())
        #expect(citas.count == 3)
        #expect(citas.map(\.fecha) == citas.map(\.fecha).sorted(by: >))
    }
}
