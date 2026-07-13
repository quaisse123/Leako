// 📸 Widget de sélection d'images (galerie + appareil photo)
// Affiche les photos existantes sous forme de miniatures
// Utilisable en création (sans fuiteId) ou en modification

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/photo.dart';
import '../api/photo_api.dart' as photo_api;

class ImagePickerWidget extends StatefulWidget {
  /// L'ID de la fuite (null en mode création)
  final int? fuiteId;

  /// Photos déjà existantes (mode modification)
  final List<Photo> photosInitiales;

  /// Callback pour récupérer les chemins des nouvelles photos (mode création)
  final ValueChanged<List<String>>? onPhotosChanged;

  const ImagePickerWidget({
    super.key,
    this.fuiteId,
    this.photosInitiales = const [],
    this.onPhotosChanged,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final _picker = ImagePicker();
  late List<Photo> _photos;

  /// Chemins des photos ajoutées en mode création (pas encore en DB)
  final List<String> _tempPaths = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photosInitiales);
    if (widget.fuiteId != null) {
      _loadPhotos();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await photo_api.getPhotosByFuite(widget.fuiteId!);
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickerDepuis(ImageSource source) async {
    try {
      List<XFile> xfiles;

      if (source == ImageSource.gallery) {
        // Sélection multiple mixte (images + vidéos)
        xfiles = await _picker.pickMultipleMedia(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } else {
        // Appareil photo → photo OU vidéo (choix via sous-menu)
        xfiles = [];
      }
      if (xfiles.isEmpty) return;

      for (final xfile in xfiles) {
        await _sauvegarderFichier(xfile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _supprimerPhoto(Photo photo) async {
    try {
      await photo_api.deletePhoto(photo.id);
      await _loadPhotos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _supprimerTemp(String path) {
    File(path).delete();
    // Supprimer aussi la miniature vidéo si elle existe
    File('$path.thumb.jpg').delete();
    setState(() {
      _tempPaths.remove(path);
    });
    widget.onPhotosChanged?.call(List.from(_tempPaths));
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter un média',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Photos et vidéos (sélection multiple)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _optionButton(
                    ctx,
                    icon: Icons.photo_library_rounded,
                    label: 'Galerie',
                    color: const Color(0xFF00875A),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickerDepuis(ImageSource.gallery);
                    },
                  ),
                  _optionButton(
                    ctx,
                    icon: Icons.camera_alt_rounded,
                    label: 'Appareil photo',
                    color: const Color(0xFF00875A),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCameraOptions();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Prendre avec la caméra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _optionButton(
                    ctx,
                    icon: Icons.camera_alt_rounded,
                    label: 'Photo',
                    color: const Color(0xFF00875A),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickerCameraImage();
                    },
                  ),
                  _optionButton(
                    ctx,
                    icon: Icons.videocam_rounded,
                    label: 'Vidéo',
                    color: const Color(0xFF00875A),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickerCameraVideo();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickerCameraImage() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xfile == null) return;
      await _sauvegarderFichier(xfile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _pickerCameraVideo() async {
    try {
      final xfile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      if (xfile == null) return;
      await _sauvegarderFichier(xfile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _sauvegarderFichier(XFile xfile) async {
    try {
      final destPath = xfile.path;

      if (widget.fuiteId != null) {
        await photo_api.createPhoto(
          fuiteId: widget.fuiteId!,
          cheminFichier: destPath,
          datePrise: DateTime.now().toIso8601String(),
        );
        await _loadPhotos();
      } else {
        setState(() {
          _tempPaths.add(destPath);
        });
        widget.onPhotosChanged?.call(List.from(_tempPaths));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _optionButton(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final allPhotos = [
      ..._photos,
      ..._tempPaths.map(
        (p) => Photo(
          id: -_tempPaths.indexOf(p) - 1,
          fuiteId: widget.fuiteId ?? 0,
          cheminFichier: p,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Grille de miniatures ──
        if (allPhotos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allPhotos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final photo = allPhotos[index];
                  return _buildThumbnail(photo);
                },
              ),
            ),
          ),

        // ── Bouton ajouter ──
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _showPickerOptions,
            icon: const Icon(
              Icons.add_a_photo_rounded,
              color: Color(0xFF00875A),
            ),
            label: const Text(
              'Ajouter des photos',
              style: TextStyle(
                color: Color(0xFF00875A),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00875A)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isVideo(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  Widget _buildThumbnail(Photo photo) {
    final isTemp = photo.id < 0;
    final isVideo = _isVideo(photo.cheminFichier);
    // Pour les vidéos, utiliser la miniature .thumb.jpg si elle existe
    final imagePath = isVideo
        ? '${photo.cheminFichier}.thumb.jpg'
        : photo.cheminFichier;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        onTap: () => _showMediaPreview(photo),
        child: Stack(
          children: [
            Image.file(
              File(imagePath),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                child: Icon(
                  isVideo ? Icons.movie_rounded : Icons.broken_image_rounded,
                  color: Colors.grey,
                ),
              ),
            ),
            // Indicateur vidéo
            if (isVideo)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            // Bouton supprimer
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () {
                  if (isTemp) {
                    _supprimerTemp(photo.cheminFichier);
                  } else {
                    _supprimerPhoto(photo);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaPreview(Photo photo) {
    final isVideo = _isVideo(photo.cheminFichier);

    if (isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _VideoPlayerScreen(path: photo.cheminFichier),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(photo.cheminFichier),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran de lecture vidéo plein écran.
class _VideoPlayerScreen extends StatefulWidget {
  final String path;
  const _VideoPlayerScreen({required this.path});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _initialized = true);
          _controller.play();
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() => _initialized = true);
        });
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.path.split('/').last,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Center(
        child: _initialized
            ? _controller.value.isInitialized
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            if (!_controller.value.isPlaying)
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 72,
                              ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_rounded,
                          color: Colors.white38,
                          size: 64,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Impossible de lire cette vidéo',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Chargement de la vidéo…',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
      ),
    );
  }
}
