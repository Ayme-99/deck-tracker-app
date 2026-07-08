import 'dart:async';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Spinner de carga que, tras [slowThreshold] sin resolverse, muestra un mensaje
/// avisando de que el backend puede estar "despertando" (cold start de Render).
class SlowLoadingIndicator extends StatefulWidget {
  final Duration slowThreshold;

  const SlowLoadingIndicator({
    super.key,
    this.slowThreshold = const Duration(seconds: 5),
  });

  @override
  State<SlowLoadingIndicator> createState() => _SlowLoadingIndicatorState();
}

class _SlowLoadingIndicatorState extends State<SlowLoadingIndicator> {
  bool _isSlow = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.slowThreshold, () {
      if (mounted) setState(() => _isSlow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (_isSlow) ...[
            const SizedBox(height: AppSizes.spacingM),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingL),
              child: Text(
                'Despertando el servidor, puede tardar unos segundos...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textS),
              ),
            ),
          ],
        ],
      ),
    );
  }
}