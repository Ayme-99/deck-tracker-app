# Deck Tracker – App

Aplicación Flutter para gestionar mazos de Pokémon TCG y registrar el resultado de las partidas jugadas, con estadísticas por mazo y globales.

## Stack

- Flutter / Dart
- `http` para consumo de API REST
- `flutter_secure_storage` para persistencia segura del token JWT
- Backend: [deck-tracker-server](https://github.com/Ayme-99/deck-tracker-server), desplegado en Render

## Estructura del proyecto

```
lib/
├── main.dart
├── config/
│   └── api_config.dart
├── styles/
│   ├── colors.dart
│   ├── sizes.dart
│   ├── text_styles.dart
│   └── theme.dart
├── models/
│   ├── deck.dart
│   └── match.dart
├── services/
│   ├── api_service.dart       # cliente HTTP base, inyecta el token JWT
│   ├── auth_service.dart
│   ├── deck_service.dart
│   ├── match_service.dart
│   └── stats_service.dart
└── screens/
├── splash_screen.dart      # comprueba sesion guardada al abrir la app
├── login_screen.dart
├── register_screen.dart
├── home_screen.dart        # navegacion: Mazos / Stats / Torneos
├── deck_list_screen.dart
├── deck_detail_screen.dart
├── create_deck_screen.dart
├── edit_deck_screen.dart
├── register_match_screen.dart
├── edit_match_screen.dart
├── stats_screen.dart
└── tournaments_screen.dart # placeholder, pendiente backend
```

## Funcionalidades

- Registro / login con persistencia de sesión (auto-login al reabrir la app)
- CRUD completo de mazos (crear, listar, ver detalle, editar, eliminar)
- Registro de partidas con autocompletado de rivales ya jugados
- Editar y eliminar partidas ya registradas
- Estadísticas por mazo: win-rate, matchups, premios cogidos/cedidos
- Estadísticas globales y ranking de mazos por win-rate
- Redirección automática a Login si la sesión deja de ser válida (token inválido o revocado)
- Para builds `--release` en Android, el permiso `android.permission.INTERNET` debe estar declarado explícitamente en `android/app/src/main/AndroidManifest.xml` (en modo debug Flutter lo añade automáticamente, pero no en release).
- Modo oscuro/claro automático según el ajuste del sistema

## Configuración

La URL del backend está definida en `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://deck-tracker-server.onrender.com/api';
}
```

## Instalación y ejecución

```bash
flutter pub get
flutter run -d edge      # o -d windows, -d chrome, un emulador Android, etc.
```

## Notas de desarrollo

- El plugin `flutter_secure_storage` en target **Windows Desktop** requiere el componente "ATL de C++ (x86 & x64)" instalado desde Visual Studio Installer (Componentes individuales).
- El backend está en Render (plan gratuito), por lo que la primera petición tras un periodo de inactividad puede tardar 30-50s en responder mientras el servidor "despierta".
- Los colores deben aplicarse vía `Theme.of(context).colorScheme` o los tokens de `AppColors`/`AppSizes`/`AppTextStyles` (`lib/styles/`), nunca como literales fijos (`Colors.black87`, etc.) — de lo contrario no se adaptan al modo oscuro.

## TODO futuro

- Pantalla de Torneos (pendiente de modelo en backend)
- Catálogo real de cartas (actualmente el `cardId` se genera a partir del nombre escrito manualmente)

## Estilos y tokens (UI)

Se ha añadido una capa de estilos reutilizables para evitar valores hardcodeados en las pantallas. Ubicación: `lib/styles/`.

- `lib/styles/colors.dart`: `AppColors` con los colores principales.
- `lib/styles/sizes.dart`: `AppSizes` con espaciados y tamaños reutilizables (ej. `spacingM`, `iconHuge`, `spinnerSmall`, `badgeWidth`).
- `lib/styles/text_styles.dart`: `AppTextStyles` para estilos de texto comunes.
- `lib/styles/theme.dart`: `buildAppTheme()` que construye el `ThemeData` principal.
- `lib/styles.dart`: export convenience file.

Buenas prácticas:

- Importar siempre con: `import 'package:deck_tracker_app/styles.dart';`
- Preferir `AppColors`, `AppSizes` y `AppTextStyles` en lugar de literales (`Colors.grey`, `SizedBox(height: 16)`, `fontSize: 16`).
- Si un valor se repite en varias pantallas, añadirlo a `AppSizes` o `AppColors`.
- Para pequeñas variaciones locales de tipografía, usar `.copyWith()` sobre `AppTextStyles`.

Refactor realizado:

- Se reemplazaron múltiples literales en `lib/screens/*` por tokens en `lib/styles/`.
- `flutter analyze` pasó sin issues tras los cambios.

¿Quieres que agregue un archivo `lib/styles/README.md` con estos lineamientos más detallados? 

### Cómo trabajar con los estilos (rápido)

1. Importa los estilos en cualquier pantalla:

```dart
import 'package:deck_tracker_app/styles.dart';
```

2. Aplica el tema global en `MaterialApp` (por ejemplo en `lib/main.dart`):

```dart
return MaterialApp(
  title: 'Deck Tracker',
  theme: buildAppTheme(),
  home: const HomeScreen(),
);
```

3. Ejemplos de uso en widgets:

```dart
Text('Título', style: AppTextStyles.title);
Container(padding: const EdgeInsets.all(AppSizes.spacingM));
Icon(Icons.star, size: AppSizes.iconNormal, color: AppColors.primary);
```

4. Reglas rápidas
- Si el valor se repite en más de 1 pantalla, añádelo a `AppSizes` o `AppColors`.
- Para variaciones de texto, usa `AppTextStyles.title.copyWith(...)` en lugar de crear un `TextStyle` desde cero.
- Documenta cualquier token nuevo con un nombre claro (p. ej. `spacingSM` para 12px, `badgeWidth` para anchuras pequeñas reutilizables).

5. Verificación
- Ejecuta `flutter analyze` después de cambios y revisa visualmente con `flutter run`.

Si quieres, puedo añadir al README ejemplos de commit/PR para este tipo de cambios o generar una entrada breve con las convenciones de nombrado.