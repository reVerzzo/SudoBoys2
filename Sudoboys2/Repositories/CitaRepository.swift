import Foundation
import SwiftData

/// Datos de una cita sin perfil (emergencia).
nonisolated struct DatosEmergencia: Equatable, Sendable {
    var especie: Especie
    var motivo: String
    var telefono: String
}

protocol CitaRepository {
    /// Citas que reservó el tutor (con o sin perfil), de la más reciente a la más antigua.
    func citas(de tutor: Usuario) throws -> [Cita]
    /// Agenda del negocio para el día de `fecha`, en orden de hora.
    func agenda(de negocio: Negocio, dia fecha: Date) throws -> [Cita]
    func cita(id: UUID) throws -> Cita?

    func reservar(
        en negocio: Negocio,
        fecha: Date,
        tipo: TipoServicio,
        servicio: Servicio?,
        mascota: Mascota,
        tutor: Usuario?
    ) throws -> Cita

    /// Cita sin perfil: guarda especie, motivo y teléfono en lugar de una mascota.
    func reservarSinPerfil(
        en negocio: Negocio,
        fecha: Date,
        tipo: TipoServicio,
        datos: DatosEmergencia,
        tutor: Usuario?
    ) throws -> Cita

    /// Urgencia: sin horario (es para ahora). Con `mascota` o, sin perfil, con la especie de `datos`.
    func reservarUrgencia(
        en negocio: Negocio,
        mascota: Mascota?,
        datos: DatosEmergencia,
        minutosLlegada: Int?,
        tutor: Usuario?
    ) throws -> Cita

    /// La cita activa de la mascota que se encima con ese horario, si la hay.
    func citaEncimada(de mascota: Mascota, fecha: Date, duracionMinutos: Int) -> Cita?

    /// Check-in: la cita pasa a "en curso" en su primera etapa.
    func registrarLlegada(_ cita: Cita) throws
    /// Avanza a la siguiente etapa; al llegar a la última la cita termina.
    @discardableResult
    func avanzarEtapa(_ cita: Cita, fotoFinal: Data?) throws -> EtapaCita
    func cancelar(_ cita: Cita) throws
    /// Liga una mascota a una cita sin perfil (al crear el perfil después).
    func asignar(_ mascota: Mascota, a cita: Cita) throws
    /// Solo para citas terminadas; actualiza la calificación del negocio.
    @discardableResult
    func agregarResena(a cita: Cita, calificacion: Int, texto: String) throws -> Resena
}

final class CitaRepositorySwiftData: CitaRepository {
    private let contexto: ModelContext
    private let calendario: Calendar

    init(contexto: ModelContext, calendario: Calendar = .current) {
        self.contexto = contexto
        self.calendario = calendario
    }

    func citas(de tutor: Usuario) throws -> [Cita] {
        let todas = try contexto.fetch(FetchDescriptor<Cita>(sortBy: [SortDescriptor(\.fecha, order: .reverse)]))
        let idTutor = tutor.id
        return todas.filter { $0.tutor?.id == idTutor || $0.mascota?.tutor?.id == idTutor }
    }

    func agenda(de negocio: Negocio, dia fecha: Date) throws -> [Cita] {
        negocio.citas
            .filter { calendario.isDate($0.fecha, inSameDayAs: fecha) }
            .sorted { $0.fecha < $1.fecha }
    }

