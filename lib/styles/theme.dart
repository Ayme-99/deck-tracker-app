import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles/colors.dart';
import 'package:deck_tracker_app/styles/sizes.dart';
import 'package:deck_tracker_app/styles/text_styles.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = isDark ? ThemeData.dark() : ThemeData.light();

  final background = isDark ? AppColors.backgroundDark : AppColors.background;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
  final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

  // Version suavizada del acento para el fondo de los botones (issue #168,
  // segunda ronda de feedback): a color plano quedaba demasiado "duro" --
  // se mezcla con blanco/negro segun el tema para que no chirríe tanto.
  final softPrimary = Color.lerp(AppColors.primary, isDark ? Colors.black : Colors.white, 0.15)!;

  return base.copyWith(
    brightness: brightness,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: background,
    colorScheme: base.colorScheme.copyWith(
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: surface,
      error: AppColors.error,
      onPrimary: isDark ? textPrimary : AppColors.surface,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: AppColors.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? surface : AppColors.primary,
      foregroundColor: isDark ? textPrimary : AppColors.surface,
      // En claro el fondo de la barra YA es el acento (los iconos van en
      // blanco para que se lean encima). En oscuro el fondo es gris fijo,
      // asi que sin esto los iconos de la barra (buscar, exportar...)
      // nunca reflejaban el acento -- issue #168, tercera ronda de feedback.
      // Se tinta solo el icono (no el titulo, que se queda neutro/legible).
      iconTheme: IconThemeData(color: isDark ? AppColors.primary : AppColors.surface),
      actionsIconTheme: IconThemeData(color: isDark ? AppColors.primary : AppColors.surface),
      elevation: 0,
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: AppTextStyles.title.copyWith(color: textPrimary),
      bodyLarge: AppTextStyles.body.copyWith(color: textPrimary),
      bodyMedium: AppTextStyles.caption.copyWith(color: textPrimary),
      labelLarge: AppTextStyles.button,
    ),
    // Icono por defecto de toda la app (issue #168, segunda ronda de
    // feedback): antes solo cambiaban con el acento los sitios que leian
    // AppColors.primary explicitamente. Los iconos con color propio (error,
    // muted...) siguen ganando, esto solo cubre los que no especifican color.
    iconTheme: IconThemeData(color: AppColors.primary),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: softPrimary,
        foregroundColor: AppColors.surface,
        textStyle: AppTextStyles.button,
      ),
    ),
    // Issue #168 (ampliacion): estos widgets usan por defecto colores de
    // Material 3 que NO derivan de colorScheme.primary (FAB va a
    // primaryContainer, NavigationBar a secondaryContainer...), asi que sin
    // estos overrides explicitos el color de acento apenas se notaba fuera
    // de los sitios que ya leian AppColors.primary directamente.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: softPrimary,
        foregroundColor: AppColors.surface,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: softPrimary,
      foregroundColor: AppColors.surface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: AppColors.primary.withValues(alpha: 0.35),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected) ? AppColors.primary : null,
          fontSize: AppSizes.textXS,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      indicatorColor: AppColors.primary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.primary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.primary.withValues(alpha: 0.5) : null,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
    ),
  );
}
