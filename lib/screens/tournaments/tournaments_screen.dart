import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: AppSizes.iconHuge, color: AppColors.muted),
            SizedBox(height: AppSizes.spacingM),
            Text(
              'Próximamente',
              style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSizes.spacingS),
            Text(
              'El seguimiento de torneos estará disponible en una futura actualización.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}