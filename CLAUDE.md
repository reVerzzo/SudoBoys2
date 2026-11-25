# CLAUDE.md — App Pet Economy (Hackathon FCA UNAM 2026)

Responde y comenta en español. Nombres de tipos y propiedades del dominio en español (Mascota, Cita, Receta); convenciones de Swift en inglés (`View`, `ViewModel`, `Repository`).

## Contexto

App iOS para el Hackathon FCA 2026 "Pet Economy". El jurado califica: 25% grado de avance (incluye pertinencia de tecnología Apple y calidad del prototipo), 20% relevancia, 20% originalidad, 20% pitch, 15% UX/UI. La demo en vivo es el centro del pitch: **todo lo que se construya tiene que funcionar en vivo, sin crashes y sin internet**. Mejor pocas funciones pulidas que muchas a medias.

**Producto:** plataforma que conecta a tutores de mascotas con veterinarias y estéticas independientes por disponibilidad real y confianza verificada, y acompaña todo el servicio. Dos roles en la misma app: **Tutor** y **Negocio** (estética, veterinaria o ambos).

## Restricciones duras

- **Sin cuenta pagada de Apple Developer.** Se firma con equipo personal (Apple ID gratis). NO usar: CloudKit/iCloud, notificaciones push remotas, Sign in with Apple funcional, Wallet/PassKit, TestFlight. No agregar capabilities ni entitlements que no se necesiten (tampoco App Groups). Si una función necesitara cuenta pagada, proponer alternativa local.
- **Sin backend.** Todo vive en SwiftData local. Los dos roles se prueban en el mismo iPhone (cambio rápido de cuenta demo).
- La Live Activity se actualiza **localmente** desde la app (ActivityKit, sin push). Las imágenes de la Live Activity van en el asset catalog de la extensión o son SF Symbols.
- Deployment target **iOS 26**. Foundation Models solo con `SystemLanguageModel.default.availability == .available`; si no, usar respaldo (regex/plantillas). Nunca crashear por falta de Apple Intelligence.
- El proyecto usa carpetas sincronizadas de Xcode: crea archivos `.swift` dentro de las carpetas existentes; **no edites `project.pbxproj`** salvo que se te pida. Targets, capabilities y extensiones se crean desde Xcode a mano.

## Arquitectura

MVVM + Repository.
- **Views**: SwiftUI, sin lógica de negocio. Reciben un ViewModel.
- **ViewModels**: `@Observable` (`@MainActor`), exponen estado y acciones. Hablan solo con protocolos de Repository y Services.
- **Repositories**: protocolos (`MascotaRepository`, `NegocioRepository`, `CitaRepository`, `RecetaRepository`, `UsuarioRepository`) + implementación SwiftData. Debe ser posible cambiarlos por un backend en la nube sin tocar vistas.
- **Services**: `EscanerTextoService` (VisionKit + Vision), `ExtractorIAService` (Foundation Models), `GeneradorQRService` (Core Image), `LiveActivityService` (ActivityKit), `NotificacionesService` (UserNotifications), `AuthService` (Google + demo), `UbicacionService` (CoreLocation; respaldo Ciudad Universitaria), `RutasService` (MKDirections; respaldo por distancia sin internet), `DatosDemoService`.
- Filtros del mapa: en memoria en el ViewModel (no `#Predicate` con enums).
- Inyección de dependencias por inicializador o `Environment`. Previews con datos de ejemplo en memoria.

```
Sudoboys2/
  App/            App, ModelContainer, SeedData, AppState (sesión y rol)
  DesignSystem/   Colores, Tipografía, Espaciado, Componentes reutilizables, Animaciones
  Models/         @Model + enums
  Repositories/
  ViewModels/
  Views/          Auth, Explorar, Mascotas, Cartilla, Citas, Recetas, Negocio, Ajustes
  Services/
SudoboysWidgets/  Live Activity (pantalla de bloqueo + Dynamic Island)
```

## Modelo de datos (SwiftData)

