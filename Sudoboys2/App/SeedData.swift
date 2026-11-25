import Foundation
import SwiftData

/// Datos de ejemplo del primer arranque: negocios del sur de CDMX, el tutor demo
/// con Firulais y Mochi, y el negocio demo Clínica Huellitas.
/// Es determinista (sin aleatorios) e idempotente.
enum SeedData {
    static let correoTutorDemo = "tutor@demo.petapp"
    static let correoNegocioDemo = "huellitas@demo.petapp"
    static let nombreNegocioDemo = "Clínica Huellitas"
    static let nombreMascotaDemo = "Mochi"
    /// Ids fijos de las mascotas demo: su QR sigue sirviendo después de restablecer los datos.
    static let idFirulais = UUID(uuidString: "F1F1F1F1-0000-4000-8000-000000000001") ?? UUID()
    static let idMochi = UUID(uuidString: "F1F1F1F1-0000-4000-8000-000000000002") ?? UUID()
    /// Hora de la cita con la que arranca la demo.
    static let horaCitaDemo = 17

    /// Siembra solo si todavía no existen las cuentas demo.
    static func sembrarSiHaceFalta(en contexto: ModelContext, ahora: Date = .now) throws {
        let demos = try contexto.fetchCount(FetchDescriptor<Usuario>(predicate: #Predicate { $0.esDemo }))
        guard demos == 0 else { return }

        let negocios = sembrarNegocios(en: contexto)
        guard let huellitas = negocios.first(where: { $0.nombre == nombreNegocioDemo }) else { return }

        let cuentaNegocio = Usuario(
            nombre: nombreNegocioDemo,
            correo: correoNegocioDemo,
            proveedor: .demo,
            rol: .negocio,
            esDemo: true
        )
        contexto.insert(cuentaNegocio)
        huellitas.propietario = cuentaNegocio

        sembrarTutor(en: contexto, clinica: huellitas, ahora: ahora)
        try contexto.save()
    }

    // MARK: - Negocios

    private struct DatoNegocio {
        let nombre: String
        let tipo: TipoNegocio
        let especies: [Especie]
        let latitud: Double
        let longitud: Double
        let direccion: String
        let apertura: Int
        let cierre: Int
        let dias: [Int]
        let calificacion: Double
        let verificacion: EstadoVerificacion
        let cedula: String?
        let lugaresHoy: Int
    }

    private static let todosLosDias = [1, 2, 3, 4, 5, 6, 7]
    private static let lunesASabado = [2, 3, 4, 5, 6, 7]
    private static let martesADomingo = [1, 3, 4, 5, 6, 7]

    private static func dato(
        _ nombre: String,
        _ tipo: TipoNegocio,
        _ especies: [Especie],
        _ latitud: Double,
        _ longitud: Double,
        _ direccion: String,
        horas: ClosedRange<Int> = 9...19,
        dias: [Int] = lunesASabado,
        _ calificacion: Double,
        _ verificacion: EstadoVerificacion,
        cedula: String? = nil,
        hoy lugaresHoy: Int
    ) -> DatoNegocio {
        DatoNegocio(
            nombre: nombre,
            tipo: tipo,
            especies: especies,
            latitud: latitud,
            longitud: longitud,
            direccion: direccion,
            apertura: horas.lowerBound * 60,
            cierre: horas.upperBound * 60,
            dias: dias,
            calificacion: calificacion,
            verificacion: verificacion,
            cedula: cedula,
            lugaresHoy: lugaresHoy
        )
    }

    private static let datosNegocios: [DatoNegocio] = [
        // Coyoacán
        dato(nombreNegocioDemo, .ambos, [.perro, .gato, .exotico], 19.3497, -99.1618,
             "Av. Miguel Ángel de Quevedo 687, Coyoacán", horas: 0...24, dias: todosLosDias,
             4.8, .verificado, cedula: "8123456", hoy: 5),
        dato("Estética Canina Coyoacán", .estetica, [.perro], 19.3521, -99.1640,
             "Francisco Sosa 120, Del Carmen, Coyoacán", 4.6, .verificado, hoy: 3),
        dato("Veterinaria Del Carmen", .veterinaria, [.perro, .gato], 19.3549, -99.1655,
             "Malintzin 48, Del Carmen, Coyoacán", horas: 8...20, 4.7, .verificado, cedula: "7345120", hoy: 2),
        dato("Patitas Felices Spa", .estetica, [.perro, .gato], 19.3462, -99.1589,
             "Av. Universidad 1810, Oxtopulco, Coyoacán", horas: 10...18, 4.3, .pendiente, hoy: 4),
        dato("Hospital Veterinario Viveros", .veterinaria, [.perro, .gato, .exotico], 19.3538, -99.1722,
             "Av. Progreso 18, Barrio de Santa Catarina, Coyoacán", horas: 0...24, dias: todosLosDias,
             4.9, .verificado, cedula: "6890231", hoy: 6),
        dato("El Gato con Botas Estética", .estetica, [.gato], 19.3440, -99.1670,
             "Tres Cruces 55, Villa Coyoacán", horas: 11...19, dias: martesADomingo, 4.5, .enRevision, hoy: 0),
        dato("Clínica Animalia Churubusco", .ambos, [.perro, .gato], 19.3571, -99.1502,
             "Río Churubusco 410, San Diego Churubusco, Coyoacán", horas: 9...21, dias: todosLosDias,
             4.4, .verificado, cedula: "9012774", hoy: 3),
        dato("Peludos Grooming Taxqueña", .estetica, [.perro, .gato], 19.3418, -99.1425,
             "Av. Taxqueña 1320, Campestre Churubusco, Coyoacán", 4.1, .pendiente, hoy: 2),
        dato("Veterinaria Santo Domingo", .veterinaria, [.perro, .gato], 19.3283, -99.1675,
             "Av. Aztecas 215, Pedregal de Santo Domingo, Coyoacán", horas: 9...20, dias: todosLosDias,
             4.2, .enRevision, cedula: "10455218", hoy: 4),
        // Ciudad Universitaria y alrededores
        dato("Exóticos CU", .veterinaria, [.exotico], 19.3349, -99.1795,
             "Cerro del Agua 232, Copilco Universidad", horas: 10...18, 4.9, .verificado, cedula: "5567803", hoy: 1),
        dato("Estética Puma Pets", .estetica, [.perro, .gato], 19.3372, -99.1768,
             "Av. Copilco 300, Copilco El Bajo", 4.4, .verificado, hoy: 5),
        dato("Clínica Veterinaria Copilco", .ambos, [.perro, .gato, .exotico], 19.3391, -99.1741,
             "Eje 10 Sur 164, Copilco El Alto", horas: 8...22, dias: todosLosDias,
             4.6, .verificado, cedula: "8344019", hoy: 2),
        dato("Baño y Corte Universidad", .estetica, [.perro], 19.3425, -99.1812,
             "Av. Universidad 2014, Copilco Universidad", horas: 10...19, 3.9, .pendiente, hoy: 6),
        dato("Veterinaria Pedregal", .veterinaria, [.perro, .gato], 19.3172, -99.2031,
             "Av. de las Fuentes 180, Jardines del Pedregal", horas: 9...20, 4.7, .verificado, cedula: "7781340", hoy: 0),
        dato("Pet Boutique San Ángel", .estetica, [.perro, .gato], 19.3458, -99.1899,
             "Av. de la Paz 37, San Ángel", horas: 10...20, dias: todosLosDias, 4.8, .verificado, hoy: 1),
        dato("Aves y Reptiles del Sur", .veterinaria, [.exotico], 19.3310, -99.1905,
             "Av. San Jerónimo 263, La Otra Banda", horas: 11...18, 4.5, .enRevision, cedula: "11230045", hoy: 2),
        // Tlalpan
        dato("Veterinaria Tlalpan Centro", .veterinaria, [.perro, .gato], 19.2893, -99.1672,
             "Madero 14, Tlalpan Centro", horas: 9...20, 4.6, .verificado, cedula: "6612987", hoy: 3),
        dato("Estética La Huella", .estetica, [.perro, .gato], 19.2911, -99.1648,
             "Av. San Fernando 120, Tlalpan Centro", 4.2, .verificado, hoy: 4),
        dato("Hospital Veterinario Huipulco", .ambos, [.perro, .gato, .exotico], 19.2987, -99.1503,
             "Calz. de Tlalpan 4456, Huipulco", horas: 0...24, dias: todosLosDias,
             4.5, .verificado, cedula: "9450661", hoy: 7),
        dato("Colitas Limpias Coapa", .estetica, [.perro], 19.2962, -99.1251,
             "Canal de Miramontes 3010, Villa Coapa", horas: 10...18, 4.0, .pendiente, hoy: 0),
        dato("Clínica Felina del Sur", .veterinaria, [.gato], 19.3015, -99.1312,
             "Calz. del Hueso 503, Granjas Coapa", horas: 10...19, 4.9, .verificado, cedula: "8870412", hoy: 2),
        dato("Mundo Mascota Insurgentes", .ambos, [.perro, .gato], 19.2934, -99.1810,
             "Av. Insurgentes Sur 3846, Tlalpan", horas: 9...21, dias: todosLosDias,
             4.3, .enRevision, cedula: "10087536", hoy: 3),
        dato("Conejos y Cuyos Tlalpan", .ambos, [.exotico], 19.2858, -99.1734,
             "Moneda 64, Tlalpan Centro", horas: 11...18, dias: martesADomingo,
             4.7, .verificado, cedula: "7903318", hoy: 1),
        dato("Spa Canino Ajusco", .estetica, [.perro, .gato], 19.2795, -99.1968,
             "Carretera Picacho-Ajusco 520, Jardines en la Montaña", 3.8, .pendiente, hoy: 5),
    ]

    private static func sembrarNegocios(en contexto: ModelContext) -> [Negocio] {
        datosNegocios.map { dato in
            let negocio = Negocio(
                nombre: dato.nombre,
                tipo: dato.tipo,
                especiesAtendidas: dato.especies,
                latitud: dato.latitud,
                longitud: dato.longitud,
                direccion: dato.direccion,
                minutoApertura: dato.apertura,
                minutoCierre: dato.cierre,
                diasAbiertos: dato.dias,
                calificacion: dato.calificacion,
                estadoVerificacion: dato.verificacion,
                cedula: dato.cedula,
                disponibilidadHoy: dato.lugaresHoy
            )
            contexto.insert(negocio)
            for servicio in servicios(para: dato.tipo) {
                contexto.insert(servicio)
                servicio.negocio = negocio
            }
            return negocio
        }
    }

    private static func servicios(para tipo: TipoNegocio) -> [Servicio] {
        var servicios: [Servicio] = []
        if tipo.ofrece(.estetica) {
            servicios += [
                Servicio(nombre: "Baño", precio: 250, tipo: .estetica),
                Servicio(nombre: "Baño y corte", precio: 420, tipo: .estetica),
                Servicio(nombre: "Corte de uñas", precio: 120, tipo: .estetica),
            ]
        }
        if tipo.ofrece(.veterinaria) {
            servicios += [
                Servicio(nombre: "Consulta general", precio: 450, tipo: .veterinaria),
                Servicio(nombre: "Vacunación", precio: 380, tipo: .veterinaria),
                Servicio(nombre: "Urgencia", precio: 900, tipo: .veterinaria),
            ]
        }
        return servicios
    }

    // MARK: - Tutor demo

    private static func sembrarTutor(en contexto: ModelContext, clinica: Negocio, ahora: Date) {
        let calendario = Calendar.current
        func hace(_ valor: Int, _ unidad: Calendar.Component) -> Date {
            calendario.date(byAdding: unidad, value: -valor, to: ahora) ?? ahora
        }
        func en(_ valor: Int, _ unidad: Calendar.Component) -> Date {
            calendario.date(byAdding: unidad, value: valor, to: ahora) ?? ahora
        }

        let tutor = Usuario(
            nombre: "Sofía Ramírez",
            correo: correoTutorDemo,
            proveedor: .demo,
            rol: .tutor,
            esDemo: true
        )
        contexto.insert(tutor)

        let veterinaria = "Dra. Mariana López"
        let cedula = clinica.cedula ?? ""

        // Firulais
        let firulais = Mascota(
            id: idFirulais,
            nombre: "Firulais",
            especie: .perro,
            raza: "Mestizo",
            nacimiento: hace(4, .year),
            pesoKg: 18.5,
            alergias: "Pollo",
            notasComportamiento: "Se pone nervioso con la secadora. Le encantan los premios."
        )
        contexto.insert(firulais)
        firulais.tutor = tutor

        let vacunasFirulais = [
            Vacuna(nombre: "Antirrábica", fechaAplicacion: hace(10, .month), proximaDosis: en(2, .month),
                   registradaPor: .veterinario, nombreVeterinario: veterinaria, cedulaVeterinario: cedula),
            Vacuna(nombre: "Múltiple (DHPPi-L)", fechaAplicacion: hace(5, .month), proximaDosis: en(7, .month),
                   registradaPor: .veterinario, nombreVeterinario: veterinaria, cedulaVeterinario: cedula),
            Vacuna(nombre: "Bordetella", fechaAplicacion: hace(14, .month), proximaDosis: nil,
                   registradaPor: .tutor),
        ]
        for vacuna in vacunasFirulais {
            contexto.insert(vacuna)
            vacuna.mascota = firulais
        }

        // Mochi
        let mochi = Mascota(
            id: idMochi,
            nombre: nombreMascotaDemo,
            especie: .exotico,
            detalleEspecie: "Conejo",
            raza: "Mini lop",
            nacimiento: hace(2, .year),
            pesoKg: 1.8,
            notasComportamiento: "Tranquilo. No le gusta que le toquen las patas traseras."
        )
        contexto.insert(mochi)
        mochi.tutor = tutor

        let vacunaMochi = Vacuna(
            nombre: "Mixomatosis y hemorrágica vírica",
            fechaAplicacion: hace(3, .month),
            proximaDosis: en(9, .month),
            registradaPor: .veterinario,
            nombreVeterinario: veterinaria,
            cedulaVeterinario: cedula
        )
        contexto.insert(vacunaMochi)
        vacunaMochi.mascota = mochi

        func servicio(_ nombre: String) -> Servicio? {
            clinica.servicios.first { $0.nombre == nombre }
        }

        // Consulta terminada de Firulais, con reseña y receta.
        let consulta = Cita(fecha: hace(12, .day), tipoServicio: .veterinaria, estado: .terminada)
        contexto.insert(consulta)
        consulta.negocio = clinica
        consulta.mascota = firulais
        consulta.tutor = tutor
        consulta.servicio = servicio("Consulta general")

        let resenaConsulta = Resena(
            calificacion: 5,
            texto: "Atendieron a Firulais con mucha paciencia y me explicaron todo el tratamiento.",
            fecha: hace(11, .day)
        )
        contexto.insert(resenaConsulta)
        resenaConsulta.cita = consulta

        let receta = Receta(
            fecha: hace(12, .day),
            nombreVeterinario: veterinaria,
            cedulaVeterinario: cedula,
            domicilioVeterinario: clinica.direccion,
            diagnostico: "Otitis externa en oído derecho",
            indicaciones: "Limpiar el oído antes de cada aplicación. Revisión en 10 días."
        )
        contexto.insert(receta)
        receta.cita = consulta
        receta.negocio = clinica
        receta.mascota = firulais

        let medicamentos = [
            Medicamento(nombre: "Gentamicina ótica", dosis: "4 gotas en oído derecho",
                        cadaHoras: 12, dias: 7, grupo: .recetaSimple),
            Medicamento(nombre: "Meloxicam 1 mg", dosis: "1 tableta con alimento",
                        cadaHoras: 24, dias: 5, grupo: .recetaSimple),
            Medicamento(nombre: "Limpiador ótico", dosis: "Aplicar y masajear la base del oído",
                        cadaHoras: 24, dias: 10, grupo: .ventaLibre),
        ]
        for medicamento in medicamentos {
            contexto.insert(medicamento)
            medicamento.receta = receta
        }

        // Baño terminado de Mochi, con reseña.
        let bano = Cita(fecha: hace(1, .month), tipoServicio: .estetica, estado: .terminada)
        contexto.insert(bano)
        bano.negocio = clinica
        bano.mascota = mochi
        bano.tutor = tutor
        bano.servicio = servicio("Corte de uñas")

        let resenaBano = Resena(
            calificacion: 4,
            texto: "Saben tratar conejos. Mochi salió tranquilo y con las uñas perfectas.",
            fecha: hace(29, .day)
        )
        contexto.insert(resenaBano)
        resenaBano.cita = bano

        // Cita de hoy de Mochi, pendiente de check-in: con ella arranca la demo.
        insertarCitaDeHoy(en: contexto, clinica: clinica, mascota: mochi, tutor: tutor, ahora: ahora)
    }

    // MARK: - Cita de la demo

    /// Consulta de hoy para Mochi en Clínica Huellitas, aún sin check-in.
    /// Es de veterinaria para poder emitir la receta durante la demo.
    private static func insertarCitaDeHoy(
        en contexto: ModelContext, clinica: Negocio, mascota: Mascota, tutor: Usuario?, ahora: Date
    ) {
        let cita = Cita(fecha: fechaCitaDemo(ahora), tipoServicio: .veterinaria)
        contexto.insert(cita)
        cita.negocio = clinica
        cita.mascota = mascota
        cita.tutor = tutor
        cita.servicio = clinica.servicios.first { $0.nombre == "Consulta general" }
    }

    private static func fechaCitaDemo(_ ahora: Date) -> Date {
        Calendar.current.date(bySettingHour: horaCitaDemo, minute: 0, second: 0, of: ahora) ?? ahora
    }

    /// Se llama en cada arranque: si la app se sembró otro día, la cita de la demo
    /// ya no saldría en la agenda de hoy. Trae a hoy la cita que quedó sin atender
    /// o crea una nueva si hoy Mochi no tiene ninguna en la clínica.
    static func asegurarCitaDeHoy(en contexto: ModelContext, ahora: Date = .now) throws {
        let demos = try contexto.fetch(FetchDescriptor<Usuario>(predicate: #Predicate { $0.esDemo }))
        guard let tutor = demos.first(where: { $0.rol == .tutor }),
              let clinica = demos.first(where: { $0.rol == .negocio })?.negocio,
              let mochi = tutor.mascotas.first(where: { $0.id == idMochi }) else { return }

        let calendario = Calendar.current
        let citas = clinica.citas.filter { $0.mascota?.id == mochi.id && $0.estado != .cancelada }
        guard !citas.contains(where: { calendario.isDate($0.fecha, inSameDayAs: ahora) }) else { return }

        let inicioDeHoy = calendario.startOfDay(for: ahora)
        if let atrasada = citas.first(where: { $0.estado == .programada && $0.fecha < inicioDeHoy }) {
            atrasada.fecha = fechaCitaDemo(ahora)
        } else {
            insertarCitaDeHoy(en: contexto, clinica: clinica, mascota: mochi, tutor: tutor, ahora: ahora)
        }
        try contexto.save()
    }
}
