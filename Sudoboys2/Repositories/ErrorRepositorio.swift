import Foundation

/// Reglas de negocio que un repositorio puede rechazar.
nonisolated enum ErrorRepositorio: Error, Equatable {
    /// No existe la cuenta demo de ese rol (faltan los datos de ejemplo).
    case sinCuentaDemo(RolUsuario)
    /// El negocio no ofrece ese tipo de servicio.
    case servicioNoOfrecido
    /// La cita ya terminó o fue cancelada.
    case citaCerrada
    /// La cita todavía no hace check-in.
    case citaSinLlegada
    /// Solo se puede reseñar una cita terminada.
    case citaNoTerminada
    case citaYaTieneResena
    /// Solo una veterinaria con cédula verificada puede emitir recetas.
    case negocioNoAutorizadoParaRecetas
    case citaYaTieneReceta
}
