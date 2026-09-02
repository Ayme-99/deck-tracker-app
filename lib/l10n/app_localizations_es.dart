// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Deck Tracker';

  @override
  String get usernameLabel => 'Usuario';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get loginUsernameRequired => 'Introduce tu usuario';

  @override
  String get loginPasswordRequired => 'Introduce tu contraseña';

  @override
  String get loginSubmitButton => 'Entrar';

  @override
  String get loginServerWakingUp =>
      'Despertando el servidor, puede tardar unos segundos...';

  @override
  String get loginRegisterLink => '¿No tienes cuenta? Regístrate';

  @override
  String get loginSessionExpired =>
      'Tu sesión ha caducado, inicia sesión de nuevo';

  @override
  String get registerScreenTitle => 'Crear cuenta';

  @override
  String get registerUsernameRequired => 'Introduce un usuario';

  @override
  String get registerPasswordMinLength => 'Mínimo 6 caracteres';

  @override
  String get registerConfirmPasswordLabel => 'Repite la contraseña';

  @override
  String get registerConfirmPasswordRequired => 'Repite la contraseña';

  @override
  String get registerPasswordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get registerSubmitButton => 'Crear cuenta';

  @override
  String get backupScreenTitle => 'Copia de seguridad';

  @override
  String backupExportedSnackbar(
    Object decks,
    Object tournaments,
    Object matches,
  ) {
    return 'Backup exportado: $decks mazos, $tournaments torneos, $matches partidas';
  }

  @override
  String get backupOpenAction => 'Abrir';

  @override
  String backupExportError(Object error) {
    return 'Error al exportar: $error';
  }

  @override
  String get backupInvalidFile =>
      'El archivo no es un backup válido (JSON corrupto)';

  @override
  String get backupRestoreDialogTitle => 'Restaurar backup';

  @override
  String backupRestoreDialogContent(
    Object decks,
    Object matches,
    Object tournaments,
  ) {
    return 'Vas a añadir $decks mazos, $matches partidas y $tournaments torneos a tu cuenta actual como entidades nuevas -- no sobrescribe ni borra nada de lo que ya tengas. Si restauras el mismo backup dos veces, tendrás los mazos duplicados.';
  }

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get backupRestoreAction => 'Restaurar';

  @override
  String backupRestoredSnackbar(
    Object decks,
    Object tournaments,
    Object matches,
  ) {
    return 'Restaurado: $decks mazos, $tournaments torneos, $matches partidas';
  }

  @override
  String backupRestoreError(Object error) {
    return 'Error al restaurar: $error';
  }

  @override
  String get backupDescription =>
      'Exporta todos tus mazos, partidas y torneos seguidos (no alojados) a un único archivo, para migrar de cuenta o tener una copia de seguridad manual.';

  @override
  String get backupExportButton => 'Exportar backup';

  @override
  String get backupRestoreButton => 'Restaurar desde archivo';

  @override
  String deckDeleteError(Object name, Object error) {
    return 'Error al eliminar \"$name\": $error';
  }

  @override
  String deckDeletedSnackbar(Object name) {
    return 'Mazo \"$name\" eliminado';
  }

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByMostWins => 'Más victorias';

  @override
  String get sortByWinRate => 'Win rate';

  @override
  String get sortByRecentActivity => 'Actividad reciente';

  @override
  String get editDeckAction => 'Editar mazo';

  @override
  String get duplicateDeckAction => 'Duplicar mazo';

  @override
  String get deleteDeckAction => 'Eliminar mazo';

  @override
  String deleteDeckConfirmWithMatches(Object name, Object count) {
    return '¿Seguro que quieres eliminar \"$name\"? Se eliminarán también sus $count partidas registradas y dejarán de contar en tus estadísticas.';
  }

  @override
  String deleteDeckConfirmSimple(Object name) {
    return '¿Seguro que quieres eliminar \"$name\"?';
  }

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get deckSearchHint => 'Buscar mazo por nombre';

  @override
  String sortByLabel(Object sortLabel) {
    return 'Ordenar: $sortLabel';
  }

  @override
  String get offlineShowingSavedData =>
      'Sin conexión · mostrando datos guardados';

  @override
  String get noDecksYetTitle => 'Todavía no tienes mazos';

  @override
  String get noDecksYetSubtitle =>
      'Crea tu primer mazo para empezar a registrar partidas';

  @override
  String deckLoadError(Object error) {
    return 'Error al cargar mazos: $error';
  }

  @override
  String get createDeckAction => 'Crear mazo';

  @override
  String noDeckMatchesSearch(Object query) {
    return 'Ningún mazo coincide con \"$query\"';
  }

  @override
  String get importFromTcgLiveTitle => 'Importar desde Pokémon TCG Live';

  @override
  String get importReplacesCurrentList =>
      'Esto sustituirá la lista de cartas actual.';

  @override
  String get importPasteHint => 'Pega aquí la lista exportada desde TCG Live';

  @override
  String get importAction => 'Importar';

  @override
  String get importNoCardsRecognized =>
      'No se ha reconocido ninguna carta en el texto pegado';

  @override
  String get deckFormEditTitle => 'Editar Mazo';

  @override
  String get deckFormDuplicateTitle => 'Duplicar Mazo';

  @override
  String get deckFormNewTitle => 'Nuevo Mazo';

  @override
  String get deckNameLabel => 'Nombre del mazo';

  @override
  String get deckNameRequired => 'Introduce un nombre';

  @override
  String get cardsSectionTitle => 'Cartas';

  @override
  String get addCardAction => 'Añadir carta';

  @override
  String get noCardsAddedYet => 'No hay cartas añadidas';

  @override
  String get canAddCardsLater => 'Puedes añadir cartas ahora o más tarde';

  @override
  String get cardNameLabel => 'Nombre';

  @override
  String get requiredFieldError => 'Requerido';

  @override
  String get cardQuantityLabel => 'Cant.';

  @override
  String get cardQuantityInvalid => 'Nº entero > 0';

  @override
  String get cardCategoryLabel => 'Tipo';

  @override
  String get cardCategoryPokemon => 'Pokémon';

  @override
  String get cardCategoryTrainer => 'Entrenador';

  @override
  String get cardCategoryEnergy => 'Energía';

  @override
  String get saveChangesAction => 'Guardar cambios';

  @override
  String matchDeleteError(Object error) {
    return 'Error al eliminar la partida: $error';
  }

  @override
  String matchDeletedSnackbar(Object opponent) {
    return 'Partida contra \"$opponent\" eliminada';
  }

  @override
  String get editMatchAction => 'Editar partida';

  @override
  String get shareMatchAction => 'Compartir partida';

  @override
  String get deleteMatchAction => 'Eliminar partida';

  @override
  String deleteMatchConfirm(Object opponent) {
    return '¿Eliminar la partida contra \"$opponent\"?';
  }

  @override
  String deleteDeckDetailConfirm(Object name) {
    return '¿Seguro que quieres eliminar \"$name\"?';
  }

  @override
  String get matchHistoryExported => 'Historial exportado a Descargas';

  @override
  String get openAction => 'Abrir';

  @override
  String exportError(Object error) {
    return 'Error al exportar: $error';
  }

  @override
  String get exportMatchesToCsvAction => 'Exportar partidas a CSV';

  @override
  String genericErrorLabel(Object error) {
    return 'Error: $error';
  }

  @override
  String get retryAction => 'Reintentar';

  @override
  String get registerMatchAction => 'Partida';

  @override
  String get matchupsSectionTitle => 'Matchups';

  @override
  String get viewAsListTooltip => 'Ver como lista';

  @override
  String get viewAsHeatmapTooltip => 'Ver como mapa de calor';

  @override
  String get noMatchesRegisteredYet => 'Todavía no hay partidas registradas';

  @override
  String matchupTooltip(
    Object opponent,
    Object wins,
    Object losses,
    Object ties,
  ) {
    return '$opponent\n${wins}V - ${losses}D - ${ties}E';
  }

  @override
  String matchResultSummary(Object wins, Object losses, Object ties) {
    return '${wins}V - ${losses}D - ${ties}E';
  }

  @override
  String get recentMatchesSectionTitle => 'Partidas recientes';

  @override
  String get matchResultWin => 'Victoria';

  @override
  String get matchResultLoss => 'Derrota';

  @override
  String get matchResultTie => 'Empate';

  @override
  String matchVsOpponent(Object opponent) {
    return 'vs $opponent';
  }

  @override
  String matchResultAndPrizes(
    Object result,
    Object userPrizes,
    Object opponentPrizes,
  ) {
    return '$result · $userPrizes-$opponentPrizes';
  }

  @override
  String get showMoreAction => 'Mostrar más';

  @override
  String get hideAction => 'Ocultar';

  @override
  String searchError(Object error) {
    return 'Error al buscar: $error';
  }

  @override
  String genericErrorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String get removeFriendshipTitle => 'Eliminar amistad';

  @override
  String removeFriendshipConfirm(Object username) {
    return '¿Seguro que quieres eliminar a \"$username\" de tus amigos?';
  }

  @override
  String removeFriendshipError(Object error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get noFriendsYet => 'Todavía no tienes amigos añadidos';

  @override
  String get removeFriendshipTooltip => 'Eliminar amistad';

  @override
  String get noPendingRequests => 'No hay solicitudes pendientes';

  @override
  String get incomingRequestsTitle => 'Entrantes';

  @override
  String get acceptAction => 'Aceptar';

  @override
  String get rejectAction => 'Rechazar';

  @override
  String get outgoingRequestsTitle => 'Salientes';

  @override
  String get pendingStatus => 'Pendiente';

  @override
  String get searchByUsernameHint => 'Buscar por username';

  @override
  String get searchByUsernamePrompt =>
      'Busca a alguien por su nombre de usuario';

  @override
  String get noResultsFound => 'Sin resultados';

  @override
  String get requestSentStatus => 'Enviada';

  @override
  String get addAction => 'Añadir';

  @override
  String get friendsScreenTitle => 'Amigos';

  @override
  String get friendsTabLabel => 'Amigos';

  @override
  String get requestsTabLabel => 'Solicitudes';

  @override
  String get searchTabLabel => 'Buscar';

  @override
  String get homeTitleDecks => 'Mis Mazos';

  @override
  String get homeTitleStats => 'Estadísticas';

  @override
  String get homeTitleTournaments => 'Torneos';

  @override
  String get searchTooltip => 'Buscar';

  @override
  String get importTournamentTooltip => 'Importar torneo';

  @override
  String get profileTooltip => 'Perfil';

  @override
  String get addDeckAction => 'Añadir mazo';

  @override
  String get createTournamentAction => 'Crear torneo';

  @override
  String get navDecksLabel => 'Mazos';

  @override
  String get navStatsLabel => 'Stats';

  @override
  String get navTournamentsLabel => 'Torneos';

  @override
  String get endReasonNormal => 'Normal (premios completos)';

  @override
  String get endReasonConcession => 'Rendición';

  @override
  String get endReasonNoPokemon => 'Sin Pokémon en banca';

  @override
  String get endReasonTime => 'Tiempo agotado';

  @override
  String get endReasonDeckOut => 'Mazo agotado';

  @override
  String newMatchTitle(Object deckName) {
    return 'Nueva partida · $deckName';
  }

  @override
  String roundLabel(Object round) {
    return 'Ronda $round';
  }

  @override
  String get opponentDeckLabel => 'Mazo rival';

  @override
  String get opponentDeckHelper => 'Empieza a escribir para ver sugerencias';

  @override
  String get opponentDeckRequired => 'Introduce el mazo rival';

  @override
  String get yourPrizesLabel => 'Tus premios';

  @override
  String get opponentPrizesLabel => 'Premios rival';

  @override
  String get manualResultWarning =>
      'Selecciona quién ganó realmente: no se calcula a partir de los premios, y este resultado es el que se guarda en tus estadísticas';

  @override
  String get manualResultWin => 'Gané';

  @override
  String get manualResultTie => 'Empate';

  @override
  String get manualResultLoss => 'Perdí';

  @override
  String get resultVictoryEmoji => '🏆 Victoria';

  @override
  String get resultDefeatEmoji => '❌ Derrota';

  @override
  String get resultTieEmoji => '🤝 Empate';

  @override
  String get matchEndReasonLabel => 'Motivo de fin de partida';

  @override
  String get notesOptionalLabel => 'Notas (opcional)';

  @override
  String get registerMatchButton => 'Registrar partida';

  @override
  String get registerMatchReadyForNext =>
      'Partida registrada. Lista para la siguiente.';

  @override
  String get registerAndAddAnother => 'Registrar y añadir otra';

  @override
  String get editMatchTitle => 'Editar partida';

  @override
  String get quickRegisterTitle => 'Registrar partida';

  @override
  String get createDeckToRegisterMatches =>
      'Crea un mazo desde la app para poder registrar partidas';

  @override
  String get accentColorBlue => 'Azul';

  @override
  String get accentColorPurple => 'Morado';

  @override
  String get accentColorGreen => 'Verde';

  @override
  String get accentColorRed => 'Rojo';

  @override
  String get accentColorTeal => 'Turquesa';

  @override
  String get accentColorOrange => 'Naranja';

  @override
  String get accentColorPickerTitle => 'Color de acento';

  @override
  String get themePickerTitle => 'Tema';

  @override
  String get themeModeSystem => 'Automático (sistema)';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get backupSettingsAction => 'Copia de seguridad';

  @override
  String get accentColorSettingsAction => 'Color de acento';

  @override
  String get themeSettingsAction => 'Tema';

  @override
  String get logoutAction => 'Cerrar sesión';

  @override
  String get myProfileTitle => 'Mi perfil';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get defaultUsername => 'Usuario';

  @override
  String get friendsMenuAction => 'Amigos';

  @override
  String get tournamentInvitesMenuAction => 'Invitaciones a torneos';

  @override
  String get globalSearchHint => 'Buscar mazos, torneos, rivales...';

  @override
  String get globalSearchPrompt =>
      'Escribe para buscar entre tus mazos, torneos y rivales';

  @override
  String globalSearchNoResults(Object query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get sectionDecks => 'Mazos';

  @override
  String get sectionTournaments => 'Torneos';

  @override
  String get sectionRivals => 'Rivales';

  @override
  String get matchPhaseGroupStage => 'Fase de grupos';

  @override
  String get matchPhaseSwiss => 'Suiza';

  @override
  String get matchPhaseRoundOf16 => 'Octavos';

  @override
  String get matchPhaseQuarterfinal => 'Cuartos';

  @override
  String get matchPhaseSemifinal => 'Semifinal';

  @override
  String get matchPhaseFinal => 'Final';

  @override
  String get matchPhaseLeagueRound => 'Jornada';

  @override
  String get tournamentStructureSwiss => 'Rondas suizas';

  @override
  String get tournamentStructureSwissElimination => 'Suizas + eliminatoria';

  @override
  String get tournamentStructureGroupsElimination =>
      'Fase de grupos + eliminatoria';

  @override
  String get tournamentStructureElimination => 'Eliminatoria directa';

  @override
  String get tournamentStructureLeague => 'Liga';

  @override
  String get matchPhaseRoundOf64 => 'Fase de 64';

  @override
  String get matchPhaseRoundOf32 => 'Dieciseisavos';

  @override
  String get selectMatchPhaseTitle => '¿En qué fase se juega?';

  @override
  String get matchPhaseLabel => 'Fase';

  @override
  String get continueAction => 'Continuar';

  @override
  String get csvHeaderDate => 'Fecha';

  @override
  String get csvHeaderOpponent => 'Rival';

  @override
  String get csvHeaderResult => 'Resultado';

  @override
  String get csvHeaderMyPrizes => 'Mis premios';

  @override
  String get csvHeaderOpponentPrizes => 'Premios rival';

  @override
  String get csvHeaderPhase => 'Fase';

  @override
  String get csvHeaderRound => 'Ronda';

  @override
  String get csvHeaderNotes => 'Notas';

  @override
  String get invitedLabel => 'Invitado';

  @override
  String summaryWithMatchCount(Object count) {
    return 'Resumen · $count partidas';
  }

  @override
  String get winRateLabel => 'Win rate';

  @override
  String get winsLabel => 'Victorias';

  @override
  String get lossesLabel => 'Derrotas';

  @override
  String get tiesLabel => 'Empates';

  @override
  String get byPhaseLabel => 'Por fase';

  @override
  String get noPhaseLabel => 'Sin fase';

  @override
  String phaseResultSummary(
    Object wins,
    Object losses,
    Object ties,
    Object winRate,
  ) {
    return '${wins}V - ${losses}D - ${ties}E · $winRate%';
  }

  @override
  String get noMatchesRegisteredInTournament =>
      'Todavía no hay partidas registradas en este torneo';

  @override
  String get tournamentStatusFinished => 'Finalizado';

  @override
  String get tournamentStatusInProgress => 'En curso';

  @override
  String get addFinalStandingAction => 'Añadir posición final';

  @override
  String get editFinalStandingAction => 'Editar posición final';

  @override
  String filterError(Object error) {
    return 'Error al filtrar: $error';
  }

  @override
  String openDeckError(Object error) {
    return 'Error al abrir el mazo: $error';
  }

  @override
  String get sortByOption => 'Win rate';

  @override
  String get sortByMatches => 'Partidas';

  @override
  String get sortByLabelField => 'Ordenar por';

  @override
  String get minMatchesLabel => 'Mín. partidas';

  @override
  String get noStatsYet =>
      'Registra partidas para ver tus estadísticas globales';

  @override
  String get myDecksTabLabel => 'Mis mazos';

  @override
  String get rivalsTabLabel => 'Rivales';

  @override
  String totalMatchesCount(Object count) {
    return '$count partidas totales';
  }

  @override
  String get prizesTakenLabel => 'Premios cogidos';

  @override
  String get prizesGivenLabel => 'Premios cedidos';

  @override
  String get winrateEvolutionTitle => 'Evolución del win-rate general';

  @override
  String get noDeckReachesMinMatches =>
      'Ningún mazo alcanza aún el mínimo de partidas';

  @override
  String matchesCountSummary(
    Object count,
    Object wins,
    Object losses,
    Object ties,
  ) {
    return '$count partidas · ${wins}V-${losses}D-${ties}E';
  }

  @override
  String get crossAllDecksHint =>
      'Cruzando todos tus mazos, sin importar con cuál jugaste';

  @override
  String get searchRivalHint => 'Buscar rival por nombre';

  @override
  String get noRivalHistoryYet =>
      'Registra partidas para ver tu historial contra cada rival';

  @override
  String noRivalMatchesSearch(Object query) {
    return 'Ningún rival coincide con \"$query\"';
  }

  @override
  String get unknownLabel => 'Desconocido';

  @override
  String get markAsInProgress => 'Marcar como en curso';

  @override
  String get markAsFinished => 'Marcar como finalizado';

  @override
  String get deleteTournamentAction => 'Eliminar torneo';

  @override
  String updateError(Object error) {
    return 'Error al actualizar: $error';
  }

  @override
  String deleteTournamentConfirm(Object name) {
    return '¿Eliminar \"$name\"? Las partidas ya registradas no se borran, quedan sueltas fuera del torneo.';
  }

  @override
  String tournamentDeleteError(Object name, Object error) {
    return 'Error al eliminar \"$name\": $error';
  }

  @override
  String tournamentDeletedSnackbar(Object name) {
    return 'Torneo \"$name\" eliminado';
  }

  @override
  String get sortByPosition => 'Posición';

  @override
  String get sortByRankingPercentage => '% Ranking';

  @override
  String get sortByDate => 'Fecha';

  @override
  String get noTournamentsYet => 'Todavía no tienes torneos';

  @override
  String get noTournamentsYetSubtitle =>
      'Registra tu primer torneo para hacer seguimiento de tus partidas por fase';

  @override
  String tournamentLoadError(Object error) {
    return 'Error al cargar torneos: $error';
  }

  @override
  String get eliminationFormatSingleMatch => 'Partido único';

  @override
  String get eliminationFormatTwoLegs => 'Ida y vuelta';

  @override
  String decksLoadError(Object error) {
    return 'No se pudieron cargar tus mazos: $error';
  }

  @override
  String get tournamentDeckRequired =>
      'Necesitas al menos un mazo creado para registrar un torneo';

  @override
  String get deckFieldLabel => 'Mazo';

  @override
  String get structureFieldLabel => 'Estructura';

  @override
  String get noDecksYetForTournament =>
      'No tienes mazos creados todavía. Crea uno primero para poder asociarlo al torneo.';

  @override
  String get deckSelectRequired => 'Selecciona un mazo';

  @override
  String get hostedModeDeckHint =>
      'Si tú también participas, podrás vincular tu mazo más adelante desde la gestión de jugadores.';

  @override
  String get tournamentStructureFieldLabel => 'Estructura del torneo';

  @override
  String get eliminationFormatFieldLabel => 'Formato de eliminatoria';

  @override
  String get thirdPlacePlayoffLabel => 'Disputar 3er y 4º puesto';

  @override
  String get doubleRoundLabel => 'Ida y vuelta';

  @override
  String get doubleRoundSubtitle => 'Cada enfrentamiento se juega dos veces';

  @override
  String get trackedModeLabel => 'Seguimiento propio';

  @override
  String get hostedModeLabel => 'Alojar torneo';

  @override
  String get editTournamentTitle => 'Editar torneo';

  @override
  String get newTournamentTitle => 'Nuevo torneo';

  @override
  String get modeFieldLabel => 'Modo';

  @override
  String get tournamentNameLabel => 'Nombre del torneo';

  @override
  String get tournamentNameRequired => 'Introduce un nombre';

  @override
  String get dateFieldLabel => 'Fecha';

  @override
  String get locationFieldLabel => 'Localización (opcional)';

  @override
  String get createTournamentButton => 'Crear torneo';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get exportTournamentTitle => 'Exportar torneo';

  @override
  String get exportTournamentInstructions =>
      'Copia este texto y envíaselo a quien vaya a importar el torneo.';

  @override
  String get copyToClipboardAction => 'Copiar al portapapeles';

  @override
  String get invalidJsonFormat =>
      'El JSON no tiene la forma esperada (faltan tournament/players/matches)';

  @override
  String invalidJsonError(Object error) {
    return 'JSON inválido: $error';
  }

  @override
  String get selectRealDeckRequired =>
      'Selecciona tu mazo real para poder vincular tu inscripción';

  @override
  String get importTournamentTitle => 'Importar torneo';

  @override
  String get pasteImportJsonInstructions =>
      'Pega aquí el JSON que te haya pasado quien exportó el torneo.';

  @override
  String get tournamentJsonLabel => 'JSON del torneo';

  @override
  String get analyzeAction => 'Analizar';

  @override
  String tournamentWithPlayersCount(Object name, Object count) {
    return '\"$name\" — $count jugadores';
  }

  @override
  String get whoAreYouInTournament => '¿Quién eres tú en este torneo?';

  @override
  String get spectatorOnlyOption => 'Ninguno (solo espectador)';

  @override
  String get yourRealDeckLabel => 'Tu mazo real';

  @override
  String get importTournamentButton => 'Importar torneo';

  @override
  String loadDecksError(Object error) {
    return 'Error al cargar tus mazos: $error';
  }

  @override
  String get needAtLeastOneDeckToJoin =>
      'Necesitas al menos un mazo propio para unirte a un torneo';

  @override
  String get whichDeckToJoinWith => '¿Con qué mazo te unes?';

  @override
  String acceptError(Object error) {
    return 'Error al aceptar: $error';
  }

  @override
  String rejectError(Object error) {
    return 'Error al rechazar: $error';
  }

  @override
  String get tournamentInvitesTitle => 'Invitaciones a torneos';

  @override
  String get noPendingInvites => 'No tienes invitaciones pendientes';

  @override
  String get tournamentFallbackName => 'Torneo';

  @override
  String roleWithValue(Object role) {
    return 'Rol: $role';
  }

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleGuest => 'Invitado';

  @override
  String get addPlayerTitle => 'Añadir jugador';

  @override
  String get editPlayerTitle => 'Editar jugador';

  @override
  String get nameFieldLabel => 'Nombre';

  @override
  String get deckArchetypeOptionalLabel => 'Mazo / arquetipo (opcional)';

  @override
  String get savedIconForDeck => 'Icono guardado para este mazo';

  @override
  String get thisIsMeLabel => 'Soy yo';

  @override
  String get linkRealDeckSubtitle =>
      'Vincula esta inscripción a un mazo real tuyo';

  @override
  String get chooseADeckError => 'Elige un mazo';

  @override
  String get saveAction => 'Guardar';

  @override
  String loadFriendsError(Object error) {
    return 'Error al cargar amigos: $error';
  }

  @override
  String get noFriendsAddedYet => 'Todavía no tienes amigos añadidos';

  @override
  String get chooseFriendTitle => 'Elegir amigo';

  @override
  String inviteFriendTitle(Object username) {
    return 'Invitar a $username';
  }

  @override
  String get roleInTournamentLabel => 'Rol dentro del torneo:';

  @override
  String get roleGuestExplanation =>
      'Invitado: solo tú registras sus resultados. Admin: podrá registrar sus propias partidas en el futuro.';

  @override
  String get sendInviteAction => 'Enviar invitación';

  @override
  String inviteSentTo(Object username) {
    return 'Invitación enviada a $username';
  }

  @override
  String saveError(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get reactivatePlayerAction => 'Reactivar (deshacer baja)';

  @override
  String get dropPlayerAction => 'Dar de baja (drop)';

  @override
  String get deletePlayerAction => 'Eliminar jugador';

  @override
  String deletePlayerConfirm(Object name) {
    return '¿Eliminar a \"$name\"? Las partidas ya registradas contra este jugador no se borran.';
  }

  @override
  String get playersScreenTitle => 'Jugadores';

  @override
  String get exportTournamentTooltip => 'Exportar torneo';

  @override
  String get standingsTooltip => 'Clasificación';

  @override
  String get roundsAndPairingsTooltip => 'Rondas y emparejamientos';

  @override
  String get noPlayersEnrolledYet => 'Todavía no hay jugadores inscritos';

  @override
  String get friendFabLabel => 'Amigo';

  @override
  String get playerFabLabel => 'Jugador';

  @override
  String get addStandingTitle => 'Añadir posición';

  @override
  String get pointsLabel => 'Puntos';

  @override
  String get positionInTableLabel => 'Posición en la tabla';

  @override
  String get finalStandingTitle => 'Posición final';

  @override
  String get positionObtainedLabel => 'Puesto obtenido';

  @override
  String get totalParticipantsLabel => 'Nº total de participantes';

  @override
  String get standingsSectionTitle => 'Clasificación';

  @override
  String get trackStandingHint =>
      'Registra tu posición y puntos cuando quieras hacer seguimiento';

  @override
  String positionOrdinal(Object position) {
    return '$positionº puesto';
  }

  @override
  String pointsAbbreviation(Object points) {
    return '$points pts';
  }

  @override
  String get tournamentFallbackTitle => 'Torneo';

  @override
  String get shareSummaryAction => 'Compartir resumen';

  @override
  String get matchesSectionTitle => 'Partidas';

  @override
  String get byeNoMatchNeeded =>
      'Bye: resuelto automáticamente, no requiere partida';

  @override
  String get assignGroupsTitle => 'Asignar grupos';

  @override
  String get playersPerGroupLabel => 'Jugadores por grupo';

  @override
  String get closeSwissPhaseTitle => 'Cerrar fase suiza';

  @override
  String get topCutQualifiersLabel => 'Nº de clasificados (top cut)';

  @override
  String get closeGroupPhaseTitle => 'Cerrar fase de grupos';

  @override
  String get qualifiersPerGroupLabel => 'Clasificados por grupo';

  @override
  String get roundsScreenTitle => 'Rondas';

  @override
  String get roundsAndPairingsTitle => 'Rondas y emparejamientos';

  @override
  String get viewFullscreenBracketTooltip => 'Ver bracket a pantalla completa';

  @override
  String get noRoundsYetHint =>
      'Todavía no hay rondas generadas. Usa el botón de arriba para empezar.';

  @override
  String get generateSwissRoundAction => 'Generar ronda swiss';

  @override
  String get generateLeagueScheduleAction => 'Generar calendario de liga';

  @override
  String get generateBracketAction => 'Generar bracket';

  @override
  String get closeSwissPhaseAction => 'Cerrar fase suiza';

  @override
  String get assignGroupsAction => 'Asignar grupos';

  @override
  String get generateGroupScheduleAction => 'Generar calendario de grupos';

  @override
  String get closeGroupPhaseAction => 'Cerrar fase de grupos';

  @override
  String get advanceToNextPhaseAction => 'Avanzar a la siguiente fase';

  @override
  String get finishTournamentAction => 'Finalizar torneo';

  @override
  String matchVsWithBye(Object player1, Object player2) {
    return '$player1 vs $player2';
  }

  @override
  String get byeLabel => 'BYE';

  @override
  String get unknownPlayerPlaceholder => '?';

  @override
  String get noResultYet => 'Sin resultado';

  @override
  String get noGroupLabel => 'Sin grupo';

  @override
  String get standingsScreenTitle => 'Clasificación';

  @override
  String pointsSuffix(Object points) {
    return '$points pts';
  }

  @override
  String prizeDifferentialAndOmw(Object differential, Object omw) {
    return 'Dif. $differential · OMW $omw%';
  }

  @override
  String get bracketTitle => 'Bracket';

  @override
  String get noBracketYet => 'Todavía no hay bracket generado';

  @override
  String get thirdFourthPlaceLabel => '3er y 4º puesto';

  @override
  String get recenterViewTooltip => 'Centrar vista';

  @override
  String get legFirstLeg => 'Ida';

  @override
  String get legSecondLeg => 'Vuelta';

  @override
  String get legSuddenDeath => 'Muerte súbita';

  @override
  String get aggregateWithSuddenDeath => 'Agregado + muerte súbita';

  @override
  String aggregateTieAwaitingSuddenDeath(Object p1Total, Object p2Total) {
    return 'Empate agregado ($p1Total-$p2Total) · falta muerte súbita';
  }

  @override
  String aggregateResult(Object p1Total, Object p2Total) {
    return '$p1Total - $p2Total (agregado)';
  }

  @override
  String firstLegResultAwaitingSecond(Object p1, Object p2) {
    return 'Ida: $p1-$p2 · Vuelta pendiente';
  }

  @override
  String prizesOfPlayer(Object player) {
    return 'Premios de $player';
  }

  @override
  String get player1Fallback => 'jugador 1';

  @override
  String get player2Fallback => 'jugador 2';

  @override
  String get drawLabel => 'Empate';

  @override
  String playerWinsLabel(Object player) {
    return 'Gana $player';
  }

  @override
  String get winnerMayNotMatchPrizes =>
      'El ganador puede no coincidir con los premios (rendición, mazo agotado, tiempo...)';

  @override
  String get editRivalAction => 'Editar rival';

  @override
  String get deleteRivalHistoryAction => 'Eliminar historial de este rival';

  @override
  String editError(Object error) {
    return 'Error al editar: $error';
  }

  @override
  String get deleteRivalDeckTitle => 'Eliminar mazo rival';

  @override
  String deleteRivalConfirmWithCount(Object name, Object count) {
    return '¿Seguro que quieres eliminar \"$name\"? Se eliminarán también sus $count partidas registradas y dejarán de contar en tus estadísticas. Esta acción no se puede deshacer.';
  }

  @override
  String deleteRivalConfirmSimple(Object name) {
    return '¿Seguro que quieres eliminar \"$name\"? Se eliminarán también sus partidas registradas y dejarán de contar en tus estadísticas. Esta acción no se puede deshacer.';
  }

  @override
  String spriteNotFound(Object species) {
    return 'No se encontró sprite para \"$species\"';
  }

  @override
  String get iconOptionalLabel => 'Icono (opcional)';

  @override
  String get searchPokemonHint => 'Buscar Pokémon';

  @override
  String get addSecondIconOptional => 'Añadir segundo icono (opcional)';

  @override
  String get newVersionAvailableTitle => 'Nueva versión disponible';

  @override
  String versionUpdatePrompt(Object current, Object latest) {
    return 'Tienes la versión $current instalada. Ya está disponible la $latest.';
  }

  @override
  String get downloadFailedHint =>
      'No se pudo descargar el instalador. Puedes descargarlo a mano desde GitHub.';

  @override
  String get notNowAction => 'Ahora no';

  @override
  String get viewOnGithubAction => 'Ver en GitHub';

  @override
  String get runInstallerAction => 'Ejecutar instalador';

  @override
  String get updateAction => 'Actualizar';

  @override
  String get seriesCumulative => 'Acumulado';

  @override
  String get seriesLast5 => 'Últimas 5';

  @override
  String get seriesLast10 => 'Últimas 10';

  @override
  String get allMatchesOption => 'Todas';

  @override
  String lastNMatchesOption(Object n) {
    return 'Últimas $n';
  }

  @override
  String losingStreakWarning(Object count) {
    return '🥶 $count derrotas seguidas con este mazo';
  }

  @override
  String get undoAction => 'Deshacer';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Introduce tu email';

  @override
  String get emailInvalid => 'El email no es válido';

  @override
  String get emailVerificationBannerText =>
      'Verifica tu email para asegurar tu cuenta';

  @override
  String get resendVerificationAction => 'Reenviar correo';

  @override
  String get verificationEmailSent => 'Correo de verificación reenviado';

  @override
  String resendVerificationError(Object error) {
    return 'Error al reenviar el correo: $error';
  }

  @override
  String get viewFullStatsAction => 'Ver estadísticas completas';

  @override
  String friendsCountLabel(Object count) {
    return '$count amigos';
  }

  @override
  String appVersionLabel(Object version) {
    return 'Versión $version';
  }

  @override
  String get reportBugAction => 'Reportar un bug';

  @override
  String get changePasswordSettingsAction => 'Cambiar contraseña';

  @override
  String get changePasswordTitle => 'Cambiar contraseña';

  @override
  String get currentPasswordLabel => 'Contraseña actual';

  @override
  String get currentPasswordRequired => 'Introduce tu contraseña actual';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get passwordChangedSuccess => 'Contraseña actualizada';
}