    func cita(id: UUID) throws -> Cita? {
        var consulta = FetchDescriptor<Cita>(predicate: #Predicate { $0.id == id })
        consulta.fetchLimit = 1
        return try contexto.fetch(consulta).first
    }

    func reservar(
        en negocio: Negocio,
        fecha: Date,
        tipo: TipoServicio,
        servicio: Servicio?,
        mascota: Mascota,
        tutor: Usuario?
    ) throws -> Cita {
        guard negocio.tipo.ofrece(tipo) else { throw ErrorRepositorio.servicioNoOfrecido }
        let duracion = servicio?.duracionMinutos ?? EtapaCita.flujo(para: tipo).minutosTotales
        guard citaEncimada(de: mascota, fecha: fecha, duracionMinutos: duracion) == nil else {
            throw ErrorRepositorio.citaEncimada
        }
        let cita = Cita(fecha: fecha, tipoServicio: tipo)
        contexto.insert(cita)
        cita.negocio = negocio
        cita.servicio = servicio
        cita.mascota = mascota
        cita.tutor = tutor ?? mascota.tutor
        descontarLugar(en: negocio, fecha: fecha)
        try contexto.save()
        return cita
    }

    func reservarSinPerfil(
        en negocio: Negocio,
        fecha: Date,
        tipo: TipoServicio,
        datos: DatosEmergencia,
        tutor: Usuario?
    ) throws -> Cita {
        guard negocio.tipo.ofrece(tipo) else { throw ErrorRepositorio.servicioNoOfrecido }
        let cita = Cita(
            fecha: fecha,
            tipoServicio: tipo,
            esUrgencia: true,
            especieEmergencia: datos.especie,
            motivoEmergencia: datos.motivo,
            telefonoEmergencia: datos.telefono
        )
        contexto.insert(cita)
        cita.negocio = negocio
        cita.tutor = tutor
        descontarLugar(en: negocio, fecha: fecha)
        try contexto.save()
        return cita
    }

    func reservarUrgencia(
        en negocio: Negocio,
        mascota: Mascota?,
        datos: DatosEmergencia,
        minutosLlegada: Int?,
        tutor: Usuario?
    ) throws -> Cita {
        guard negocio.tipo.ofrece(.veterinaria) else { throw ErrorRepositorio.servicioNoOfrecido }
        let cita = Cita(
            fecha: .now,
            tipoServicio: .veterinaria,
            esUrgencia: true,
            especieEmergencia: mascota?.especie ?? datos.especie,
            motivoEmergencia: datos.motivo,
            telefonoEmergencia: datos.telefono
        )
        contexto.insert(cita)
        cita.negocio = negocio
        cita.mascota = mascota
        cita.tutor = tutor ?? mascota?.tutor
        cita.minutosLlegada = minutosLlegada
        cita.servicio = negocio.servicios.first {
            $0.tipo == .veterinaria && $0.nombre.localizedCaseInsensitiveContains("urgencia")
        }
        try contexto.save()
        return cita
    }

    func citaEncimada(de mascota: Mascota, fecha: Date, duracionMinutos: Int) -> Cita? {
        let nueva = DateInterval(start: fecha, duration: TimeInterval(max(duracionMinutos, 1) * 60))
        return mascota.citas.first { $0.estaActiva && $0.intervalo.seEncima(con: nueva) }
    }

    func registrarLlegada(_ cita: Cita) throws {
        guard cita.estado == .programada else { throw ErrorRepositorio.citaCerrada }
        cita.fijarEtapas()
        cita.estado = .enCurso
        cita.indiceEtapa = 0
        cita.horaLlegada = .now
        cita.horaEtapa = .now
        try contexto.save()
    }

    @discardableResult
    func avanzarEtapa(_ cita: Cita, fotoFinal: Data?) throws -> EtapaCita {
        guard cita.estado == .enCurso else {
            throw cita.estado == .programada ? ErrorRepositorio.citaSinLlegada : ErrorRepositorio.citaCerrada
        }
        guard let indice = cita.indiceEtapaVisible, let siguiente = cita.siguienteEtapa else {
            throw ErrorRepositorio.citaCerrada
        }
        cita.indiceEtapa = indice + 1
        cita.horaEtapa = .now
        if indice + 1 == cita.etapas.count - 1 {
            cita.estado = .terminada
            if let fotoFinal { cita.fotoFinal = fotoFinal }
        }
        try contexto.save()
        return siguiente
    }

    func cancelar(_ cita: Cita) throws {
        guard cita.estado == .programada || cita.estado == .enCurso else { throw ErrorRepositorio.citaCerrada }
        cita.estado = .cancelada
        try contexto.save()
    }

    func asignar(_ mascota: Mascota, a cita: Cita) throws {
        cita.mascota = mascota
        try contexto.save()
    }

    @discardableResult
    func agregarResena(a cita: Cita, calificacion: Int, texto: String) throws -> Resena {
        guard cita.estado == .terminada else { throw ErrorRepositorio.citaNoTerminada }
        guard cita.resena == nil else { throw ErrorRepositorio.citaYaTieneResena }
        let resena = Resena(calificacion: calificacion, texto: texto)
        contexto.insert(resena)
        resena.cita = cita
        if let negocio = cita.negocio {
            let calificaciones = negocio.citas.compactMap { $0.resena?.calificacion }
            if !calificaciones.isEmpty {
                negocio.calificacion = Double(calificaciones.reduce(0, +)) / Double(calificaciones.count)
            }
        }
        try contexto.save()
        return resena
    }

    private func descontarLugar(en negocio: Negocio, fecha: Date) {
        if calendario.isDateInToday(fecha), negocio.disponibilidadHoy > 0 {
            negocio.disponibilidadHoy -= 1
        }
    }
}
