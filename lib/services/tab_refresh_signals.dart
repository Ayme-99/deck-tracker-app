import 'package:flutter/foundation.dart';

/// Señales para forzar la recarga de una pestaña del shell principal desde
/// fuera de ella (ej. tras crear un mazo/torneo desde el FAB de HomeScreen).
///
/// Bug encontrado tras la migracion a go_router (#238): goBranch(index,
/// initialLocation: true) no remonta el widget raiz de la rama si ya esta
/// en su ubicacion inicial -- que es el caso normal, ya que los FAB de
/// "Añadir mazo"/"Crear torneo" solo se muestran estando ya en esa pestaña.
/// Sin remonte, initState() (y por tanto la carga de red) nunca se repite,
/// asi que un mazo/torneo recien creado solo aparecia tras cerrar/abrir
/// sesion (arranque limpio de HomeScreen).
final deckListRefreshSignal = ValueNotifier<int>(0);
final tournamentsListRefreshSignal = ValueNotifier<int>(0);
