import SwiftUI

/// Alta manual de una vacuna. Queda registrada por el tutor.
struct FormularioVacunaView: View {
    let alGuardar: (_ nombre: String, _ fechaAplicacion: Date, _ proximaDosis: Date?) -> Void

    @Environment(\.dismiss) private var cerrar
    @State private var nombre = ""
    @State private var fechaAplicacion = Date.now
    @State private var tieneProximaDosis = false
    @State private var proximaDosis = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now

    private var puedeGuardar: Bool { !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espaciado.m) {
                    CampoTexto("Vacuna", marcador: "Por ejemplo: Antirrábica", icono: "syringe.fill", texto: $nombre)
                    VStack(alignment: .leading, spacing: Espaciado.s) {
                        DatePicker("Fecha de aplicación", selection: $fechaAplicacion, in: ...Date.now, displayedComponents: .date)
                        Toggle("Tiene próxima dosis", isOn: $tieneProximaDosis)
                            .tint(Color.app.salud)
                        if tieneProximaDosis {
                            DatePicker("Próxima dosis", selection: $proximaDosis, in: fechaAplicacion..., displayedComponents: .date)
                                .transition(.opacity)
                        }
                    }
                    .font(Font.app.cuerpo)
                    .foregroundStyle(Color.app.textoPrincipal)
                    .padding(Espaciado.m)
                    .background(Color.app.superficieElevada, in: Forma.control)
                    .animation(Animation.app.suave, value: tieneProximaDosis)

                    Label("Aparecerá como registrada por el tutor.", systemImage: "person.fill")
                        .font(Font.app.nota)
                        .foregroundStyle(Color.app.textoSecundario)
                }
                .padding(.horizontal, Espaciado.margenPantalla)
                .padding(.vertical, Espaciado.m)
            }
            .background(Color.app.fondo)
            .navigationTitle("Agregar vacuna")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cerrar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        alGuardar(nombre, fechaAplicacion, tieneProximaDosis ? max(proximaDosis, fechaAplicacion) : nil)
                        cerrar()
                    }
                    .disabled(!puedeGuardar)
                }
            }
        }
        .environment(\.locale, .mx)
        .presentationDetents([.medium, .large])
    }
}

#Preview("Claro") {
    FormularioVacunaView { _, _, _ in }
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    FormularioVacunaView { _, _, _ in }
        .tint(Color.app.primarioTinte)
        .preferredColorScheme(.dark)
}
