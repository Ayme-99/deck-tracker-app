package com.example.deck_tracker_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de acceso rapido (issue #10): un icono en la pantalla de inicio del
 * movil que abre la app directamente en el selector de mazo para registrar
 * una partida, saltandose la navegacion normal (Mazos > detalle > Registrar
 * partida).
 *
 * Nivel 2 (issue #132): ademas muestra datos reales leidos del SharedPreferences
 * de widgetData -- el mazo mas jugado y su racha actual, calculados y
 * guardados desde el lado Flutter via QuickWidgetSyncService
 * (lib/services/quick_widget_sync_service.dart). Cada dato tiene su propia
 * linea (en vez de una sola concatenada) porque en dispositivo real una
 * linea unica se cortaba con nombres de mazo largos ("Mega-Lucario ex · 🥶
 * 1D..."). Mientras no haya datos sincronizados (widget recien anadido, sin
 * conexion la primera vez...) se muestra un texto de respaldo
 * ("Registrar partida") en su lugar, para no dejar el widget vacio.
 */
class QuickRegisterWidgetProvider : HomeWidgetProvider() {
    // Mismos colores que AppColors.success/error/muted (lib/styles/colors.dart),
    // para que la racha del widget siga el mismo lenguaje visual que
    // DeckOverviewCard (issue #127).
    private fun streakColor(streakType: String?): Int = when (streakType) {
        "win" -> Color.parseColor("#FF22C55E")
        "loss" -> Color.parseColor("#FFB00020")
        else -> Color.parseColor("#FF9CA3AF")
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val deckName = widgetData.getString("widget_deck_name", null)?.trim().orEmpty()
        val streakLabel = widgetData.getString("widget_streak_label", null)?.trim().orEmpty()
        val streakType = widgetData.getString("widget_streak_type", null)
        val hasData = deckName.isNotBlank()

        appWidgetIds.forEach { widgetId ->
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("decktracker://registrar-partida")
            )
            val views = RemoteViews(context.packageName, R.layout.quick_register_widget).apply {
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setViewVisibility(R.id.widget_placeholder_line, if (hasData) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.widget_deck_name_line, if (hasData) View.VISIBLE else View.GONE)
                if (hasData) setTextViewText(R.id.widget_deck_name_line, deckName)

                if (hasData && streakLabel.isNotBlank()) {
                    setTextViewText(R.id.widget_streak_line, streakLabel)
                    setTextColor(R.id.widget_streak_line, streakColor(streakType))
                    setViewVisibility(R.id.widget_streak_line, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_streak_line, View.GONE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
