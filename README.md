# Deck Tracker – App

Aplicación Flutter para gestionar mazos de Pokémon TCG, registrar partidas, ver estadísticas y organizar torneos completos: seguimiento del propio historial (**tracked**) o torneos alojados por la app con varios jugadores (**hosted**). Incluye perfil de usuario, sistema de amigos e invitaciones a torneos.

**Demo web:** https://deck-tracker-web.onrender.com

## Descargas

- 📱 [Descargar APK (Android)](https://github.com/Ayme-99/deck-tracker-app/releases/download/v1.5.0%2B1/DeckTrackerApp-1.5.1+1.apk)
- 💻 [Descargar instalador (Windows)](https://github.com/Ayme-99/deck-tracker-app/releases/download/v1.5.0%2B1/DeckTrackerSetup-1.5.0+1.exe)

## Stack

- Flutter / Dart
- `http` (API REST) · `flutter_secure_storage` (token JWT) · `go_router` (rutas con URL real en web)
- Backend: [deck-tracker-server](https://github.com/Ayme-99/deck-tracker-server) (Node.js/Express/MongoDB, desplegado en Render)

## Funcionalidades

- **Auth**: registro, login y auto-login con sesión persistente; redirección a Login si el token deja de ser válido (incluye aviso de sesión caducada). Manejo de sesión robusto frente al cold start del backend: los 401 de peticiones lanzadas antes de un logout (sin token) no expulsan la sesión ni borran el token actual. Verificación de email tras el registro, con reenvío del correo desde el perfil. Enter funciona como "Aceptar" en los formularios principales (login, registro, mazos, partidas, torneos, jugadores).
- **Perfil de usuario**: nombre de usuario, fecha de alta ("Miembro desde..."), resumen rápido de actividad (mazos, partidas, win rate global), cambio de contraseña, ajustes (copia de seguridad, color de acento, tema, cerrar sesión) y reporte de bugs directo a GitHub (issue form estructurado, sin necesidad de saber Markdown).
- **Amigos**: solicitudes (enviar/aceptar/rechazar), listado de amigos, búsqueda de usuarios por username, badge de solicitudes pendientes en el perfil.
- **Mazos**: CRUD completo, vista en grid adaptable con buscador, récord de partidas y orden por actividad reciente. Al eliminar un mazo se borran también sus partidas (cascada en backend); el diálogo de confirmación avisa del nº de partidas afectadas. Al añadir cartas al mazo, autocompletado contra el catálogo real de [TCGdex](https://tcgdex.dev) (issue #12): si se elige una sugerencia se guarda el `cardId` oficial; si no hay coincidencia, se conserva el slug generado a mano como hasta ahora.
- **Partidas**: registro, edición y borrado, con autocompletado de rivales ya jugados.
- **Estadísticas**: win-rate, matchups y premios por mazo; stats globales y ranking ordenable (win rate, nº de partidas, nombre) con mínimo de partidas ajustable; win-rate contra cada arquetipo rival agregado a lo largo de todos los mazos propios.
- **Torneos — modo tracked**: creación con 5 estructuras (suiza, suiza+eliminatoria, grupos+eliminatoria, eliminatoria directa, liga), detalle con partidas agrupadas por fase/ronda, resumen W-L-T global y por fase, standing manual para ligas, opciones de editar estado/eliminar mediante long-press.
- **Torneos — modo hosted**: la app aloja el torneo completo.
  - Gestión de jugadores (inscripciones sin cuenta propia), con autocompletado de arquetipo y opción de vincular tu propio mazo real si participas.
  - Invitar a un amigo a un torneo, con rol admin (registra sus propios resultados) o invitado (solo el organizador los registra); invitaciones recibidas visibles desde el perfil.
  - Rondas y emparejamientos: generación automática por estructura (suiza, grupos, liga, eliminatoria), registro de resultados, avance de fase, pestañas combinadas por ronda/fase.
  - Bracket de eliminatoria visual, con conectores calculados por datos reales (no por posición), y pantalla independiente con pan/zoom (botón de recentrar) para brackets grandes. Hasta 64 jugadores en la primera ronda.
  - Clasificación en vivo: puntos, W-L-D y desempates (diferencial de premios, luego OMW%).
  - Exportar/Importar torneos completos entre usuarios (JSON), preservando todo el historial y resultados ya jugados; al importar, opción de vincular una inscripción a tu propia cuenta y mazo.
- **Actualizaciones**: aviso de nueva versión disponible (Windows/Android, comparando contra la última release de GitHub); descarga del instalador/APK en segundo plano con progreso y botón para ejecutarlo directamente desde la app.
- **UI**: modo oscuro/claro automático, color de acento personalizable, sprites de Pokémon para mazos y rivales (PokeAPI), aviso de cold start del backend si una carga tarda más de 5 s. En web, rutas con URL real y sin `#` para las pantallas principales (Mazos, Stats, Torneos, Perfil), navegables con atrás/adelante del navegador y compartibles como enlace directo.

## Estructura del proyecto

```
lib/
├── main.dart
├── config/
│ ├── api_config.dart # URL del backend
│ ├── app_router.dart # rutas de go_router (web: URL real por pantalla)
│ └── navigation_service.dart
├── styles/ # tokens de UI: colores, tamaños, tipografías, tema
├── l10n/ # textos de la UI centralizados (app_es.arb + AppLocalizations generado)
├── models/ # Deck, Match, OpponentArchetype, Tournament,
│ # TournamentPlayer, TournamentMatch
├── services/ # ApiService (HTTP + JWT), auth, decks, matches,
│ # stats, pokemon, tournaments (tracked + hosted),
│ # friends, actualizaciones (check + descarga)
├── widgets/ # SpritePicker, SpriteAvatarGroup, SubmitOnEnter,
│ # TournamentBracket, UpdateDialog
└── screens/
├── auth/ # splash, login, registro
├── home/ # shell de navegación: Mazos / Stats / Torneos
├── profile/ # perfil, ajustes, cambio de contraseña
├── friends/ # lista, solicitudes, búsqueda de usuarios
├── decks/ # lista, detalle, formulario (crear/editar)
├── matches/ # registrar, editar
├── stats/
└── tournaments/ # listado, formulario de creación,
# detalle tracked (partidas por fase/ronda + resumen),
# jugadores, invitaciones, rondas/emparejamientos,
# bracket (embebido y pantalla completa), clasificación,
# exportar, importar (todo modo hosted)
```

## Configuración y ejecución

La URL del backend se define en `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://deck-tracker-server.onrender.com/api';
}
```

```bash
flutter pub get
flutter run -d edge   # o -d windows, -d chrome, un emulador Android, etc.
```

### GitHub Codespaces

El repo incluye `.devcontainer/` para instalar Flutter automáticamente al crear un Codespace nuevo (clona el canal `stable`, añade al `PATH`, ejecuta `flutter pub get` + `flutter precache --web`). Una vez listo:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```
y abre el puerto `8080` desde la pestaña "Ports" del Codespace.

## Deploy web

Automatizado con GitHub Actions (`.github/workflows/deploy-web.yml`): en cada push a `main` se compila `flutter build web --release` y se publica `build/web` en la rama `web-build`, desde la que sirve Render (Static Site, Publish directory: `.`). Incluye `web/_redirects` para que cualquier subruta (ej. `/decks`) sirva `index.html` en vez de dar 404 al recargar o compartir un enlace directo.

## Localización

Los textos de la UI viven en `lib/l10n/app_es.arb` y se generan como la clase `AppLocalizations` vía `flutter gen-l10n` (se dispara automáticamente en `pub get`/`build`/`run`). Añadir un idioma nuevo es solo traducir ese archivo (ej. `app_en.arb`), sin tocar código Dart. Configuración en `l10n.yaml`.

## Reportar un bug

Desde Perfil → Ajustes → "Reportar un bug", que abre un [issue form](.github/ISSUE_TEMPLATE/user_bug_report.yml) estructurado en GitHub (sin necesidad de saber Markdown). Se asigna automáticamente al mantenedor y se añade al [Project](https://github.com/users/Ayme-99/projects/7) en la columna correspondiente.

## Estilos

Todos los colores, espaciados y tipografías se aplican vía tokens (`AppColors`, `AppSizes`, `AppTextStyles`) o `Theme.of(context).colorScheme` — nunca literales fijos, o no se adaptarán al modo oscuro.

```dart
import 'package:deck_tracker_app/styles.dart';
```

Si un valor se repite en varias pantallas, añadirlo como token. Para variaciones puntuales de texto, usar `.copyWith()` sobre `AppTextStyles`.

> Nota: el bracket de eliminatoria (`lib/widgets/tournament_bracket/bracket_constants.dart`) mantiene sus propias constantes de tamaño fijas (no en `AppSizes`) a propósito: son medidas específicas de ese árbol, no reutilizadas en otras pantallas.

## Notas de desarrollo

- **Android release**: declarar `android.permission.INTERNET` en `android/app/src/main/AndroidManifest.xml` (en debug Flutter lo añade solo; en `--release` no).
- **Windows Desktop**: `flutter_secure_storage` requiere el componente "ATL de C++ (x86 & x64)" del Visual Studio Installer.
- **Cold start**: el backend está en el plan gratuito de Render; la primera petición tras inactividad puede tardar 30-50 s.
- **Peticiones y ciclo de vida**: tras cada `await` en cargas de pantalla, comprobar `mounted` antes de continuar o hacer `setState` — evita cadenas de peticiones zombis tras logout/navegación (ver issue #32).
- **Bracket de eliminatoria**: los conectores entre fases se calculan comparando `winnerId` de cada partida contra `player1Id`/`player2Id` de la siguiente, no por posición visual — necesario porque el orden de llegada de los datos no garantiza que los rivales de un mismo enfrentamiento estén ya adyacentes.
- **Navegación en web (`go_router`)**: solo las pantallas de nivel superior (Mazos/Stats/Torneos vía `StatefulShellRoute`, y Perfil como ruta independiente) tienen URL propia. El resto sigue con `Navigator.push` imperativo sobre el mismo Navigator raíz. Usar `context.go()` en vez de `context.push()` para que la URL se sincronice de forma fiable (ver issue #300).
