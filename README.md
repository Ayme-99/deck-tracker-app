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

## TODO futuro

- Pantalla de Torneos (pendiente de modelo en backend)
- Catálogo real de cartas (actualmente el `cardId` se genera a partir del nombre escrito manualmente)