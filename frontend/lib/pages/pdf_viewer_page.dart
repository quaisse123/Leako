// 📄 Page de visualisation du rapport PDF
// Télécharge le PDF et l'ouvre via OpenFileX → lecteur PDF système

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../api/rapport_api.dart' as api;

class PdfViewerPage extends StatefulWidget {
  final int projetId;
  final String periode;
  final String titre;
  final Set<String>? metrics;

  const PdfViewerPage({
    super.key,
    required this.projetId,
    required this.periode,
    this.titre = 'Rapport PDF',
    this.metrics,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  static const Color _ocpGreen = Color(0xFF00875A);
  static const Color _ocpBlack = Color(0xFF111111);

  Uint8List? _pdfBytes;
  bool _loading = true;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerPdf();
  }

  Future<void> _chargerPdf() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await api.getPdfBytes(
        projetId: widget.projetId,
        periode: widget.periode,
        metrics: widget.metrics,
      );
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _loading = false;
      });
      _ouvrirAvecLecteur();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement : $e';
        _loading = false;
      });
    }
  }

  Future<void> _ouvrirAvecLecteur() async {
    if (_pdfBytes == null || _opening) return;
    setState(() => _opening = true);

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/rapport_ocp_${widget.projetId}.pdf');
      await file.writeAsBytes(_pdfBytes!);

      if (!mounted) return;

      final result = await OpenFilex.open(file.path);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        setState(() {
          _error = 'Impossible d\'ouvrir le PDF : ${result.message}';
          _opening = false;
        });
        return;
      }

      // Succès → on ferme la page
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur : $e';
        _opening = false;
      });
    }
  }

  Future<void> _sauvegarderPdf() async {
    if (_pdfBytes == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/rapport_ocp_${widget.projetId}.pdf');
      await file.writeAsBytes(_pdfBytes!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ PDF sauvegardé dans Documents'),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Erreur de sauvegarde : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ocpBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.titre,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: _ocpBlack,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_pdfBytes != null)
            IconButton(
              tooltip: 'Sauvegarder le PDF',
              icon: const Icon(Icons.download_rounded, color: _ocpGreen),
              onPressed: _sauvegarderPdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading || _opening) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _opening ? 'Ouverture du PDF…' : 'Génération du rapport…',
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _chargerPdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(backgroundColor: _ocpGreen),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    // PDF chargé mais pas encore ouvert (si l'auto-ouverture a échoué)
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_rounded, size: 64, color: _ocpGreen),
          const SizedBox(height: 16),
          const Text(
            'PDF prêt',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _ouvrirAvecLecteur,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir le PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: _ocpGreen,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _sauvegarderPdf,
            icon: const Icon(Icons.download),
            label: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }
}
