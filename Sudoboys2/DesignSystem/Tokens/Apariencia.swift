import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Preferencia de apariencia de la app. Se guarda con `@AppStorage`
/// usando `PreferenciaApariencia.clave`.
enum PreferenciaApariencia: String, CaseIterable, Identifiable {
    case sistema
    case claro
    case oscuro

    /// Clave de `@AppStorage`.
    static let clave = "preferenciaApariencia"

    var id: Self { self }

    var titulo: String {
        switch self {
        case .sistema: "Sistema"
        case .claro: "Claro"
        case .oscuro: "Oscuro"
        }
    }

    var icono: String {
        switch self {
        case .sistema: "circle.lefthalf.filled"
        case .claro: "sun.max.fill"
        case .oscuro: "moon.fill"
        }
    }

    /// `nil` sigue la apariencia del sistema.
    var esquemaDeColor: ColorScheme? {
        switch self {
        case .sistema: nil
        case .claro: .light
        case .oscuro: .dark
        }
    }
}

#if canImport(UIKit)
extension PreferenciaApariencia {
    var estiloDeInterfaz: UIUserInterfaceStyle {
        switch self {
        case .sistema: .unspecified
        case .claro: .light
        case .oscuro: .dark
        }
    }

    /// Aplica la preferencia a todas las ventanas de la app.
    func aplicarALasVentanas() {
        for escena in UIApplication.shared.connectedScenes {
            guard let escena = escena as? UIWindowScene else { continue }
            for ventana in escena.windows {
                ventana.overrideUserInterfaceStyle = estiloDeInterfaz
            }
        }
    }
}
#endif

/// Aplica en la raíz de la app la apariencia guardada con `@AppStorage`.
///
/// En iOS se fija el estilo de la ventana en lugar de usar `.preferredColorScheme`:
/// en el simulador de iOS 27, `.preferredColorScheme` pasaba a oscuro pero ya no
/// regresaba a claro ni a "Sistema" al cambiar la preferencia en caliente.
private struct AparienciaDeLaApp: ViewModifier {
    @AppStorage(PreferenciaApariencia.clave) private var preferencia: PreferenciaApariencia = .sistema
    @Environment(\.scenePhase) private var fase

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content
            .onAppear { preferencia.aplicarALasVentanas() }
            .onChange(of: preferencia) { preferencia.aplicarALasVentanas() }
            .onChange(of: fase) { preferencia.aplicarALasVentanas() }
        #else
        content.preferredColorScheme(preferencia.esquemaDeColor)
        #endif
    }
}

extension View {
    /// Úsalo una sola vez, en la vista raíz de la app.
    func aparienciaDeLaApp() -> some View {
        modifier(AparienciaDeLaApp())
    }
}

/// Selector Sistema / Claro / Oscuro. Lee y escribe la preferencia guardada.
struct SelectorApariencia: View {
    @AppStorage(PreferenciaApariencia.clave) private var preferencia: PreferenciaApariencia = .sistema

    var body: some View {
        Picker("Apariencia", selection: $preferencia) {
            ForEach(PreferenciaApariencia.allCases) { opcion in
                Label(opcion.titulo, systemImage: opcion.icono)
                    .labelStyle(.titleOnly)
                    .tag(opcion)
            }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: preferencia)
    }
}

#Preview("Claro") {
    SelectorApariencia()
        .padding(Espaciado.margenPantalla)
        .background(Color.app.fondo)
        .preferredColorScheme(.light)
}

#Preview("Oscuro") {
    SelectorApariencia()
        .padding(Espaciado.margenPantalla)
        .background(Color.app.fondo)
        .preferredColorScheme(.dark)
}
