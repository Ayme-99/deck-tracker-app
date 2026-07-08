# Deck Tracker – App

Aplicación Flutter para gestionar mazos de Pokémon TCG y registrar partidas, con estadísticas por mazo y globales.

**Demo web:** https://deck-tracker-web.onrender.com

## Stack

- Flutter / Dart
- `http` (API REST) · `flutter_secure_storage` (token JWT)
- Backend: [deck-tracker-server](https://github.com/Ayme-99/deck-tracker-server) (Node.js/Express/MongoDB, desplegado en Render)

## Funcionalidades

- **Auth**: registro, login y auto-login con sesión persistente; redirección a Login si el token deja de ser válido.
- **Mazos**: CRUD completo, vista en grid adaptable con buscador, récord de partidas y orden por actividad reciente.
- **Partidas**: registro, edición y borrado, con autocompletado de rivales ya jugados.
- **Estadísticas**: win-rate, matchups y premios por mazo; stats globales y ranking ordenable (win rate, nº de partidas, nombre) con mínimo de partidas ajustable.
- **UI**: modo oscuro/claro automático, sprites de Pokémon para mazos y rivales (PokeAPI), aviso de cold start del backend si una carga tarda más de 5 s.

## Estructura del proyecto

```
lib/
├── main.dart
├── config/api_config.dart      # URL del backend
├── styles/                     # tokens de UI: colores, tamaños, tipografías, tema
├── models/                     # Deck, Match, OpponentArchetype
├── services/                   # ApiService (HTTP + JWT), auth, decks, matches, stats, pokemon
├── widgets/                    # SpritePicker, SpriteAvatarGroup
└── screens/
    ├── auth/                   # splash, login, registro
    ├── home/                   # navegación: Mazos / Stats / Torneos
    ├── decks/                  # lista, detalle, formulario (crear/editar)
    ├── matches/                # registrar, editar
    ├── stats/
    └── tournaments/            # placeholder, pendiente backend
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

## Deploy web

Automatizado con GitHub Actions (`.github/workflows/deploy-web.yml`): en cada push a `main` se compila `flutter build web --release` y se publica `build/web` en la rama `web-build`, desde la que sirve Render (Static Site, Publish directory: `.`).

## Estilos

Todos los colores, espaciados y tipografías se aplican vía tokens (`AppColors`, `AppSizes`, `AppTextStyles`) o `Theme.of(context).colorScheme` — nunca literales fijos, o no se adaptarán al modo oscuro.

```dart
import 'package:deck_tracker_app/styles.dart';
```

Si un valor se repite en varias pantallas, añadirlo como token. Para variaciones puntuales de texto, usar `.copyWith()` sobre `AppTextStyles`.

## Notas de desarrollo

- **Android release**: declarar `android.permission.INTERNET` en `android/app/src/main/AndroidManifest.xml` (en debug Flutter lo añade solo; en `--release` no).
- **Windows Desktop**: `flutter_secure_storage` requiere el componente "ATL de C++ (x86 & x64)" del Visual Studio Installer.
- **Cold start**: el backend está en el plan gratuito de Render; la primera petición tras inactividad puede tardar 30-50 s.

## TODO

- [ ] Feature de Torneos (pendiente del modelo en backend)
- [ ] Widget de pantalla de inicio (Android)
- [ ] Formato cooperativo "Incursiones"
