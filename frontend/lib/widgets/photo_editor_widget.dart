// 🎨 Éditeur photo — dessin, texte, effacer, sauvegarder
// Utilise flutter_painter_v2 pour l'édition sur image

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';
import '../api/photo_api.dart' as photo_api;

class PhotoEditorPage extends StatefulWidget {
  final String imagePath;
  final String? baseUrl;

  const PhotoEditorPage({super.key, required this.imagePath, this.baseUrl});

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  late PainterController _controller;
  ui.Image? _backgroundImage;
  bool _loading = true;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  FreeStyleMode _mode = FreeStyleMode.draw;
  bool _textMode = false;

  static const _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.black,
    Colors.white,
    Colors.yellow,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _controller = PainterController(
      settings: const PainterSettings(
        freeStyle: FreeStyleSettings(
          mode: FreeStyleMode.draw,
          color: Colors.red,
          strokeWidth: 3.0,
        ),
        text: TextSettings(
          textStyle: TextStyle(fontSize: 24, color: Colors.red),
        ),
      ),
    );
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      if (!await file.exists()) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _backgroundImage = frame.image;
          _controller.background = frame.image.backgroundDrawable;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setColor(Color color) {
    setState(() {
      _selectedColor = color;
      _textMode = false;
      _mode = FreeStyleMode.draw;
      _controller.settings = _controller.settings.copyWith(
        freeStyle: FreeStyleSettings(
          mode: FreeStyleMode.draw,
          color: color,
          strokeWidth: _strokeWidth,
        ),
        text: TextSettings(textStyle: TextStyle(fontSize: 24, color: color)),
      );
    });
  }

  void _setStrokeWidth(double width) {
    setState(() {
      _strokeWidth = width;
      _controller.settings = _controller.settings.copyWith(
        freeStyle: FreeStyleSettings(
          mode: _mode,
          color: _selectedColor,
          strokeWidth: width,
        ),
      );
    });
  }

  void _toggleDrawMode() {
    setState(() {
      _textMode = false;
      _mode = _mode == FreeStyleMode.draw
          ? FreeStyleMode.none
          : FreeStyleMode.draw;
      _controller.settings = _controller.settings.copyWith(
        freeStyle: FreeStyleSettings(
          mode: _mode,
          color: _selectedColor,
          strokeWidth: _strokeWidth,
        ),
      );
    });
  }

  void _toggleEraseMode() {
    setState(() {
      _textMode = false;
      _mode = _mode == FreeStyleMode.erase
          ? FreeStyleMode.none
          : FreeStyleMode.erase;
      _controller.settings = _controller.settings.copyWith(
        freeStyle: FreeStyleSettings(
          mode: _mode,
          color: _selectedColor,
          strokeWidth: _strokeWidth,
        ),
      );
    });
  }