- **Usuario**: nombre, correo, proveedor (google, apple, demo), rol (tutor, negocio), negocio asociado.
- **Mascota**: nombre, especie (perro, gato, exótico) + detalle (conejo, ave…), raza, nacimiento, peso, alergias, notas de comportamiento, foto (`@Attribute(.externalStorage)`), vacunas, recetas. Un tutor tiene varias mascotas.
- **Vacuna**: nombre, fecha de aplicación, próxima dosis, registradaPor (tutor, veterinario), nombre y cédula del veterinario.
- **Negocio**: nombre, tipo (estética, veterinaria, ambos), especies atendidas, latitud, longitud, dirección, horario, calificación, estadoVerificacion (pendiente, enRevision, verificado), cédula (solo veterinaria), servicios, disponibilidad de hoy.
- **Servicio**: nombre, precio, tipo (estética, veterinaria) y **sus etapas** (`EtapaCita`: título, ícono, minutos; guardadas como JSON en `etapasDatos`). La duración es la suma de los minutos de las etapas.
- **Cita**: fecha, negocio, mascota (opcional: nil = cita sin perfil), datos de emergencia (especie, motivo, teléfono), esUrgencia, minutosLlegada (urgencias), índice de la etapa actual, etapas fijadas al hacer check-in, estado. El tiempo estimado es la suma de las etapas que faltan.
- **Resena**: calificación, texto, cita (solo desde una cita terminada).
- **Receta**: fecha, mascota, cita, negocio, nombre/cédula/domicilio del veterinario, diagnóstico, indicaciones, medicamentos, requiereRecetaFisica.
- **Medicamento**: nombre, dosis, cada cuántas horas, cuántos días, grupo (ventaLibre, recetaSimple, recetaCuantificada).

Datos de ejemplo al primer arranque: 20–30 negocios en el sur de CDMX (Coyoacán, Tlalpan, CU) con mezcla de tipos, especies y verificación; tutor demo con 2 mascotas (perro "Firulais" y conejo "Mochi") con cartilla y una receta; usuario negocio demo "Clínica Huellitas" (ambos, cédula verificada).

## Funciones (orden de prioridad)

1. Inicio de sesión por rol: "Soy tutor" / "Soy estética o veterinaria". Botones: Continuar con Google (GoogleSignIn), Continuar con Apple (visible, deshabilitado con nota "Disponible próximamente"), **Entrar con cuenta demo** (siempre funciona offline). Alta de negocio: tipo, especies, ubicación, foto de cédula si es veterinaria.
2. Explorar: mapa (MapKit) + lista, filtros por servicio (estética / veterinaria / ambos), especie (perros, gatos, exóticos), verificado, disponible hoy, abierto ahora, calificación, distancia. Insignias: "Cédula verificada" (veterinaria) y "Negocio verificado" (estética).
3. Perfil del negocio: servicios, precios, especies, horario, reseñas de citas reales, botón reservar.
4. Mis mascotas: varias mascotas, tarjeta por mascota (foto, datos, alergias, próxima vacuna, QR con el id de la mascota).
5. Cartilla de vacunación virtual: alta manual y por escaneo (VisionKit + Foundation Models `@Generable`). Cada vacuna indica si la registró el tutor o un veterinario (con nombre y cédula).
6. Citas: reservar eligiendo mascota, servicio, día y horario. La misma mascota no puede tener dos citas que se encimen (cuenta la duración del servicio) y los horarios ocupados del negocio salen deshabilitados. **Urgencias sin horario** (botón Urgencia en Explorar): mascota o "sin perfil" con especie, motivo, teléfono y una veterinaria abierta ahora con su tiempo de llegada (MKDirections). Al terminar una cita sin perfil, ofrecer crear el perfil.
7. Modo negocio: agenda del día con las urgencias en camino arriba y resaltadas (haptic y notificación local), escanear QR de la mascota, check-in, avanzar las etapas **del servicio elegido** con foto final; actualiza la Live Activity. El negocio agrega y edita sus servicios, etapas y minutos desde Perfil.
8. Recetas: solo veterinarios verificados. Se emite desde la cita, aparece en el historial de la mascota, programa recordatorios de dosis locales, genera PDF (`ImageRenderer` + `ShareLink`) y marca "requiere receta física" según el grupo del medicamento (NOM-064-ZOO-2000).
9. Carga de cédula: foto → OCR (nombre y número) → "En revisión" → aprobación simulada con botón de administrador.
10. Ajustes: apariencia Sistema / Claro / Oscuro (`@AppStorage` + `.preferredColorScheme`), cerrar sesión, cambiar a cuenta demo del otro rol.

