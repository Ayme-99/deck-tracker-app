# Deck Tracker – App

Aplicación Flutter para gestionar mazos de Pokémon TCG, registrar partidas, ver estadísticas y organizar torneos completos: seguimiento del propio historial (**tracked**) o torneos alojados por la app con varios jugadores (**hosted**).

**Demo web:** https://deck-tracker-web.onrender.com

## Stack

- Flutter / Dart
- `http` (API REST) · `flutter_secure_storage` (token JWT)
- Backend: [deck-tracker-server](https://github.com/Ayme-99/deck-tracker-server) (Node.js/Express/MongoDB, desplegado en Render)

## Funcionalidades

- **Auth**: registro, login y auto-login con sesión persistente; redirección a Login si el token deja de ser válido. Manejo de sesión robusto frente al cold start del backend: los 401 de peticiones lanzadas antes de un logout (sin token) no expulsan la sesión ni borran el token actual. Enter funciona como "Aceptar" en los formularios principales (login, registro, mazos, partidas, torneos, jugadores).
- **Mazos**: CRUD completo, vista en grid adaptable con buscador, récord de partidas y orden por actividad reciente. Al eliminar un mazo se borran también sus partidas (cascada en backend); el diálogo de confirmación avisa del nº de partidas afectadas. Al añadir cartas al mazo, autocompletado contra el catálogo real de [TCGdex](https://tcgdex.dev) (issue #12): si se elige una sugerencia se guarda el `cardId` oficial; si no hay coincidencia, se conserva el slug generado a mano como hasta ahora.
- **Partidas**: registro, edición y borrado, con autocompletado de rivales ya jugados.
- **Estadísticas**: win-rate, matchups y premios por mazo; stats globales y ranking ordenable (win rate, nº de partidas, nombre) con mínimo de partidas ajustable; win-rate contra cada arquetipo rival agregado a lo largo de todos los mazos propios.
- **Torneos — modo tracked**: creación con 5 estructuras (suiza, suiza+eliminatoria, grupos+eliminatoria, eliminatoria directa, liga), detalle con partidas agrupadas por fase/ronda, resumen W-L-T global y por fase, standing manual para ligas, opciones de editar estado/eliminar mediante long-press.
- **Torneos — modo hosted**: la app aloja el torneo completo.
  - Gestión de jugadores (inscripciones sin cuenta propia), con autocompletado de arquetipo y opción de vincular tu propio mazo real si participas.
  - Rondas y emparejamientos: generación automática por estructura (suiza, grupos, liga, eliminatoria), registro de resultados, avance de fase, pestañas combinadas por ronda/fase.
  - Bracket de eliminatoria visual, con conectores calculados por datos reales (no por posición), y pantalla independiente con pan/zoom (botón de recentrar) para brackets grandes.
  - Clasificación en vivo: puntos, W-L-D y desempates (diferencial de premios, luego OMW%).
  - Exportar/Importar torneos completos entre usuarios (JSON), preservando todo el historial y resultados ya jugados; al importar, opción de vincular una inscripción a tu propia cuenta y mazo.
  - Bracket de eliminatoria: hasta 64 jugadores en la primera ronda (issue #92).
- **UI**: modo oscuro/claro automático, sprites de Pokémon para mazos y rivales (PokeAPI), aviso de cold start del backend si una carga tarda más de 5 s.

## Estructura del proyecto

```
lib/
├── main.dart
├── config/api_config.dart # URL del backend
├── styles/ # tokens de UI: colores, tamaños, tipografías, tema
├── models/ # Deck, Match, OpponentArchetype, Tournament,
│ # TournamentPlayer, TournamentMatch
├── services/ # ApiService (HTTP + JWT), auth, decks, matches,
│ # stats, pokemon, tournaments (tracked + hosted)
├── widgets/ # SpritePicker, SpriteAvatarGroup, SubmitOnEnter,
│ # TournamentBracket
└── screens/
├── auth/ # splash, login, registro
├── home/ # navegación: Mazos / Stats / Torneos
├── decks/ # lista, detalle, formulario (crear/editar)
├── matches/ # registrar, editar
├── stats/
└── tournaments/ # listado, formulario de creación,
# detalle tracked (partidas por fase/ronda + resumen),
# jugadores, rondas/emparejamientos, bracket
# (embebido y pantalla completa), clasificación,
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

Automatizado con GitHub Actions (`.github/workflows/deploy-web.yml`): en cada push a `main` se compila `flutter build web --release` y se publica `build/web` en la rama `web-build`, desde la que sirve Render (Static Site, Publish directory: `.`).

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

## TODO

- [x] Ampliar bracket de eliminatoria hasta 64 jugadores (issue #92)
- [x] Pasada de limpieza de UI en pantallas de torneos hosted (tokens de estilo)
- [ ] Editar torneo ya creado en modo tracked (por ahora solo se puede crear, marcar finalizado/en curso o eliminar)
- [ ] Widget de pantalla de inicio (Android)
- [ ] Formato cooperativo "Incursiones"