  void _addTextMode() {
    setState(() {
      _textMode = !_textMode;
      _mode = FreeStyleMode.none;
      _controller.settings = _controller.settings.copyWith(
        freeStyle: const FreeStyleSettings(mode: FreeStyleMode.none),
      );
    });
    if (_textMode) {
      _controller.addText();
    }
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tout effacer ?'),
        content: const Text('Tous les dessins et textes seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _controller.clearDrawables();
              Navigator.pop(ctx);
            },
            child: const Text('Effacer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _undo() {
    _controller.undo();
  }

  void _redo() {
    _controller.redo();
  }

  Future<Uint8List?> _renderImage() async {
    if (_backgroundImage == null) return null;

    final size = Size(
      _backgroundImage!.width.toDouble(),
      _backgroundImage!.height.toDouble(),
    );

    final img = await _controller.renderImage(size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _save() async {
    final bytes = await _renderImage();
    if (bytes == null) return;

    // Écraser le fichier original
    await File(widget.imagePath).writeAsBytes(bytes);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Éditer la photo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            tooltip: 'Annuler',
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.white),
            tooltip: 'Rétablir',
            onPressed: _redo,
          ),
          TextButton(
            onPressed: _save,
            child: const Text(
              'Sauvegarder',
              style: TextStyle(
                color: Color(0xFF00875A),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _backgroundImage == null
          ? const Center(
              child: Text(
                'Impossible de charger l\'image',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              children: [
                // ── Zone d'édition ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterPainter(
                        controller: _controller,
                        onSelectedObjectDrawableChanged: (obj) {
                          if (obj != null) {
                            setState(() => _textMode = false);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // ── Barre d'outils ──
                _buildToolbar(),
              ],
            ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Ligne 1 : Outils ──
          Row(
            children: [
              _toolButton(
                icon: Icons.brush_rounded,
                label: 'Dessin',
                active: _mode == FreeStyleMode.draw,
                onTap: _toggleDrawMode,
              ),
              const SizedBox(width: 4),
              _toolButton(
                icon: Icons.auto_fix_high_rounded,
                label: 'Texte',
                active: _textMode,
                onTap: _addTextMode,
              ),
              const SizedBox(width: 4),
              _toolButton(
                icon: Icons.auto_fix_off_rounded,
                label: 'Gomme',
                active: _mode == FreeStyleMode.erase,
                onTap: _toggleEraseMode,
              ),
              const Spacer(),
              _toolButton(
                icon: Icons.delete_outline_rounded,
                label: 'Tout effacer',
                active: false,
                color: Colors.red.shade300,
                onTap: _clearAll,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Ligne 2 : Épaisseur ──
          Row(
            children: [
              Icon(
                Icons.line_weight_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 12,
                  divisions: 11,
                  activeColor: _selectedColor,
                  inactiveColor: Colors.grey.shade700,
                  onChanged: _setStrokeWidth,
                ),
              ),
              Text(
                '${_strokeWidth.toInt()}px',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Ligne 3 : Couleurs ──
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, i) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final c = _colors[index];
                final selected = c == _selectedColor;
                return GestureDetector(
                  onTap: () => _setColor(c),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    Color? color,
  }) {
    final fgColor = active
        ? const Color(0xFF00875A)
        : (color ?? Colors.grey.shade300);
    final bgColor = active
        ? const Color(0xFF00875A).withValues(alpha: 0.15)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(
                  color: const Color(0xFF00875A).withValues(alpha: 0.4),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fgColor, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fonction utilitaire centralisée ──────────────────────────────────
// Ouvre l'éditeur photo, télécharge si besoin, sauvegarde dans la DB et rafraîchit.
//
// Usage:
//   final edited = await editPhoto(context, photo: myPhoto, photoUrl: (p) => _photoUrl(p));
//   if (edited) setState(() {});
//
// Paramètres :
//   [context]   : BuildContext pour la navigation
//   [photo]     : l'objet Photo à éditer
//   [photoUrl]  : fonction qui transforme un chemin en URL (pour les photos serveur)
//   [onSaved]   : callback appelée après le save DB (pour rafraîchir)
//
// Retourne true si la photo a été éditée et sauvegardée.
Future<bool> editPhoto(
  BuildContext context, {
  required Photo photo,
  required String Function(String path) photoUrl,
  VoidCallback? onSaved,
}) async {
  final isTemp = photo.id < 0;
  String editPath = photo.cheminFichier;

  // Télécharger depuis le serveur si besoin
  if (!isTemp) {
    final tempDir = await getTemporaryDirectory();
    final ext = photo.cheminFichier.split('.').last;
    editPath =
        '${tempDir.path}/edit_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final response = await http.Client().send(
      http.Request('GET', Uri.parse(photoUrl(photo.cheminFichier))),
    );
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      await File(editPath).writeAsBytes(bytes);
    }
  }

  // Ouvrir l'éditeur
  final edited = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => PhotoEditorPage(imagePath: editPath)),
  );

  if (edited == true) {
    if (!isTemp) {
      // Photo du serveur → supprimer l'ancienne + upload la nouvelle
      await photo_api.deletePhoto(photo.id);
      await photo_api.createPhoto(
        cheminFichier: editPath,
        fuiteId: photo.fuiteId,
        datePrise: photo.datePrise,
      );
    }
    onSaved?.call();
  }

  return edited == true;
}
