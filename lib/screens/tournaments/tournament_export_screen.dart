import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/tournament_service.dart';

/// Exporta un torneo hosted a JSON (issue #76, ver TORNEOS_HOSTED_GDD.md
/// seccion 7). Se muestra el JSON con opcion de copiarlo al portapapeles,
/// para que el usuario se lo pase a otro (por chat, email, etc.) y lo
/// importe desde su propia cuenta.
class TournamentExportScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentExportScreen({super.key, required this.tournamentId});

  @override
  State<TournamentExportScreen> createState() => _TournamentExportScreenState();
}

class _TournamentExportScreenState extends State<TournamentExportScreen> {
  final _tournamentService = TournamentService();

  String? _jsonText;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExport();
  }

  Future<void> _loadExport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _tournamentService.exportTournament(widget.tournamentId);
      const encoder = JsonEncoder.withIndent('  ');
      if (!mounted) return;
      setState(() {
        _jsonText = encoder.convert(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_jsonText == null) return;
    await Clipboard.setData(ClipboardData(text: _jsonText!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar torneo')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage', textAlign: TextAlign.center),
                        const SizedBox(height: AppSizes.spacingM),
                        FilledButton(onPressed: _loadExport, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.spacingM),
                      child: Text(
                        'Copia este texto y envíaselo a quien vaya a importar el torneo.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
                        child: SelectableText(
                          _jsonText ?? '',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: AppSizes.textS),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.spacingM),
                      child: FilledButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar al portapapeles'),
                      ),
                    ),
                  ],
                ),
    );
  }
}