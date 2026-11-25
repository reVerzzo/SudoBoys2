import Foundation
import Testing
@testable import Sudoboys2

@MainActor
@Suite("MascotaRepository")
struct MascotaRepositoryTests {
    @Test func listaLasMascotasDelTutorPorNombre() throws {
        let entorno = try Entorno()
        let mascotas = try entorno.repos.mascotas.mascotas(de: entorno.tutor())
        #expect(mascotas.map(\.nombre) == ["Firulais", "Mochi"])
    }

    @Test func agregaMascotaYLaEncuentraPorId() throws {
        let entorno = try Entorno()
        let tutor = try entorno.tutor()
        let michi = Mascota(nombre: "Michi", especie: .gato)
        try entorno.repos.mascotas.agregar(michi, a: tutor)

        #expect(try entorno.repos.mascotas.mascotas(de: tutor).count == 3)
        #expect(try entorno.repos.mascotas.mascota(id: michi.id)?.nombre == "Michi")
        #expect(michi.tutor?.id == tutor.id)
    }

    @Test func agregaVacunaRegistradaPorElTutor() throws {
        let entorno = try Entorno()
        let mochi = try entorno.mascota("Mochi")
        let antes = mochi.vacunas.count
        let vacuna = Vacuna(nombre: "Refuerzo", fechaAplicacion: .now, registradaPor: .tutor)
        try entorno.repos.mascotas.agregar(vacuna, a: mochi)

        #expect(mochi.vacunas.count == antes + 1)
        #expect(vacuna.registradaPor == .tutor)
        #expect(vacuna.cedulaVeterinario == nil)
    }

    @Test func eliminarMascotaBorraSuCartillaYRecetas() throws {
        let entorno = try Entorno()
        let firulais = try entorno.mascota("Firulais")
        let vacunasDeFirulais = firulais.vacunas.count
        let vacunasAntes = try entorno.contar(Vacuna.self)
        #expect(try entorno.contar(Receta.self) == 1)

        try entorno.repos.mascotas.eliminar(firulais)

        #expect(try entorno.repos.mascotas.mascotas(de: entorno.tutor()).map(\.nombre) == ["Mochi"])
        #expect(try entorno.contar(Vacuna.self) == vacunasAntes - vacunasDeFirulais)
        #expect(try entorno.contar(Receta.self) == 0)
        #expect(try entorno.contar(Medicamento.self) == 0)
    }
}
