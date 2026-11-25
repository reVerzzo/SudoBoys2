import Foundation
import Testing
@testable import Sudoboys2

@MainActor
@Suite("Etapas por servicio, urgencias y horarios")
struct EtapasYHorariosTests {
    private func manana(hora: Int, minuto: Int = 0) throws -> Date {
        let dia = try #require(Calendar.current.date(byAdding: .day, value: 1, to: .now))
        return try #require(Calendar.current.date(bySettingHour: hora, minute: minuto, second: 0, of: dia))
    }

    @Test func cadaServicioTieneSusEtapasYSuDuracionEsLaSuma() throws {
        let entorno = try Entorno()
        let servicios = try entorno.huellitas().servicios
        func etapas(_ nombre: String) throws -> [String] {
            try #require(servicios.first { $0.nombre == nombre }).etapas.map(\.titulo)
        }
        #expect(try etapas("Corte de uñas") == ["Recibido", "Corte de uñas", "Listo"])
        #expect(try etapas("Baño") == ["Recibido", "Baño", "Secado", "Listo"])
        #expect(try etapas("Baño y corte") == ["Recibido", "Baño", "Secado", "Corte", "Listo"])
        #expect(try etapas("Consulta general") == ["Recibido", "Revisión", "Diagnóstico", "Listo"])
        #expect(try etapas("Vacunación") == ["Recibido", "Revisión", "Aplicación", "Observación", "Listo"])
        #expect(try etapas("Urgencia") == ["Recibido", "Valoración", "Tratamiento", "Estable"])
        #expect(servicios.first { $0.nombre == "Corte de uñas" }?.duracionMinutos == 15)
        #expect(servicios.allSatisfy { $0.duracionMinutos == $0.etapas.minutosTotales })
    }

    @Test func laCitaUsaLasEtapasDelServicioYElTiempoEsLoQueFalta() throws {
        let entorno = try Entorno()
        let citas = entorno.repos.citas
        let huellitas = try entorno.huellitas()
        let unas = try #require(huellitas.servicios.first { $0.nombre == "Corte de uñas" })
        let cita = try citas.reservar(
            en: huellitas, fecha: try manana(hora: 10), tipo: .estetica, servicio: unas,
            mascota: entorno.mascota("Firulais"), tutor: nil
        )
        #expect(cita.minutosRestantes == 15)

        try citas.registrarLlegada(cita)
        // Editar el servicio después del check-in no cambia esta cita.
        unas.etapas = EtapaCita.banoYCorte
        #expect(cita.etapas.map(\.titulo) == ["Recibido", "Corte de uñas", "Listo"])

        try citas.avanzarEtapa(cita, fotoFinal: nil)
        #expect(cita.etapaActual?.titulo == "Corte de uñas")
        #expect(cita.minutosRestantes == 13)
        #expect(cita.siguienteEsFinal)
        try citas.avanzarEtapa(cita, fotoFinal: nil)
        #expect(cita.estado == .terminada)
        #expect(cita.minutosRestantes == 0)
    }

