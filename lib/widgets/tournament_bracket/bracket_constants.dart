/// Constantes de layout propias del bracket (no van a AppSizes: son medidas
/// especificas de este arbol de eliminatoria, no reutilizadas en otras
/// pantallas -- ver nota de la Fase 5 en el refactor, issue #115).
class BracketConstants {
  // FIX (issue #83): rowHeight es fijo, y cardHeight se calcula sumando
  // ambas filas + el divisor + margen, en vez de derivar rowHeight
  // dividiendo cardHeight entre 2 (eso no dejaba hueco para el Divider).
  static const double dividerHeight = 1;
  static const double rowHeight = 32;
  static const double cardHeight = rowHeight * 2 + dividerHeight + 4;
  static const double cardWidth = 210;
  static const double leafGap = 14;
  static const double colGap = 48;
  static const double labelHeight = 24;
}