## Sistema de diseño

Paleta 60/30/10: 60% fondo, 30% primario y salud, 10% acento. Definir **cada color como Color Set en el asset catalog con variante Any y Dark** y exponerlos como `Color.app.fondo`, etc. Nunca hex sueltos en vistas.

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| fondo | #FAF8F5 | #17121D | Fondo de pantallas |
| superficie | #FFFFFF | #231B2B | Tarjetas, hojas |
| superficieElevada | #F2EDE7 | #2E2438 | Avatares, campos, chips inactivos |
| borde | #E6DFD7 | #3A2F45 | Separadores; en oscuro sustituye a la sombra |
| textoPrincipal | #3D2C4D | #F3EEF6 | Títulos y texto |
| textoSecundario | #6E6178 | #B5AABF | Subtítulos, metadatos |
| primario | #3D2C4D | #5E4875 | Fondo de botón principal (texto blanco) |
| primarioTinte | #3D2C4D | #C7B3DD | Íconos, enlaces, selección, tint de la app |
| salud | #4A908A | #6FC2BA | Rellenos grandes, íconos de salud, gráficas |
| saludTexto | #2F756F | #6FC2BA | Texto verde e insignias de salud (texto blanco en claro, #17121D en oscuro) |
| acento | #E8985E | #F2A56C | Botones destacados (texto #3D2C4D en claro, #17121D en oscuro) |
| acentoTexto | #A65A24 | #F2A56C | Texto o enlaces en tono durazno |
| estrellas | #D0793A | #F2A56C | Calificaciones |

Contraste verificado (WCAG AA): no poner texto blanco sobre `acento` ni texto pequeño blanco sobre `salud` en claro; usar las combinaciones de la tabla.

- **Tipografía**: SF Pro con `.fontDesign(.rounded)` en títulos para un tono cálido; estilos semánticos (`.largeTitle`, `.headline`, `.body`) para Dynamic Type. Nada de tamaños fijos.
- **Forma**: esquinas `RoundedRectangle(cornerRadius: 20–24, style: .continuous)`. Sombras suaves solo en claro (`Color.app.primario.opacity(0.08)`, radio 16, y 4); en oscuro, borde de 1 pt `borde`.
- **Espaciado**: escala 4/8/12/16/24/32. Márgenes de pantalla 20.
- **Liquid Glass (iOS 26)**: `.glassEffect()` en botones flotantes y controles sobre el mapa; agrupar con `GlassEffectContainer`. No poner vidrio sobre vidrio ni en tarjetas de contenido.
- **Íconos**: SF Symbols (`pawprint.fill`, `stethoscope`, `scissors`, `syringe.fill`, `cross.case.fill`, `pills.fill`, `star.fill`, `checkmark.seal.fill`, `qrcode`).
- Componentes base en `DesignSystem/`: `BotonPrincipal`, `BotonAcento`, `TarjetaApp`, `InsigniaVerificado`, `InsigniaSalud`, `Calificacion`, `ChipFiltro`, `EstadoVacio`, `AvatarMascota`, `EncabezadoSeccion`.

## Animación y sensación premium