    @Test func laMismaMascotaNoTieneDosCitasEncimadas() throws {
        let entorno = try Entorno()
        let citas = entorno.repos.citas
        let huellitas = try entorno.huellitas()
        let firulais = try entorno.mascota("Firulais")
        let bano = try #require(huellitas.servicios.first { $0.nombre == "Baño" })  // 60 min
        _ = try citas.reservar(
            en: huellitas, fecha: try manana(hora: 10), tipo: .estetica, servicio: bano, mascota: firulais, tutor: nil
        )
        // 10:30 cae dentro del baño de 10:00 a 11:00.
        #expect(throws: ErrorRepositorio.citaEncimada) {
            try citas.reservar(
                en: huellitas, fecha: try manana(hora: 10, minuto: 30), tipo: .veterinaria,
                servicio: nil, mascota: firulais, tutor: nil
            )
        }
        // A las 11:00 ya no se enciman, y otra mascota sí puede a las 10:30.
        _ = try citas.reservar(
            en: huellitas, fecha: try manana(hora: 11), tipo: .veterinaria, servicio: nil, mascota: firulais, tutor: nil
        )
        _ = try citas.reservar(
            en: huellitas, fecha: try manana(hora: 10, minuto: 30), tipo: .veterinaria,
            servicio: nil, mascota: entorno.mascota("Mochi"), tutor: nil
        )
    }

    @Test func reservarDeshabilitaLosHorariosOcupados() throws {
        let entorno = try Entorno()
        let huellitas = try entorno.huellitas()
        let ahora = try manana(hora: 7)
        let bano = try #require(huellitas.servicios.first { $0.nombre == "Baño" })
        _ = try entorno.repos.citas.reservar(
            en: huellitas, fecha: try manana(hora: 10), tipo: .estetica, servicio: bano,
            mascota: entorno.mascota("Firulais"), tutor: nil
        )
        let vm = ReservarViewModel(
            negocio: huellitas, tutor: try entorno.tutor(),
            citas: entorno.repos.citas, mascotas: entorno.repos.mascotas, ahora: ahora
        )
        vm.idMascota = try entorno.mascota("Firulais").id
        vm.servicio = bano
        let ocupados = vm.horarios.filter { !$0.disponible }.map(\.fecha)
        // Un baño de 60 min choca si empieza entre 9:30 y 10:30.
        #expect(ocupados == [try manana(hora: 9, minuto: 30), try manana(hora: 10), try manana(hora: 10, minuto: 30)])
        #expect(vm.avisoHorarios?.contains("Firulais ya tiene cita") == true)

        // Para Mochi ese horario está ocupado en el negocio, no por él.
        vm.idMascota = try entorno.mascota("Mochi").id
        #expect(vm.horarios.first { $0.fecha == ocupados[1] }?.ocupado == .negocio)
    }

    @Test func laUrgenciaNoPideHoraYSoloOfreceLoAbiertoAhora() throws {
        let entorno = try Entorno()
        // Domingo 3:00 a.m.: solo abren los de 24 horas.
        var partes = DateComponents()
        partes.year = 2026; partes.month = 11; partes.day = 29; partes.hour = 3
        let madrugada = try #require(Calendar.current.date(from: partes))
        let vm = UrgenciaViewModel(
            tutor: try entorno.tutor(), origen: ExplorarViewModel.referencia,
            negocios: entorno.repos.negocios, citas: entorno.repos.citas, mascotas: entorno.repos.mascotas,
            reloj: { madrugada }
        )
        #expect(!vm.opciones.isEmpty)
        #expect(vm.opciones.allSatisfy { $0.negocio.estaAbierto(en: madrugada) && $0.negocio.tipo.ofrece(.veterinaria) })
        #expect(vm.opciones.map(\.distanciaKm) == vm.opciones.map(\.distanciaKm).sorted())
        #expect(!vm.puedeConfirmar)

        vm.idMascota = try entorno.mascota("Mochi").id
        #expect(vm.opciones.allSatisfy { $0.negocio.especiesAtendidas.contains(.exotico) })
        vm.motivo = "No quiere comer"
        vm.telefono = "55 1234 5678"
        vm.idNegocio = try entorno.huellitas().id
        #expect(vm.puedeConfirmar)
        vm.confirmar()

        let cita = try #require(vm.citaConfirmada)
        #expect(cita.esUrgencia)
        #expect(cita.mascota?.nombre == "Mochi")
        #expect(cita.minutosLlegada != nil)
        #expect(cita.etapas.map(\.titulo) == ["Recibido", "Valoración", "Tratamiento", "Estable"])
        #expect(TextoUrgencia.aviso(especie: "Conejo", motivo: "No quiere comer", minutos: 8)
            == "Urgencia: Conejo, No quiere comer. Llegan en ~8 min")
    }
}
