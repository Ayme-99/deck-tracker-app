package com.example.deck_tracker_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de acceso rapido (issue #10): un icono en la pantalla de inicio del
 * movil que abre la app directamente en el selector de mazo para registrar
 * una partida, saltandose la navegacion normal (Mazos > detalle > Registrar
 * partida).
 *
 * No muestra datos dinamicos (no usa el SharedPreferences de widgetData):
 * su unico trabajo es lanzar MainActivity con una URI propia
 * ("decktracker://registrar-partida") que el lado Flutter detecta via
 * HomeWidget.initiallyLaunchedFromHomeWidget() (app cerrada) o
 * HomeWidget.widgetClicked (app ya en segundo plano) -- ver
 * lib/screens/auth/splash_screen.dart y lib/main.dart.
 */
class QuickRegisterWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("decktracker://registrar-partida")
            )
            val views = RemoteViews(context.packageName, R.layout.quick_register_widget).apply {
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