- Resortes por defecto: `.spring(duration: 0.4, bounce: 0.2)` o `.smooth`; nunca animaciones lineales.
- Transición de zoom al abrir la tarjeta de mascota o el perfil de negocio: `.matchedTransitionSource` + `.navigationTransition(.zoom(sourceID:in:))`.
- `symbolEffect(.bounce)` al marcar favorito o completar una etapa; `.contentTransition(.numericText())` en contadores y precios; `.contentTransition(.symbolEffect(.replace))` al cambiar íconos.
- `.sensoryFeedback(.success, trigger:)` al reservar, avanzar etapa y recibir receta; `.selection` al cambiar filtros.
- Progreso de etapas de la cita con `PhaseAnimator` o `KeyframeAnimator` y la misma estética en la Live Activity.
- Listas con `.scrollTransition` sutil (opacidad y escala 0.95–1). Estados de carga con `.redacted(reason: .placeholder)`.
- Encabezados con `MeshGradient` muy suave usando ciruela, jade y durazno a baja opacidad.
- Respetar `accessibilityReduceMotion`: reemplazar movimiento por fundidos.

## Calidad

- Compila sin warnings nuevos. Después de cada fase, compilar y probar en simulador (usar las herramientas de Xcode por MCP si están disponibles).
- Cada vista con `#Preview` en claro y en oscuro.
- Accesibilidad: etiquetas en botones de íconos, Dynamic Type, contraste de la tabla.
- Textos de la interfaz en español de México, tono cálido y breve.
- No agregues dependencias externas salvo GoogleSignIn (Swift Package).
- Commits pequeños por función.

## Skills: cuándo usar cada una

Usa la skill que corresponda **antes** de escribir o revisar código; si aplican varias, combínalas. **Este CLAUDE.md manda sobre las skills**: la paleta, la tipografía, los resortes, la arquitectura y las restricciones de arriba no se cambian por lo que sugiera una skill. Varias skills de diseño y animación ponen ejemplos para web: toma el criterio y tradúcelo a SwiftUI (`.spring`, `PhaseAnimator`, `.sensoryFeedback`, `DragGesture`, etc.), nunca CSS ni React.

**Al escribir código (siempre)**
- `swiftui-expert-skill`: cualquier vista, estado `@Observable`, navegación, listas, previews, localización.
- `write-swift`: modelos, repositorios, servicios, concurrencia (`@MainActor`, `@concurrent`, actores), pruebas con Swift Testing.
- `swiftui-liquid-glass`: botones flotantes y controles sobre el mapa, barra de filtros (función 2) y cualquier `.glassEffect()`.

**Sistema de diseño (fase 0, antes de las pantallas)**
- `ui-ux-pro-max:ui-ux-pro-max`: buenas prácticas de UX, accesibilidad y la guía del stack SwiftUI. Solo para criterio; la paleta y la tipografía ya están definidas aquí.
- `ui-ux-pro-max:design-system`: estructurar los tokens de `Color.app`, espaciado y tipografía en `DesignSystem/` y especificar los componentes base.
- `apple-design`: sensación nativa de iOS en materiales, profundidad, tipografía, retroalimentación y movimiento físico.
- `emil-design-eng`: pulido de cada componente (estados al presionar, transiciones, detalles invisibles).

**Animación (funciones 4, 6, 7 y la Live Activity)**
- `animate`: crear una animación nueva (zoom a la tarjeta de mascota, insignias, contadores).
- `choreograph`: varios elementos que se mueven juntos, como el avance de etapas de la cita, las listas con entrada escalonada y el encabezado con `MeshGradient`.
- `gestures`: hojas, arrastres y swipes (hoja del mapa, deslizar para cancelar cita).
- `animation-vocabulary`: poner nombre exacto a un efecto que se describe a medias.
- `find-animation-opportunities`: al terminar una pantalla, buscar dónde falta movimiento.
- `review-animations`: revisar cada cambio que agregue o modifique animaciones.
- `remove-animations`: si algo se siente lento o sobreanimado.
- `improve-animations`: auditoría completa del movimiento en la fase de pulido.

