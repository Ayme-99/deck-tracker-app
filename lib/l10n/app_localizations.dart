import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Nombre de la app, mostrado en el titulo de la ventana/pestana
  ///
  /// In es, this message translates to:
  /// **'Deck Tracker'**
  String get appTitle;

  /// Etiqueta del campo de usuario en login/registro
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get usernameLabel;

  /// Etiqueta del campo de contraseña en login/registro
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// Validacion: usuario vacio en login
  ///
  /// In es, this message translates to:
  /// **'Introduce tu usuario'**
  String get loginUsernameRequired;

  /// Validacion: contraseña vacia en login
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get loginPasswordRequired;

  /// Boton para enviar el formulario de login
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get loginSubmitButton;

  /// Aviso cuando el login tarda por el cold start del servidor
  ///
  /// In es, this message translates to:
  /// **'Despertando el servidor, puede tardar unos segundos...'**
  String get loginServerWakingUp;

  /// Enlace para ir a la pantalla de registro
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get loginRegisterLink;

  /// Mensaje mostrado al llegar a login tras expirar la sesion
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado, inicia sesión de nuevo'**
  String get loginSessionExpired;

  /// Titulo de la pantalla de registro
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerScreenTitle;

  /// Validacion: usuario vacio en registro
  ///
  /// In es, this message translates to:
  /// **'Introduce un usuario'**
  String get registerUsernameRequired;

  /// Validacion: contraseña demasiado corta
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get registerPasswordMinLength;

  /// Etiqueta del campo de confirmar contraseña
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña'**
  String get registerConfirmPasswordLabel;

  /// Validacion: confirmar contraseña vacio
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña'**
  String get registerConfirmPasswordRequired;

  /// Validacion: las dos contraseñas no coinciden
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get registerPasswordsDontMatch;

  /// Boton para enviar el formulario de registro
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerSubmitButton;

  /// Titulo de la pantalla de backup
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad'**
  String get backupScreenTitle;

  /// Confirmacion tras exportar backup
  ///
  /// In es, this message translates to:
  /// **'Backup exportado: {decks} mazos, {tournaments} torneos, {matches} partidas'**
  String backupExportedSnackbar(
    Object decks,
    Object tournaments,
    Object matches,
  );

  /// Accion del snackbar para abrir el archivo exportado
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get backupOpenAction;

  /// Error al exportar backup
  ///
  /// In es, this message translates to:
  /// **'Error al exportar: {error}'**
  String backupExportError(Object error);

  /// Error al leer un archivo de backup corrupto
  ///
  /// In es, this message translates to:
  /// **'El archivo no es un backup válido (JSON corrupto)'**
  String get backupInvalidFile;

  /// Titulo del dialogo de confirmacion de restauracion
  ///
  /// In es, this message translates to:
  /// **'Restaurar backup'**
  String get backupRestoreDialogTitle;

  /// Contenido del dialogo de confirmacion de restauracion
  ///
  /// In es, this message translates to:
  /// **'Vas a añadir {decks} mazos, {matches} partidas y {tournaments} torneos a tu cuenta actual como entidades nuevas -- no sobrescribe ni borra nada de lo que ya tengas. Si restauras el mismo backup dos veces, tendrás los mazos duplicados.'**
  String backupRestoreDialogContent(
    Object decks,
    Object matches,
    Object tournaments,
  );

  /// Boton generico para cancelar un dialogo
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelAction;

  /// Boton para confirmar la restauracion
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get backupRestoreAction;

  /// Confirmacion tras restaurar backup
  ///
  /// In es, this message translates to:
  /// **'Restaurado: {decks} mazos, {tournaments} torneos, {matches} partidas'**
  String backupRestoredSnackbar(
    Object decks,
    Object tournaments,
    Object matches,
  );

  /// Error al restaurar backup
  ///
  /// In es, this message translates to:
  /// **'Error al restaurar: {error}'**
  String backupRestoreError(Object error);

  /// Texto explicativo de la pantalla de backup
  ///
  /// In es, this message translates to:
  /// **'Exporta todos tus mazos, partidas y torneos seguidos (no alojados) a un único archivo, para migrar de cuenta o tener una copia de seguridad manual.'**
  String get backupDescription;

  /// Boton para exportar el backup
  ///
  /// In es, this message translates to:
  /// **'Exportar backup'**
  String get backupExportButton;

  /// Boton para restaurar desde un archivo
  ///
  /// In es, this message translates to:
  /// **'Restaurar desde archivo'**
  String get backupRestoreButton;

  /// Error al eliminar un mazo
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar \"{name}\": {error}'**
  String deckDeleteError(Object name, Object error);

  /// Confirmacion tras eliminar un mazo
  ///
  /// In es, this message translates to:
  /// **'Mazo \"{name}\" eliminado'**
  String deckDeletedSnackbar(Object name);

  /// Opcion de ordenacion por nombre
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get sortByName;

  /// Opcion de ordenacion por victorias
  ///
  /// In es, this message translates to:
  /// **'Más victorias'**
  String get sortByMostWins;

  /// Opcion de ordenacion por win rate
  ///
  /// In es, this message translates to:
  /// **'Win rate'**
  String get sortByWinRate;

  /// Opcion de ordenacion por actividad reciente
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get sortByRecentActivity;

  /// Accion del menu de opciones de un mazo
  ///
  /// In es, this message translates to:
  /// **'Editar mazo'**
  String get editDeckAction;

  /// Accion del menu de opciones de un mazo
  ///
  /// In es, this message translates to:
  /// **'Duplicar mazo'**
  String get duplicateDeckAction;

  /// Accion del menu de opciones de un mazo, y titulo del dialogo de confirmacion
  ///
  /// In es, this message translates to:
  /// **'Eliminar mazo'**
  String get deleteDeckAction;

  /// Confirmacion de borrado de mazo con partidas asociadas
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar \"{name}\"? Se eliminarán también sus {count} partidas registradas y dejarán de contar en tus estadísticas.'**
  String deleteDeckConfirmWithMatches(Object name, Object count);

  /// Confirmacion de borrado de mazo sin partidas
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar \"{name}\"?'**
  String deleteDeckConfirmSimple(Object name);

  /// Boton generico para confirmar un borrado
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteAction;

  /// Placeholder del buscador de mazos
  ///
  /// In es, this message translates to:
  /// **'Buscar mazo por nombre'**
  String get deckSearchHint;

  /// Texto del menu de ordenacion actual
  ///
  /// In es, this message translates to:
  /// **'Ordenar: {sortLabel}'**
  String sortByLabel(Object sortLabel);

  /// Aviso de datos cacheados sin conexion
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · mostrando datos guardados'**
  String get offlineShowingSavedData;

  /// Titulo de estado vacio de mazos
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes mazos'**
  String get noDecksYetTitle;

  /// Subtitulo de estado vacio de mazos
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer mazo para empezar a registrar partidas'**
  String get noDecksYetSubtitle;

  /// Error al cargar la lista de mazos
  ///
  /// In es, this message translates to:
  /// **'Error al cargar mazos: {error}'**
  String deckLoadError(Object error);

  /// Boton para crear un mazo
  ///
  /// In es, this message translates to:
  /// **'Crear mazo'**
  String get createDeckAction;

  /// Estado vacio de busqueda de mazos sin resultados
  ///
  /// In es, this message translates to:
  /// **'Ningún mazo coincide con \"{query}\"'**
  String noDeckMatchesSearch(Object query);

  /// Titulo del dialogo de importacion de lista de cartas
  ///
  /// In es, this message translates to:
  /// **'Importar desde Pokémon TCG Live'**
  String get importFromTcgLiveTitle;

  /// Aviso al importar cartas con mazo ya con cartas
  ///
  /// In es, this message translates to:
  /// **'Esto sustituirá la lista de cartas actual.'**
  String get importReplacesCurrentList;

  /// Placeholder del campo de pegar lista de TCG Live
  ///
  /// In es, this message translates to:
  /// **'Pega aquí la lista exportada desde TCG Live'**
  String get importPasteHint;

  /// Boton para confirmar una importacion
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get importAction;

  /// Error al no reconocer cartas en el texto pegado
  ///
  /// In es, this message translates to:
  /// **'No se ha reconocido ninguna carta en el texto pegado'**
  String get importNoCardsRecognized;

  /// Titulo de la pantalla al editar un mazo
  ///
  /// In es, this message translates to:
  /// **'Editar Mazo'**
  String get deckFormEditTitle;

  /// Titulo de la pantalla al duplicar un mazo
  ///
  /// In es, this message translates to:
  /// **'Duplicar Mazo'**
  String get deckFormDuplicateTitle;

  /// Titulo de la pantalla al crear un mazo
  ///
  /// In es, this message translates to:
  /// **'Nuevo Mazo'**
  String get deckFormNewTitle;

  /// Etiqueta del campo de nombre del mazo
  ///
  /// In es, this message translates to:
  /// **'Nombre del mazo'**
  String get deckNameLabel;

  /// Validacion: nombre de mazo vacio
  ///
  /// In es, this message translates to:
  /// **'Introduce un nombre'**
  String get deckNameRequired;

  /// Titulo de la seccion de cartas del formulario de mazo
  ///
  /// In es, this message translates to:
  /// **'Cartas'**
  String get cardsSectionTitle;

  /// Boton para anadir una carta al mazo
  ///
  /// In es, this message translates to:
  /// **'Añadir carta'**
  String get addCardAction;

  /// Estado vacio de cartas al editar un mazo
  ///
  /// In es, this message translates to:
  /// **'No hay cartas añadidas'**
  String get noCardsAddedYet;

  /// Estado vacio de cartas al crear un mazo
  ///
  /// In es, this message translates to:
  /// **'Puedes añadir cartas ahora o más tarde'**
  String get canAddCardsLater;

  /// Etiqueta del campo de nombre de una carta
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get cardNameLabel;

  /// Validacion generica de campo requerido
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get requiredFieldError;

  /// Etiqueta del campo de cantidad de una carta
  ///
  /// In es, this message translates to:
  /// **'Cant.'**
  String get cardQuantityLabel;

  /// Validacion: cantidad de carta invalida
  ///
  /// In es, this message translates to:
  /// **'Nº entero > 0'**
  String get cardQuantityInvalid;

  /// Etiqueta del campo de tipo/categoria de una carta
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get cardCategoryLabel;

  /// Categoria de carta: Pokemon
  ///
  /// In es, this message translates to:
  /// **'Pokémon'**
  String get cardCategoryPokemon;

  /// Categoria de carta: Entrenador
  ///
  /// In es, this message translates to:
  /// **'Entrenador'**
  String get cardCategoryTrainer;

  /// Categoria de carta: Energia
  ///
  /// In es, this message translates to:
  /// **'Energía'**
  String get cardCategoryEnergy;

  /// Boton para guardar cambios de un formulario
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChangesAction;

  /// Error al eliminar una partida
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar la partida: {error}'**
  String matchDeleteError(Object error);

  /// Confirmacion tras eliminar una partida
  ///
  /// In es, this message translates to:
  /// **'Partida contra \"{opponent}\" eliminada'**
  String matchDeletedSnackbar(Object opponent);

  /// Accion del menu de opciones de una partida
  ///
  /// In es, this message translates to:
  /// **'Editar partida'**
  String get editMatchAction;

  /// Accion del menu de opciones de una partida
  ///
  /// In es, this message translates to:
  /// **'Compartir partida'**
  String get shareMatchAction;

  /// Accion del menu de opciones de una partida, y titulo del dialogo de confirmacion
  ///
  /// In es, this message translates to:
  /// **'Eliminar partida'**
  String get deleteMatchAction;

  /// Confirmacion de borrado de una partida
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la partida contra \"{opponent}\"?'**
  String deleteMatchConfirm(Object opponent);

  /// Confirmacion de borrado de mazo desde su detalle
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar \"{name}\"?'**
  String deleteDeckDetailConfirm(Object name);

  /// Confirmacion tras exportar historial de partidas
  ///
  /// In es, this message translates to:
  /// **'Historial exportado a Descargas'**
  String get matchHistoryExported;

  /// Accion generica de un snackbar para abrir un archivo
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get openAction;

  /// Error generico al exportar
  ///
  /// In es, this message translates to:
  /// **'Error al exportar: {error}'**
  String exportError(Object error);

  /// Accion del menu de opciones de un mazo, exportar partidas a CSV
  ///
  /// In es, this message translates to:
  /// **'Exportar partidas a CSV'**
  String get exportMatchesToCsvAction;

  /// Etiqueta generica de error con detalle
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String genericErrorLabel(Object error);

  /// Boton generico para reintentar tras un error
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retryAction;

  /// Boton flotante para registrar una partida
  ///
  /// In es, this message translates to:
  /// **'Partida'**
  String get registerMatchAction;

  /// Titulo de la seccion de matchups
  ///
  /// In es, this message translates to:
  /// **'Matchups'**
  String get matchupsSectionTitle;

  /// Tooltip para cambiar a vista de lista
  ///
  /// In es, this message translates to:
  /// **'Ver como lista'**
  String get viewAsListTooltip;

  /// Tooltip para cambiar a vista de mapa de calor
  ///
  /// In es, this message translates to:
  /// **'Ver como mapa de calor'**
  String get viewAsHeatmapTooltip;

  /// Estado vacio de matchups sin partidas
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay partidas registradas'**
  String get noMatchesRegisteredYet;

  /// Tooltip de un matchup con resultado
  ///
  /// In es, this message translates to:
  /// **'{opponent}\n{wins}V - {losses}D - {ties}E'**
  String matchupTooltip(
    Object opponent,
    Object wins,
    Object losses,
    Object ties,
  );

  /// Resumen V-D-E de un matchup
  ///
  /// In es, this message translates to:
  /// **'{wins}V - {losses}D - {ties}E'**
  String matchResultSummary(Object wins, Object losses, Object ties);

  /// Titulo de la seccion de partidas recientes
  ///
  /// In es, this message translates to:
  /// **'Partidas recientes'**
  String get recentMatchesSectionTitle;

  /// Resultado de partida: victoria
  ///
  /// In es, this message translates to:
  /// **'Victoria'**
  String get matchResultWin;

  /// Resultado de partida: derrota
  ///
  /// In es, this message translates to:
  /// **'Derrota'**
  String get matchResultLoss;

  /// Resultado de partida: empate
  ///
  /// In es, this message translates to:
  /// **'Empate'**
  String get matchResultTie;

  /// Titulo de una fila de partida, contra que rival
  ///
  /// In es, this message translates to:
  /// **'vs {opponent}'**
  String matchVsOpponent(Object opponent);

  /// Subtitulo de una fila de partida: resultado y premios
  ///
  /// In es, this message translates to:
  /// **'{result} · {userPrizes}-{opponentPrizes}'**
  String matchResultAndPrizes(
    Object result,
    Object userPrizes,
    Object opponentPrizes,
  );

  /// Boton para ampliar una lista paginada
  ///
  /// In es, this message translates to:
  /// **'Mostrar más'**
  String get showMoreAction;

  /// Boton para colapsar una lista ampliada
  ///
  /// In es, this message translates to:
  /// **'Ocultar'**
  String get hideAction;

  /// Error generico al buscar
  ///
  /// In es, this message translates to:
  /// **'Error al buscar: {error}'**
  String searchError(Object error);

  /// Error generico con prefijo Error:
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String genericErrorPrefix(Object error);

  /// Titulo del dialogo de confirmacion para eliminar un amigo
  ///
  /// In es, this message translates to:
  /// **'Eliminar amistad'**
  String get removeFriendshipTitle;

  /// Confirmacion de borrado de amistad
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar a \"{username}\" de tus amigos?'**
  String removeFriendshipConfirm(Object username);

  /// Error al eliminar una amistad
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar: {error}'**
  String removeFriendshipError(Object error);

  /// Estado vacio de la lista de amigos
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes amigos añadidos'**
  String get noFriendsYet;

  /// Tooltip del boton de eliminar amistad
  ///
  /// In es, this message translates to:
  /// **'Eliminar amistad'**
  String get removeFriendshipTooltip;

  /// Estado vacio de solicitudes de amistad
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes pendientes'**
  String get noPendingRequests;

  /// Titulo de la seccion de solicitudes entrantes
  ///
  /// In es, this message translates to:
  /// **'Entrantes'**
  String get incomingRequestsTitle;

  /// Boton para aceptar una solicitud
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get acceptAction;

  /// Boton para rechazar una solicitud
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get rejectAction;

  /// Titulo de la seccion de solicitudes salientes
  ///
  /// In es, this message translates to:
  /// **'Salientes'**
  String get outgoingRequestsTitle;

  /// Estado de una solicitud de amistad pendiente
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get pendingStatus;

  /// Placeholder del buscador de usuarios
  ///
  /// In es, this message translates to:
  /// **'Buscar por username'**
  String get searchByUsernameHint;

  /// Prompt inicial del buscador de usuarios
  ///
  /// In es, this message translates to:
  /// **'Busca a alguien por su nombre de usuario'**
  String get searchByUsernamePrompt;

  /// Estado de busqueda sin resultados
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get noResultsFound;

  /// Estado de una solicitud de amistad ya enviada
  ///
  /// In es, this message translates to:
  /// **'Enviada'**
  String get requestSentStatus;

  /// Boton generico para anadir/enviar una solicitud
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get addAction;

  /// Titulo de la pantalla de amigos
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get friendsScreenTitle;

  /// Pestana de lista de amigos
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get friendsTabLabel;

  /// Pestana de solicitudes de amistad
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get requestsTabLabel;

  /// Pestana de busqueda de usuarios
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get searchTabLabel;

  /// Titulo de la pestana de mazos
  ///
  /// In es, this message translates to:
  /// **'Mis Mazos'**
  String get homeTitleDecks;

  /// Titulo de la pestana de estadisticas
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get homeTitleStats;

  /// Titulo de la pestana de torneos
  ///
  /// In es, this message translates to:
  /// **'Torneos'**
  String get homeTitleTournaments;

  /// Tooltip del icono de busqueda global
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get searchTooltip;

  /// Tooltip del icono de importar torneo
  ///
  /// In es, this message translates to:
  /// **'Importar torneo'**
  String get importTournamentTooltip;

  /// Tooltip del icono de perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTooltip;

  /// Boton flotante para anadir un mazo
  ///
  /// In es, this message translates to:
  /// **'Añadir mazo'**
  String get addDeckAction;

  /// Boton flotante para crear un torneo
  ///
  /// In es, this message translates to:
  /// **'Crear torneo'**
  String get createTournamentAction;

  /// Etiqueta de la pestana inferior de mazos
  ///
  /// In es, this message translates to:
  /// **'Mazos'**
  String get navDecksLabel;

  /// Etiqueta de la pestana inferior de estadisticas
  ///
  /// In es, this message translates to:
  /// **'Stats'**
  String get navStatsLabel;

  /// Etiqueta de la pestana inferior de torneos
  ///
  /// In es, this message translates to:
  /// **'Torneos'**
  String get navTournamentsLabel;

  /// Motivo de fin de partida: normal
  ///
  /// In es, this message translates to:
  /// **'Normal (premios completos)'**
  String get endReasonNormal;

  /// Motivo de fin de partida: rendicion
  ///
  /// In es, this message translates to:
  /// **'Rendición'**
  String get endReasonConcession;

  /// Motivo de fin de partida: sin pokemon en banca
  ///
  /// In es, this message translates to:
  /// **'Sin Pokémon en banca'**
  String get endReasonNoPokemon;

  /// Motivo de fin de partida: tiempo agotado
  ///
  /// In es, this message translates to:
  /// **'Tiempo agotado'**
  String get endReasonTime;

  /// Motivo de fin de partida: mazo agotado
  ///
  /// In es, this message translates to:
  /// **'Mazo agotado'**
  String get endReasonDeckOut;

  /// Titulo de la pantalla de registrar partida
  ///
  /// In es, this message translates to:
  /// **'Nueva partida · {deckName}'**
  String newMatchTitle(Object deckName);

  /// Etiqueta de ronda actual
  ///
  /// In es, this message translates to:
  /// **'Ronda {round}'**
  String roundLabel(Object round);

  /// Etiqueta del campo de mazo rival
  ///
  /// In es, this message translates to:
  /// **'Mazo rival'**
  String get opponentDeckLabel;

  /// Texto de ayuda del campo de mazo rival
  ///
  /// In es, this message translates to:
  /// **'Empieza a escribir para ver sugerencias'**
  String get opponentDeckHelper;

  /// Validacion: mazo rival vacio
  ///
  /// In es, this message translates to:
  /// **'Introduce el mazo rival'**
  String get opponentDeckRequired;

  /// Etiqueta del contador de premios propios
  ///
  /// In es, this message translates to:
  /// **'Tus premios'**
  String get yourPrizesLabel;

  /// Etiqueta del contador de premios del rival
  ///
  /// In es, this message translates to:
  /// **'Premios rival'**
  String get opponentPrizesLabel;

  /// Aviso al necesitar elegir resultado manual
  ///
  /// In es, this message translates to:
  /// **'Selecciona quién ganó realmente: no se calcula a partir de los premios, y este resultado es el que se guarda en tus estadísticas'**
  String get manualResultWarning;

  /// Opcion de resultado manual: victoria propia
  ///
  /// In es, this message translates to:
  /// **'Gané'**
  String get manualResultWin;

  /// Opcion de resultado manual: empate
  ///
  /// In es, this message translates to:
  /// **'Empate'**
  String get manualResultTie;

  /// Opcion de resultado manual: derrota propia
  ///
  /// In es, this message translates to:
  /// **'Perdí'**
  String get manualResultLoss;

  /// Resultado calculado: victoria
  ///
  /// In es, this message translates to:
  /// **'🏆 Victoria'**
  String get resultVictoryEmoji;

  /// Resultado calculado: derrota
  ///
  /// In es, this message translates to:
  /// **'❌ Derrota'**
  String get resultDefeatEmoji;

  /// Resultado calculado: empate
  ///
  /// In es, this message translates to:
  /// **'🤝 Empate'**
  String get resultTieEmoji;

  /// Etiqueta del selector de motivo de fin de partida
  ///
  /// In es, this message translates to:
  /// **'Motivo de fin de partida'**
  String get matchEndReasonLabel;

  /// Etiqueta del campo de notas opcionales
  ///
  /// In es, this message translates to:
  /// **'Notas (opcional)'**
  String get notesOptionalLabel;

  /// Boton para registrar una partida
  ///
  /// In es, this message translates to:
  /// **'Registrar partida'**
  String get registerMatchButton;

  /// Confirmacion tras registrar una partida en modo encadenado
  ///
  /// In es, this message translates to:
  /// **'Partida registrada. Lista para la siguiente.'**
  String get registerMatchReadyForNext;

  /// Boton para registrar una partida y encadenar otra
  ///
  /// In es, this message translates to:
  /// **'Registrar y añadir otra'**
  String get registerAndAddAnother;

  /// Titulo de la pantalla de editar partida
  ///
  /// In es, this message translates to:
  /// **'Editar partida'**
  String get editMatchTitle;

  /// Titulo del selector rapido de mazo
  ///
  /// In es, this message translates to:
  /// **'Registrar partida'**
  String get quickRegisterTitle;

  /// Estado vacio del selector rapido de mazo
  ///
  /// In es, this message translates to:
  /// **'Crea un mazo desde la app para poder registrar partidas'**
  String get createDeckToRegisterMatches;

  /// Color de acento: azul
  ///
  /// In es, this message translates to:
  /// **'Azul'**
  String get accentColorBlue;

  /// Color de acento: morado
  ///
  /// In es, this message translates to:
  /// **'Morado'**
  String get accentColorPurple;

  /// Color de acento: verde
  ///
  /// In es, this message translates to:
  /// **'Verde'**
  String get accentColorGreen;

  /// Color de acento: rojo
  ///
  /// In es, this message translates to:
  /// **'Rojo'**
  String get accentColorRed;

  /// Color de acento: turquesa
  ///
  /// In es, this message translates to:
  /// **'Turquesa'**
  String get accentColorTeal;

  /// Color de acento: naranja
  ///
  /// In es, this message translates to:
  /// **'Naranja'**
  String get accentColorOrange;

  /// Titulo del dialogo de eleccion de color de acento
  ///
  /// In es, this message translates to:
  /// **'Color de acento'**
  String get accentColorPickerTitle;

  /// Titulo del dialogo de eleccion de tema
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get themePickerTitle;

  /// Opcion de tema: automatico segun el sistema
  ///
  /// In es, this message translates to:
  /// **'Automático (sistema)'**
  String get themeModeSystem;

  /// Opcion de tema: claro
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeModeLight;

  /// Opcion de tema: oscuro
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeModeDark;

  /// Accion del menu de ajustes: copia de seguridad
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad'**
  String get backupSettingsAction;

  /// Accion del menu de ajustes: color de acento
  ///
  /// In es, this message translates to:
  /// **'Color de acento'**
  String get accentColorSettingsAction;

  /// Accion del menu de ajustes: tema
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get themeSettingsAction;

  /// Accion del menu de ajustes: cerrar sesion
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logoutAction;

  /// Titulo de la pantalla de perfil
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get myProfileTitle;

  /// Tooltip del icono de ajustes
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTooltip;

  /// Tooltip del boton de volver en pantallas secundarias
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get backTooltip;

  /// Nombre de usuario por defecto si no se pudo cargar
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get defaultUsername;

  /// Accion del perfil para ir a la pantalla de amigos
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get friendsMenuAction;

  /// Accion del perfil para ir a las invitaciones a torneos
  ///
  /// In es, this message translates to:
  /// **'Invitaciones a torneos'**
  String get tournamentInvitesMenuAction;

  /// Placeholder del buscador global
  ///
  /// In es, this message translates to:
  /// **'Buscar mazos, torneos, rivales...'**
  String get globalSearchHint;

  /// Prompt inicial del buscador global
  ///
  /// In es, this message translates to:
  /// **'Escribe para buscar entre tus mazos, torneos y rivales'**
  String get globalSearchPrompt;

  /// Estado sin resultados del buscador global
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para \"{query}\"'**
  String globalSearchNoResults(Object query);

  /// Titulo de seccion: mazos
  ///
  /// In es, this message translates to:
  /// **'Mazos'**
  String get sectionDecks;

  /// Titulo de seccion: torneos
  ///
  /// In es, this message translates to:
  /// **'Torneos'**
  String get sectionTournaments;

  /// Titulo de seccion: rivales
  ///
  /// In es, this message translates to:
  /// **'Rivales'**
  String get sectionRivals;

  /// Fase de partida: fase de grupos
  ///
  /// In es, this message translates to:
  /// **'Fase de grupos'**
  String get matchPhaseGroupStage;

  /// Fase de partida: suiza
  ///
  /// In es, this message translates to:
  /// **'Suiza'**
  String get matchPhaseSwiss;

  /// Fase de partida: octavos
  ///
  /// In es, this message translates to:
  /// **'Octavos'**
  String get matchPhaseRoundOf16;

  /// Fase de partida: cuartos
  ///
  /// In es, this message translates to:
  /// **'Cuartos'**
  String get matchPhaseQuarterfinal;

  /// Fase de partida: semifinal
  ///
  /// In es, this message translates to:
  /// **'Semifinal'**
  String get matchPhaseSemifinal;

  /// Fase de partida: final
  ///
  /// In es, this message translates to:
  /// **'Final'**
  String get matchPhaseFinal;

  /// Fase de partida: jornada de liga
  ///
  /// In es, this message translates to:
  /// **'Jornada'**
  String get matchPhaseLeagueRound;

  /// Estructura de torneo: suizas
  ///
  /// In es, this message translates to:
  /// **'Rondas suizas'**
  String get tournamentStructureSwiss;

  /// Estructura de torneo: suizas mas eliminatoria
  ///
  /// In es, this message translates to:
  /// **'Suizas + eliminatoria'**
  String get tournamentStructureSwissElimination;

  /// Estructura de torneo: grupos mas eliminatoria
  ///
  /// In es, this message translates to:
  /// **'Fase de grupos + eliminatoria'**
  String get tournamentStructureGroupsElimination;

  /// Estructura de torneo: eliminatoria directa
  ///
  /// In es, this message translates to:
  /// **'Eliminatoria directa'**
  String get tournamentStructureElimination;

  /// Estructura de torneo: liga
  ///
  /// In es, this message translates to:
  /// **'Liga'**
  String get tournamentStructureLeague;

  /// Fase de partida hosted: fase de 64
  ///
  /// In es, this message translates to:
  /// **'Fase de 64'**
  String get matchPhaseRoundOf64;

  /// Fase de partida hosted: dieciseisavos
  ///
  /// In es, this message translates to:
  /// **'Dieciseisavos'**
  String get matchPhaseRoundOf32;

  /// Titulo del dialogo de eleccion de fase de una partida
  ///
  /// In es, this message translates to:
  /// **'¿En qué fase se juega?'**
  String get selectMatchPhaseTitle;

  /// Etiqueta del selector de fase
  ///
  /// In es, this message translates to:
  /// **'Fase'**
  String get matchPhaseLabel;

  /// Boton generico para continuar
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueAction;

  /// Cabecera CSV: fecha
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get csvHeaderDate;

  /// Cabecera CSV: rival
  ///
  /// In es, this message translates to:
  /// **'Rival'**
  String get csvHeaderOpponent;

  /// Cabecera CSV: resultado
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get csvHeaderResult;

  /// Cabecera CSV: mis premios
  ///
  /// In es, this message translates to:
  /// **'Mis premios'**
  String get csvHeaderMyPrizes;

  /// Cabecera CSV: premios rival
  ///
  /// In es, this message translates to:
  /// **'Premios rival'**
  String get csvHeaderOpponentPrizes;

  /// Cabecera CSV: fase
  ///
  /// In es, this message translates to:
  /// **'Fase'**
  String get csvHeaderPhase;

  /// Cabecera CSV: ronda
  ///
  /// In es, this message translates to:
  /// **'Ronda'**
  String get csvHeaderRound;

  /// Cabecera CSV: notas
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get csvHeaderNotes;

  /// Etiqueta de torneo al que se ha sido invitado, no propio
  ///
  /// In es, this message translates to:
  /// **'Invitado'**
  String get invitedLabel;

  /// Resumen de un torneo con numero de partidas
  ///
  /// In es, this message translates to:
  /// **'Resumen · {count} partidas'**
  String summaryWithMatchCount(Object count);

  /// Etiqueta de estadistica: win rate
  ///
  /// In es, this message translates to:
  /// **'Win rate'**
  String get winRateLabel;

  /// Etiqueta de estadistica: victorias
  ///
  /// In es, this message translates to:
  /// **'Victorias'**
  String get winsLabel;

  /// Etiqueta de estadistica: derrotas
  ///
  /// In es, this message translates to:
  /// **'Derrotas'**
  String get lossesLabel;

  /// Etiqueta de estadistica: empates
  ///
  /// In es, this message translates to:
  /// **'Empates'**
  String get tiesLabel;

  /// Titulo de la seccion de resumen por fase
  ///
  /// In es, this message translates to:
  /// **'Por fase'**
  String get byPhaseLabel;

  /// Fallback cuando una partida no tiene fase asignada
  ///
  /// In es, this message translates to:
  /// **'Sin fase'**
  String get noPhaseLabel;

  /// Resumen V-D-E y win rate de una fase
  ///
  /// In es, this message translates to:
  /// **'{wins}V - {losses}D - {ties}E · {winRate}%'**
  String phaseResultSummary(
    Object wins,
    Object losses,
    Object ties,
    Object winRate,
  );

  /// Estado vacio de partidas de un torneo
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay partidas registradas en este torneo'**
  String get noMatchesRegisteredInTournament;

  /// Estado de torneo: finalizado
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get tournamentStatusFinished;

  /// Estado de torneo: en curso
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get tournamentStatusInProgress;

  /// Accion para anadir la posicion final de un torneo
  ///
  /// In es, this message translates to:
  /// **'Añadir posición final'**
  String get addFinalStandingAction;

  /// Accion para editar la posicion final de un torneo
  ///
  /// In es, this message translates to:
  /// **'Editar posición final'**
  String get editFinalStandingAction;

  /// Error al filtrar datos
  ///
  /// In es, this message translates to:
  /// **'Error al filtrar: {error}'**
  String filterError(Object error);

  /// Error al abrir el detalle de un mazo
  ///
  /// In es, this message translates to:
  /// **'Error al abrir el mazo: {error}'**
  String openDeckError(Object error);

  /// Opcion de ordenacion de ranking: win rate
  ///
  /// In es, this message translates to:
  /// **'Win rate'**
  String get sortByOption;

  /// Opcion de ordenacion de ranking: partidas
  ///
  /// In es, this message translates to:
  /// **'Partidas'**
  String get sortByMatches;

  /// Etiqueta del selector de orden del ranking
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get sortByLabelField;

  /// Etiqueta del contador de partidas minimas del ranking
  ///
  /// In es, this message translates to:
  /// **'Mín. partidas'**
  String get minMatchesLabel;

  /// Estado vacio de estadisticas globales
  ///
  /// In es, this message translates to:
  /// **'Registra partidas para ver tus estadísticas globales'**
  String get noStatsYet;

  /// Pestana de ranking de mazos propios
  ///
  /// In es, this message translates to:
  /// **'Mis mazos'**
  String get myDecksTabLabel;

  /// Pestana de historial contra rivales
  ///
  /// In es, this message translates to:
  /// **'Rivales'**
  String get rivalsTabLabel;

  /// Total de partidas registradas
  ///
  /// In es, this message translates to:
  /// **'{count} partidas totales'**
  String totalMatchesCount(Object count);

  /// Etiqueta de estadistica: premios cogidos
  ///
  /// In es, this message translates to:
  /// **'Premios cogidos'**
  String get prizesTakenLabel;

  /// Etiqueta de estadistica: premios cedidos
  ///
  /// In es, this message translates to:
  /// **'Premios cedidos'**
  String get prizesGivenLabel;

  /// Titulo del grafico de evolucion de win rate
  ///
  /// In es, this message translates to:
  /// **'Evolución del win-rate general'**
  String get winrateEvolutionTitle;

  /// Estado vacio del ranking de mazos por minimo de partidas
  ///
  /// In es, this message translates to:
  /// **'Ningún mazo alcanza aún el mínimo de partidas'**
  String get noDeckReachesMinMatches;

  /// Resumen de partidas y record V-D-E
  ///
  /// In es, this message translates to:
  /// **'{count} partidas · {wins}V-{losses}D-{ties}E'**
  String matchesCountSummary(
    Object count,
    Object wins,
    Object losses,
    Object ties,
  );

  /// Explicacion de la pestana de rivales
  ///
  /// In es, this message translates to:
  /// **'Cruzando todos tus mazos, sin importar con cuál jugaste'**
  String get crossAllDecksHint;

  /// Placeholder del buscador de rivales
  ///
  /// In es, this message translates to:
  /// **'Buscar rival por nombre'**
  String get searchRivalHint;

  /// Estado vacio del historial de rivales
  ///
  /// In es, this message translates to:
  /// **'Registra partidas para ver tu historial contra cada rival'**
  String get noRivalHistoryYet;

  /// Estado vacio de busqueda de rivales sin resultados
  ///
  /// In es, this message translates to:
  /// **'Ningún rival coincide con \"{query}\"'**
  String noRivalMatchesSearch(Object query);

  /// Fallback generico cuando falta un nombre
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get unknownLabel;

  /// Accion para marcar un torneo como en curso
  ///
  /// In es, this message translates to:
  /// **'Marcar como en curso'**
  String get markAsInProgress;

  /// Accion para marcar un torneo como finalizado
  ///
  /// In es, this message translates to:
  /// **'Marcar como finalizado'**
  String get markAsFinished;

  /// Accion y titulo del dialogo para eliminar un torneo
  ///
  /// In es, this message translates to:
  /// **'Eliminar torneo'**
  String get deleteTournamentAction;

  /// Error generico al actualizar algo
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar: {error}'**
  String updateError(Object error);

  /// Confirmacion de borrado de un torneo
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"? Las partidas ya registradas no se borran, quedan sueltas fuera del torneo.'**
  String deleteTournamentConfirm(Object name);

  /// Error al eliminar un torneo
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar \"{name}\": {error}'**
  String tournamentDeleteError(Object name, Object error);

  /// Confirmacion tras eliminar un torneo
  ///
  /// In es, this message translates to:
  /// **'Torneo \"{name}\" eliminado'**
  String tournamentDeletedSnackbar(Object name);

  /// Opcion de ordenacion de torneos: posicion
  ///
  /// In es, this message translates to:
  /// **'Posición'**
  String get sortByPosition;

  /// Opcion de ordenacion de torneos: porcentaje de ranking
  ///
  /// In es, this message translates to:
  /// **'% Ranking'**
  String get sortByRankingPercentage;

  /// Opcion de ordenacion de torneos: fecha
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get sortByDate;

  /// Estado vacio de la lista de torneos
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes torneos'**
  String get noTournamentsYet;

  /// Subtitulo del estado vacio de la lista de torneos
  ///
  /// In es, this message translates to:
  /// **'Registra tu primer torneo para hacer seguimiento de tus partidas por fase'**
  String get noTournamentsYetSubtitle;

  /// Error al cargar la lista de torneos
  ///
  /// In es, this message translates to:
  /// **'Error al cargar torneos: {error}'**
  String tournamentLoadError(Object error);

  /// Formato de eliminatoria: partido unico
  ///
  /// In es, this message translates to:
  /// **'Partido único'**
  String get eliminationFormatSingleMatch;

  /// Formato de eliminatoria: ida y vuelta
  ///
  /// In es, this message translates to:
  /// **'Ida y vuelta'**
  String get eliminationFormatTwoLegs;

  /// Error al cargar mazos en el formulario de torneo
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus mazos: {error}'**
  String decksLoadError(Object error);

  /// Validacion: no hay mazos para crear un torneo tracked
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos un mazo creado para registrar un torneo'**
  String get tournamentDeckRequired;

  /// Etiqueta del campo de mazo del torneo
  ///
  /// In es, this message translates to:
  /// **'Mazo'**
  String get deckFieldLabel;

  /// Etiqueta del campo de estructura del torneo, solo lectura
  ///
  /// In es, this message translates to:
  /// **'Estructura'**
  String get structureFieldLabel;

  /// Aviso al crear torneo tracked sin mazos
  ///
  /// In es, this message translates to:
  /// **'No tienes mazos creados todavía. Crea uno primero para poder asociarlo al torneo.'**
  String get noDecksYetForTournament;

  /// Validacion: mazo no seleccionado
  ///
  /// In es, this message translates to:
  /// **'Selecciona un mazo'**
  String get deckSelectRequired;

  /// Aviso de mazo opcional en modo hosted
  ///
  /// In es, this message translates to:
  /// **'Si tú también participas, podrás vincular tu mazo más adelante desde la gestión de jugadores.'**
  String get hostedModeDeckHint;

  /// Etiqueta del selector de estructura al crear un torneo
  ///
  /// In es, this message translates to:
  /// **'Estructura del torneo'**
  String get tournamentStructureFieldLabel;

  /// Etiqueta del selector de formato de eliminatoria
  ///
  /// In es, this message translates to:
  /// **'Formato de eliminatoria'**
  String get eliminationFormatFieldLabel;

  /// Opcion de jugar el partido por el 3er y 4º puesto
  ///
  /// In es, this message translates to:
  /// **'Disputar 3er y 4º puesto'**
  String get thirdPlacePlayoffLabel;

  /// Opcion de liga a ida y vuelta
  ///
  /// In es, this message translates to:
  /// **'Ida y vuelta'**
  String get doubleRoundLabel;

  /// Explicacion de la opcion de liga a ida y vuelta
  ///
  /// In es, this message translates to:
  /// **'Cada enfrentamiento se juega dos veces'**
  String get doubleRoundSubtitle;

  /// Modo de torneo: seguimiento propio (tracked)
  ///
  /// In es, this message translates to:
  /// **'Seguimiento propio'**
  String get trackedModeLabel;

  /// Modo de torneo: alojado (hosted)
  ///
  /// In es, this message translates to:
  /// **'Alojar torneo'**
  String get hostedModeLabel;

  /// Titulo de la pantalla al editar un torneo
  ///
  /// In es, this message translates to:
  /// **'Editar torneo'**
  String get editTournamentTitle;

  /// Titulo de la pantalla al crear un torneo
  ///
  /// In es, this message translates to:
  /// **'Nuevo torneo'**
  String get newTournamentTitle;

  /// Etiqueta de la seccion de eleccion de modo del torneo
  ///
  /// In es, this message translates to:
  /// **'Modo'**
  String get modeFieldLabel;

  /// Etiqueta del campo de nombre del torneo
  ///
  /// In es, this message translates to:
  /// **'Nombre del torneo'**
  String get tournamentNameLabel;

  /// Validacion: nombre de torneo vacio
  ///
  /// In es, this message translates to:
  /// **'Introduce un nombre'**
  String get tournamentNameRequired;

  /// Etiqueta del campo de fecha
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get dateFieldLabel;

  /// Etiqueta del campo de localizacion opcional
  ///
  /// In es, this message translates to:
  /// **'Localización (opcional)'**
  String get locationFieldLabel;

  /// Boton para crear un torneo
  ///
  /// In es, this message translates to:
  /// **'Crear torneo'**
  String get createTournamentButton;

  /// Confirmacion tras copiar texto al portapapeles
  ///
  /// In es, this message translates to:
  /// **'Copiado al portapapeles'**
  String get copiedToClipboard;

  /// Titulo de la pantalla de exportar torneo
  ///
  /// In es, this message translates to:
  /// **'Exportar torneo'**
  String get exportTournamentTitle;

  /// Instrucciones de la pantalla de exportar torneo
  ///
  /// In es, this message translates to:
  /// **'Copia este texto y envíaselo a quien vaya a importar el torneo.'**
  String get exportTournamentInstructions;

  /// Boton para copiar al portapapeles
  ///
  /// In es, this message translates to:
  /// **'Copiar al portapapeles'**
  String get copyToClipboardAction;

  /// Error de formato al analizar un JSON de importacion de torneo
  ///
  /// In es, this message translates to:
  /// **'El JSON no tiene la forma esperada (faltan tournament/players/matches)'**
  String get invalidJsonFormat;

  /// Error al analizar un JSON invalido
  ///
  /// In es, this message translates to:
  /// **'JSON inválido: {error}'**
  String invalidJsonError(Object error);

  /// Validacion: falta elegir mazo real al importar torneo
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu mazo real para poder vincular tu inscripción'**
  String get selectRealDeckRequired;

  /// Titulo de la pantalla de importar torneo
  ///
  /// In es, this message translates to:
  /// **'Importar torneo'**
  String get importTournamentTitle;

  /// Instrucciones de la pantalla de importar torneo
  ///
  /// In es, this message translates to:
  /// **'Pega aquí el JSON que te haya pasado quien exportó el torneo.'**
  String get pasteImportJsonInstructions;

  /// Etiqueta del campo de pegar JSON del torneo
  ///
  /// In es, this message translates to:
  /// **'JSON del torneo'**
  String get tournamentJsonLabel;

  /// Boton para analizar el JSON pegado
  ///
  /// In es, this message translates to:
  /// **'Analizar'**
  String get analyzeAction;

  /// Resumen del torneo analizado con numero de jugadores
  ///
  /// In es, this message translates to:
  /// **'\"{name}\" — {count} jugadores'**
  String tournamentWithPlayersCount(Object name, Object count);

  /// Etiqueta del selector de quien es el usuario en el torneo importado
  ///
  /// In es, this message translates to:
  /// **'¿Quién eres tú en este torneo?'**
  String get whoAreYouInTournament;

  /// Opcion de no vincularse a ningun jugador al importar
  ///
  /// In es, this message translates to:
  /// **'Ninguno (solo espectador)'**
  String get spectatorOnlyOption;

  /// Etiqueta del selector de mazo real al importar torneo
  ///
  /// In es, this message translates to:
  /// **'Tu mazo real'**
  String get yourRealDeckLabel;

  /// Boton para importar el torneo analizado
  ///
  /// In es, this message translates to:
  /// **'Importar torneo'**
  String get importTournamentButton;

  /// Error al cargar los mazos propios
  ///
  /// In es, this message translates to:
  /// **'Error al cargar tus mazos: {error}'**
  String loadDecksError(Object error);

  /// Validacion: sin mazos propios para aceptar invitacion
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos un mazo propio para unirte a un torneo'**
  String get needAtLeastOneDeckToJoin;

  /// Titulo del selector de mazo al aceptar una invitacion
  ///
  /// In es, this message translates to:
  /// **'¿Con qué mazo te unes?'**
  String get whichDeckToJoinWith;

  /// Error al aceptar una invitacion
  ///
  /// In es, this message translates to:
  /// **'Error al aceptar: {error}'**
  String acceptError(Object error);

  /// Error al rechazar una invitacion
  ///
  /// In es, this message translates to:
  /// **'Error al rechazar: {error}'**
  String rejectError(Object error);

  /// Titulo de la pantalla de invitaciones a torneos
  ///
  /// In es, this message translates to:
  /// **'Invitaciones a torneos'**
  String get tournamentInvitesTitle;

  /// Estado vacio de invitaciones a torneos
  ///
  /// In es, this message translates to:
  /// **'No tienes invitaciones pendientes'**
  String get noPendingInvites;

  /// Nombre por defecto de un torneo sin nombre
  ///
  /// In es, this message translates to:
  /// **'Torneo'**
  String get tournamentFallbackName;

  /// Etiqueta de rol de un jugador en un torneo
  ///
  /// In es, this message translates to:
  /// **'Rol: {role}'**
  String roleWithValue(Object role);

  /// Rol de torneo: administrador
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// Rol de torneo: invitado
  ///
  /// In es, this message translates to:
  /// **'Invitado'**
  String get roleGuest;

  /// Titulo del dialogo para anadir un jugador
  ///
  /// In es, this message translates to:
  /// **'Añadir jugador'**
  String get addPlayerTitle;

  /// Titulo del dialogo para editar un jugador
  ///
  /// In es, this message translates to:
  /// **'Editar jugador'**
  String get editPlayerTitle;

  /// Etiqueta generica del campo de nombre
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nameFieldLabel;

  /// Etiqueta del campo de arquetipo de mazo opcional
  ///
  /// In es, this message translates to:
  /// **'Mazo / arquetipo (opcional)'**
  String get deckArchetypeOptionalLabel;

  /// Aviso de icono ya guardado para un arquetipo
  ///
  /// In es, this message translates to:
  /// **'Icono guardado para este mazo'**
  String get savedIconForDeck;

  /// Opcion para vincular un jugador al usuario actual
  ///
  /// In es, this message translates to:
  /// **'Soy yo'**
  String get thisIsMeLabel;

  /// Explicacion de la opcion Soy yo
  ///
  /// In es, this message translates to:
  /// **'Vincula esta inscripción a un mazo real tuyo'**
  String get linkRealDeckSubtitle;

  /// Validacion: mazo no elegido
  ///
  /// In es, this message translates to:
  /// **'Elige un mazo'**
  String get chooseADeckError;

  /// Boton generico para guardar
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get saveAction;

  /// Error al cargar la lista de amigos
  ///
  /// In es, this message translates to:
  /// **'Error al cargar amigos: {error}'**
  String loadFriendsError(Object error);

  /// Estado vacio de amigos al intentar invitar a un torneo
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes amigos añadidos'**
  String get noFriendsAddedYet;

  /// Titulo del selector de amigo para invitar a un torneo
  ///
  /// In es, this message translates to:
  /// **'Elegir amigo'**
  String get chooseFriendTitle;

  /// Titulo del dialogo de invitar a un amigo
  ///
  /// In es, this message translates to:
  /// **'Invitar a {username}'**
  String inviteFriendTitle(Object username);

  /// Etiqueta del selector de rol al invitar a un torneo
  ///
  /// In es, this message translates to:
  /// **'Rol dentro del torneo:'**
  String get roleInTournamentLabel;

  /// Explicacion de los roles de invitacion a un torneo
  ///
  /// In es, this message translates to:
  /// **'Invitado: solo tú registras sus resultados. Admin: podrá registrar sus propias partidas en el futuro.'**
  String get roleGuestExplanation;

  /// Boton para enviar una invitacion
  ///
  /// In es, this message translates to:
  /// **'Enviar invitación'**
  String get sendInviteAction;

  /// Confirmacion de invitacion enviada
  ///
  /// In es, this message translates to:
  /// **'Invitación enviada a {username}'**
  String inviteSentTo(Object username);

  /// Error generico al guardar algo
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String saveError(Object error);

  /// Accion para reactivar un jugador dado de baja
  ///
  /// In es, this message translates to:
  /// **'Reactivar (deshacer baja)'**
  String get reactivatePlayerAction;

  /// Accion para dar de baja a un jugador
  ///
  /// In es, this message translates to:
  /// **'Dar de baja (drop)'**
  String get dropPlayerAction;

  /// Accion y titulo del dialogo para eliminar un jugador
  ///
  /// In es, this message translates to:
  /// **'Eliminar jugador'**
  String get deletePlayerAction;

  /// Confirmacion de borrado de un jugador
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a \"{name}\"? Las partidas ya registradas contra este jugador no se borran.'**
  String deletePlayerConfirm(Object name);

  /// Titulo de la pantalla de gestion de jugadores
  ///
  /// In es, this message translates to:
  /// **'Jugadores'**
  String get playersScreenTitle;

  /// Tooltip del icono de exportar torneo
  ///
  /// In es, this message translates to:
  /// **'Exportar torneo'**
  String get exportTournamentTooltip;

  /// Tooltip del icono de clasificacion
  ///
  /// In es, this message translates to:
  /// **'Clasificación'**
  String get standingsTooltip;

  /// Tooltip del icono de rondas y emparejamientos
  ///
  /// In es, this message translates to:
  /// **'Rondas y emparejamientos'**
  String get roundsAndPairingsTooltip;

  /// Estado vacio de jugadores de un torneo
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay jugadores inscritos'**
  String get noPlayersEnrolledYet;

  /// Etiqueta del boton flotante de invitar a un amigo
  ///
  /// In es, this message translates to:
  /// **'Amigo'**
  String get friendFabLabel;

  /// Etiqueta del boton flotante de anadir jugador
  ///
  /// In es, this message translates to:
  /// **'Jugador'**
  String get playerFabLabel;

  /// Titulo del dialogo para anadir un snapshot de clasificacion
  ///
  /// In es, this message translates to:
  /// **'Añadir posición'**
  String get addStandingTitle;

  /// Etiqueta del campo de puntos
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get pointsLabel;

  /// Etiqueta del campo de posicion en la tabla
  ///
  /// In es, this message translates to:
  /// **'Posición en la tabla'**
  String get positionInTableLabel;

  /// Titulo del dialogo de editar posicion final
  ///
  /// In es, this message translates to:
  /// **'Posición final'**
  String get finalStandingTitle;

  /// Etiqueta del campo de puesto obtenido
  ///
  /// In es, this message translates to:
  /// **'Puesto obtenido'**
  String get positionObtainedLabel;

  /// Etiqueta del campo de numero total de participantes
  ///
  /// In es, this message translates to:
  /// **'Nº total de participantes'**
  String get totalParticipantsLabel;

  /// Titulo de la seccion de clasificacion manual
  ///
  /// In es, this message translates to:
  /// **'Clasificación'**
  String get standingsSectionTitle;

  /// Estado vacio de la seccion de clasificacion manual
  ///
  /// In es, this message translates to:
  /// **'Registra tu posición y puntos cuando quieras hacer seguimiento'**
  String get trackStandingHint;

  /// Posicion ordinal en un snapshot de clasificacion
  ///
  /// In es, this message translates to:
  /// **'{position}º puesto'**
  String positionOrdinal(Object position);

  /// Puntos abreviados en un snapshot de clasificacion
  ///
  /// In es, this message translates to:
  /// **'{points} pts'**
  String pointsAbbreviation(Object points);

  /// Titulo generico de la pantalla de torneo mientras carga/hay error
  ///
  /// In es, this message translates to:
  /// **'Torneo'**
  String get tournamentFallbackTitle;

  /// Accion del menu de opciones de un torneo, compartir resumen
  ///
  /// In es, this message translates to:
  /// **'Compartir resumen'**
  String get shareSummaryAction;

  /// Titulo de la seccion de partidas de un torneo
  ///
  /// In es, this message translates to:
  /// **'Partidas'**
  String get matchesSectionTitle;

  /// Aviso al tocar una partida bye, no necesita registrarse
  ///
  /// In es, this message translates to:
  /// **'Bye: resuelto automáticamente, no requiere partida'**
  String get byeNoMatchNeeded;

  /// Titulo del dialogo de asignar grupos
  ///
  /// In es, this message translates to:
  /// **'Asignar grupos'**
  String get assignGroupsTitle;

  /// Etiqueta del campo de jugadores por grupo
  ///
  /// In es, this message translates to:
  /// **'Jugadores por grupo'**
  String get playersPerGroupLabel;

  /// Titulo del dialogo de cerrar fase suiza
  ///
  /// In es, this message translates to:
  /// **'Cerrar fase suiza'**
  String get closeSwissPhaseTitle;

  /// Etiqueta del campo de numero de clasificados top cut
  ///
  /// In es, this message translates to:
  /// **'Nº de clasificados (top cut)'**
  String get topCutQualifiersLabel;

  /// Titulo del dialogo de cerrar fase de grupos
  ///
  /// In es, this message translates to:
  /// **'Cerrar fase de grupos'**
  String get closeGroupPhaseTitle;

  /// Etiqueta del campo de clasificados por grupo
  ///
  /// In es, this message translates to:
  /// **'Clasificados por grupo'**
  String get qualifiersPerGroupLabel;

  /// Titulo de la pantalla de rondas mientras carga o hay error
  ///
  /// In es, this message translates to:
  /// **'Rondas'**
  String get roundsScreenTitle;

  /// Titulo de la pantalla de rondas y emparejamientos
  ///
  /// In es, this message translates to:
  /// **'Rondas y emparejamientos'**
  String get roundsAndPairingsTitle;

  /// Tooltip del icono de ver bracket a pantalla completa
  ///
  /// In es, this message translates to:
  /// **'Ver bracket a pantalla completa'**
  String get viewFullscreenBracketTooltip;

  /// Estado vacio de rondas de un torneo
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay rondas generadas. Usa el botón de arriba para empezar.'**
  String get noRoundsYetHint;

  /// Accion para generar una nueva ronda suiza
  ///
  /// In es, this message translates to:
  /// **'Generar ronda swiss'**
  String get generateSwissRoundAction;

  /// Accion para generar el calendario de una liga
  ///
  /// In es, this message translates to:
  /// **'Generar calendario de liga'**
  String get generateLeagueScheduleAction;

  /// Accion para generar el bracket de eliminatoria
  ///
  /// In es, this message translates to:
  /// **'Generar bracket'**
  String get generateBracketAction;

  /// Accion para cerrar la fase suiza
  ///
  /// In es, this message translates to:
  /// **'Cerrar fase suiza'**
  String get closeSwissPhaseAction;

  /// Accion para asignar grupos
  ///
  /// In es, this message translates to:
  /// **'Asignar grupos'**
  String get assignGroupsAction;

  /// Accion para generar el calendario de grupos
  ///
  /// In es, this message translates to:
  /// **'Generar calendario de grupos'**
  String get generateGroupScheduleAction;

  /// Accion para cerrar la fase de grupos
  ///
  /// In es, this message translates to:
  /// **'Cerrar fase de grupos'**
  String get closeGroupPhaseAction;

  /// Accion para avanzar el bracket a la siguiente fase
  ///
  /// In es, this message translates to:
  /// **'Avanzar a la siguiente fase'**
  String get advanceToNextPhaseAction;

  /// Accion para finalizar un torneo
  ///
  /// In es, this message translates to:
  /// **'Finalizar torneo'**
  String get finishTournamentAction;

  /// Titulo de un emparejamiento, con BYE si aplica
  ///
  /// In es, this message translates to:
  /// **'{player1} vs {player2}'**
  String matchVsWithBye(Object player1, Object player2);

  /// Etiqueta de una partida bye
  ///
  /// In es, this message translates to:
  /// **'BYE'**
  String get byeLabel;

  /// Marcador de jugador desconocido
  ///
  /// In es, this message translates to:
  /// **'?'**
  String get unknownPlayerPlaceholder;

  /// Estado de un emparejamiento sin resultado aun
  ///
  /// In es, this message translates to:
  /// **'Sin resultado'**
  String get noResultYet;

  /// Nombre de grupo por defecto cuando un jugador no tiene grupo asignado
  ///
  /// In es, this message translates to:
  /// **'Sin grupo'**
  String get noGroupLabel;

  /// Titulo de la pantalla de clasificacion
  ///
  /// In es, this message translates to:
  /// **'Clasificación'**
  String get standingsScreenTitle;

  /// Puntos con sufijo pts
  ///
  /// In es, this message translates to:
  /// **'{points} pts'**
  String pointsSuffix(Object points);

  /// Diferencial de premios y OMW% en la clasificacion
  ///
  /// In es, this message translates to:
  /// **'Dif. {differential} · OMW {omw}%'**
  String prizeDifferentialAndOmw(Object differential, Object omw);

  /// Titulo de la pantalla de bracket a pantalla completa
  ///
  /// In es, this message translates to:
  /// **'Bracket'**
  String get bracketTitle;

  /// Estado vacio del bracket de eliminatoria
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay bracket generado'**
  String get noBracketYet;

  /// Etiqueta del partido por el 3er y 4º puesto
  ///
  /// In es, this message translates to:
  /// **'3er y 4º puesto'**
  String get thirdFourthPlaceLabel;

  /// Tooltip del boton de recentrar la vista del bracket
  ///
  /// In es, this message translates to:
  /// **'Centrar vista'**
  String get recenterViewTooltip;

  /// Partido de ida y vuelta: ida
  ///
  /// In es, this message translates to:
  /// **'Ida'**
  String get legFirstLeg;

  /// Partido de ida y vuelta: vuelta
  ///
  /// In es, this message translates to:
  /// **'Vuelta'**
  String get legSecondLeg;

  /// Partido de ida y vuelta: muerte subita (desempate)
  ///
  /// In es, this message translates to:
  /// **'Muerte súbita'**
  String get legSuddenDeath;

  /// Resultado agregado con muerte subita completada
  ///
  /// In es, this message translates to:
  /// **'Agregado + muerte súbita'**
  String get aggregateWithSuddenDeath;

  /// Resultado agregado empatado, pendiente de muerte subita
  ///
  /// In es, this message translates to:
  /// **'Empate agregado ({p1Total}-{p2Total}) · falta muerte súbita'**
  String aggregateTieAwaitingSuddenDeath(Object p1Total, Object p2Total);

  /// Resultado agregado de ida y vuelta
  ///
  /// In es, this message translates to:
  /// **'{p1Total} - {p2Total} (agregado)'**
  String aggregateResult(Object p1Total, Object p2Total);

  /// Resultado de la ida, vuelta pendiente
  ///
  /// In es, this message translates to:
  /// **'Ida: {p1}-{p2} · Vuelta pendiente'**
  String firstLegResultAwaitingSecond(Object p1, Object p2);

  /// Etiqueta del contador de premios de un jugador
  ///
  /// In es, this message translates to:
  /// **'Premios de {player}'**
  String prizesOfPlayer(Object player);

  /// Nombre por defecto del jugador 1
  ///
  /// In es, this message translates to:
  /// **'jugador 1'**
  String get player1Fallback;

  /// Nombre por defecto del jugador 2
  ///
  /// In es, this message translates to:
  /// **'jugador 2'**
  String get player2Fallback;

  /// Etiqueta del switch de marcar empate
  ///
  /// In es, this message translates to:
  /// **'Empate'**
  String get drawLabel;

  /// Opcion de radio button: gana este jugador
  ///
  /// In es, this message translates to:
  /// **'Gana {player}'**
  String playerWinsLabel(Object player);

  /// Aclaracion de que el ganador no se deduce de los premios
  ///
  /// In es, this message translates to:
  /// **'El ganador puede no coincidir con los premios (rendición, mazo agotado, tiempo...)'**
  String get winnerMayNotMatchPrizes;

  /// Accion y titulo del dialogo de editar un rival
  ///
  /// In es, this message translates to:
  /// **'Editar rival'**
  String get editRivalAction;

  /// Accion para eliminar el historial de un rival
  ///
  /// In es, this message translates to:
  /// **'Eliminar historial de este rival'**
  String get deleteRivalHistoryAction;

  /// Error generico al editar algo
  ///
  /// In es, this message translates to:
  /// **'Error al editar: {error}'**
  String editError(Object error);

  /// Titulo del dialogo de confirmacion de borrado de rival
  ///
  /// In es, this message translates to:
  /// **'Eliminar mazo rival'**
  String get deleteRivalDeckTitle;

  /// Confirmacion de borrado de rival con numero de partidas
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar \"{name}\"? Se eliminarán también sus {count} partidas registradas y dejarán de contar en tus estadísticas. Esta acción no se puede deshacer.'**
  String deleteRivalConfirmWithCount(Object name, Object count);

  /// Confirmacion de borrado de rival sin numero de partidas
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar \"{name}\"? Se eliminarán también sus partidas registradas y dejarán de contar en tus estadísticas. Esta acción no se puede deshacer.'**
  String deleteRivalConfirmSimple(Object name);

  /// Error al no encontrar sprite para una especie
  ///
  /// In es, this message translates to:
  /// **'No se encontró sprite para \"{species}\"'**
  String spriteNotFound(Object species);

  /// Etiqueta de la seccion de icono opcional de un mazo/rival
  ///
  /// In es, this message translates to:
  /// **'Icono (opcional)'**
  String get iconOptionalLabel;

  /// Placeholder del buscador de especies de Pokemon
  ///
  /// In es, this message translates to:
  /// **'Buscar Pokémon'**
  String get searchPokemonHint;

  /// Placeholder para anadir un segundo icono opcional
  ///
  /// In es, this message translates to:
  /// **'Añadir segundo icono (opcional)'**
  String get addSecondIconOptional;

  /// Titulo del dialogo de nueva version disponible
  ///
  /// In es, this message translates to:
  /// **'Nueva versión disponible'**
  String get newVersionAvailableTitle;

  /// Descripcion de la version actual y la nueva disponible
  ///
  /// In es, this message translates to:
  /// **'Tienes la versión {current} instalada. Ya está disponible la {latest}.'**
  String versionUpdatePrompt(Object current, Object latest);

  /// Error al fallar la descarga del instalador de actualizacion
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar el instalador. Puedes descargarlo a mano desde GitHub.'**
  String get downloadFailedHint;

  /// Boton para posponer la actualizacion
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get notNowAction;

  /// Boton para abrir la release en GitHub
  ///
  /// In es, this message translates to:
  /// **'Ver en GitHub'**
  String get viewOnGithubAction;

  /// Boton para ejecutar el instalador ya descargado
  ///
  /// In es, this message translates to:
  /// **'Ejecutar instalador'**
  String get runInstallerAction;

  /// Boton para iniciar la descarga de la actualizacion
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get updateAction;

  /// Serie del grafico de win rate: acumulado
  ///
  /// In es, this message translates to:
  /// **'Acumulado'**
  String get seriesCumulative;

  /// Serie del grafico de win rate: ultimas 5 partidas
  ///
  /// In es, this message translates to:
  /// **'Últimas 5'**
  String get seriesLast5;

  /// Serie del grafico de win rate: ultimas 10 partidas
  ///
  /// In es, this message translates to:
  /// **'Últimas 10'**
  String get seriesLast10;

  /// Opcion del filtro de rango: todas las partidas
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get allMatchesOption;

  /// Opcion del filtro de rango: ultimas N partidas
  ///
  /// In es, this message translates to:
  /// **'Últimas {n}'**
  String lastNMatchesOption(Object n);

  /// Aviso de racha negativa con un mazo
  ///
  /// In es, this message translates to:
  /// **'🥶 {count} derrotas seguidas con este mazo'**
  String losingStreakWarning(Object count);

  /// Boton para deshacer un borrado pendiente
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undoAction;

  /// Etiqueta del campo de email en el registro
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Validacion: email vacio en el registro
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email'**
  String get emailRequired;

  /// Validacion: formato de email invalido
  ///
  /// In es, this message translates to:
  /// **'El email no es válido'**
  String get emailInvalid;

  /// Aviso en el perfil cuando el email aun no esta verificado
  ///
  /// In es, this message translates to:
  /// **'Verifica tu email para asegurar tu cuenta'**
  String get emailVerificationBannerText;

  /// Boton para reenviar el correo de verificacion
  ///
  /// In es, this message translates to:
  /// **'Reenviar correo'**
  String get resendVerificationAction;

  /// Confirmacion tras reenviar el correo de verificacion
  ///
  /// In es, this message translates to:
  /// **'Correo de verificación reenviado'**
  String get verificationEmailSent;

  /// Error al reenviar el correo de verificacion
  ///
  /// In es, this message translates to:
  /// **'Error al reenviar el correo: {error}'**
  String resendVerificationError(Object error);

  /// Boton para ir a la pantalla de estadisticas completas desde el perfil
  ///
  /// In es, this message translates to:
  /// **'Ver estadísticas completas'**
  String get viewFullStatsAction;

  /// Numero de amigos mostrado en la card de amigos del perfil
  ///
  /// In es, this message translates to:
  /// **'{count} amigos'**
  String friendsCountLabel(Object count);

  /// Version de la app mostrada al final del perfil
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String appVersionLabel(Object version);

  /// Accion del menu de ajustes para reportar un bug en GitHub
  ///
  /// In es, this message translates to:
  /// **'Reportar un bug'**
  String get reportBugAction;

  /// Accion del menu de ajustes para cambiar la contraseña
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePasswordSettingsAction;

  /// Titulo del dialogo de cambiar contraseña
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePasswordTitle;

  /// Etiqueta del campo de contraseña actual
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get currentPasswordLabel;

  /// Validacion: contraseña actual vacia
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña actual'**
  String get currentPasswordRequired;

  /// Etiqueta del campo de nueva contraseña
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get newPasswordLabel;

  /// Confirmacion tras cambiar la contraseña
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada'**
  String get passwordChangedSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}