import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import 'bracket_layout.dart';

/// Dibuja los conectores entre fases del bracket, reutilizando las fuentes
/// ya resueltas en [BracketLayout.connectorSourceIndices] (issue #115) en
/// vez de repetir la busqueda por winnerId aqui.
class BracketConnectorPainter extends CustomPainter {
  final List<String> phasesWithMatches;
  final Map<String, List<double>> centers;
  final Map<String, List<List<int>>> connectorSourceIndices;
  final double cardWidth;
  final double colGap;

  BracketConnectorPainter({
    required this.phasesWithMatches,
    required this.centers,
    required this.connectorSourceIndices,
    required this.cardWidth,
    required this.colGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < phasesWithMatches.length - 1; i++) {
      final phase = phasesWithMatches[i];
      final nextPhaseName = phasesWithMatches[i + 1];
      final phaseCenters = centers[phase]!;
      final nextCenters = centers[nextPhaseName]!;
      final sourcesByNextIndex = connectorSourceIndices[nextPhaseName]!;

      final x1 = i * (cardWidth + colGap) + cardWidth;
      final xMid = x1 + colGap / 2;
      final x2 = (i + 1) * (cardWidth + colGap);

      for (int j = 0; j < sourcesByNextIndex.length; j++) {
        final sourceIndices = sourcesByNextIndex[j];
        final yParent = nextCenters[j];

        if (sourceIndices.length == 2) {
          final yChild0 = phaseCenters[sourceIndices[0]];
          final yChild1 = phaseCenters[sourceIndices[1]];
          canvas.drawLine(Offset(x1, yChild0), Offset(xMid, yChild0), paint);
          canvas.drawLine(Offset(x1, yChild1), Offset(xMid, yChild1), paint);
          canvas.drawLine(Offset(xMid, yChild0), Offset(xMid, yChild1), paint);
          canvas.drawLine(Offset(xMid, yParent), Offset(x2, yParent), paint);
        } else if (sourceIndices.length == 1) {
          final yChild = phaseCenters[sourceIndices[0]];
          canvas.drawLine(Offset(x1, yChild), Offset(xMid, yChild), paint);
          canvas.drawLine(Offset(xMid, yChild), Offset(xMid, yParent), paint);
          canvas.drawLine(Offset(xMid, yParent), Offset(x2, yParent), paint);
        }
        // 0 fuentes: ninguno de los dos jugadores de este partido proviene
        // de un ganador de la fase anterior -- no hay nada que conectar.
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectorPainter oldDelegate) => true;
}