**Calidad y pulido (antes de la demo)**
- `break-ui`: probar cada pantalla con datos extremos (nombres larguísimos, mascota sin foto, cero citas, negocio sin reseñas, Dynamic Type XXL). En SwiftUI el interruptor "Demo / Peor caso" va en el `#Preview`.
- `swiftui-performance-audit`: mapa con 30 negocios, listas, scroll y Live Activity sin tirones.
- `prototype`: cuando haya dudas de diseño, hacer 2–3 variantes de un componente y compararlas en el `#Preview` con un `Picker`.
- `learn-taste`: cuando corrija un detalle de diseño, convertirlo en regla y guardarla en la sección "Sistema de diseño" de este archivo (no en un DESIGN.md aparte).
- `ask-emil`: si no está claro qué skill de diseño o animación aplica.

**Pitch (20% de la calificación)**
- `ui-ux-pro-max:slides`: la presentación del pitch, con la paleta de la app.
- `ui-ux-pro-max:brand`: voz y mensajes de la marca para el pitch y los textos de la interfaz (español de México, cálido y breve).
- `ui-ux-pro-max:banner-design`: portada, imagen para redes o póster del proyecto.

**No aplican a esta app:** `ui-ux-pro-max:ui-styling` (shadcn/Tailwind, solo web) y la generación de logos de `ui-ux-pro-max:design` (necesita llaves de APIs externas; el ícono se resuelve con SF Symbols o a mano).

## Estado actual del proyecto (Xcode)

- Proyecto `Sudoboys2.xcodeproj`. Targets: app `Sudoboys2` y extensión `SudoboysWidgetsExtension` (widget + Live Activity).
- **Pendiente de ajustar en Xcode a mano:** el deployment target está en 27.0 (debe ser iOS 26) y la app tiene marcadas macOS y visionOS además de iOS.
- La firma falla hasta elegir el equipo personal en Signing & Capabilities de ambos targets.
- Solo existe el esquema `SudoboysWidgetsExtension`; falta uno para la app.
- Ajustes de Swift: modo de lenguaje 5, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`.
- Las carpetas vacías tienen `.gitkeep`; bórralo en cuanto la carpeta tenga código. Si el build da "Multiple commands produce … .gitkeep", exclúyelos del target.
- Skills del proyecto en `.claude/skills/` (versiones en `skills-lock.json`); el plugin `ui-ux-pro-max` está instalado a nivel de usuario. Ver "Skills: cuándo usar cada una".

## Pendientes anotados

- **Fase 7, falta verificar en el iPhone** (los arreglos compilan, pero no se revisaron con capturas ni se corrieron las pruebas):
  - Alta de negocio y perfil del negocio: al desplazar, la barra toma fondo y muestra el título (`DesignSystem/Componentes/BarraAlDesplazar.swift`). Confirmar que el contenido ya no se encima con la barra de estado ni con el botón de regreso.
  - Reservar: la fila de días se desvanece en los bordes en lugar de cortar un chip.
  - Títulos grandes alineados al margen 20 con `layoutMargins` de `UINavigationBar` (`EstiloNavegacion`). Si en iOS 26/27 no surte efecto, "Citas" y "Agenda" seguirán en x=16.
  - Hoja de filtros a media altura: sin cambios; falta revisar que la barra de resultados no se encime con los chips.
  - Live Activity tras quitar el widget de plantilla: el bundle solo declara `SudoboysWidgetsLiveActivity` y compila; falta probar el check-in en vivo.
- **Pruebas:** el target `Sudoboys2Tests` no tiene equipo de firma ni dependencia declarada del target de la app; hay que ajustarlo en Xcode para correr las pruebas nuevas de `SeedDataTests.swift`.
- **Urgencias, etapas y ubicación (revisado en simulador):** falta probar en el iPhone real el permiso de ubicación, la Live Activity con las etapas de cada servicio y el tiempo de llegada sin internet (cae a la aproximación por distancia). En la hoja de Urgencia algunas rutas de MapKit no responden y se quedan en "aprox."; la lista se ordena por distancia, no por tiempo.
- **Regla:** las vistas que dibuja MapKit (contenido de `Annotation`) reciben copias de los datos, nunca el `@Model`: MapKit las vuelve a medir después de desmontarlas y leer un modelo borrado truena la app.
