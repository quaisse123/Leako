// 🔍 Page Détail Fuite — Vue d'ensemble d'une fuite
// Voir les détails / modifier le statut / supprimer / éditer (formulaire)
// Accessible partout dans l'app : tout clic sur une fuite passe ici.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../models/fuite.dart';
import '../models/photo.dart';
import '../services/debit_service.dart';
import '../api/fuite_api.dart' as fuite_api;
import '../api/photo_api.dart' as photo_api;
import '../api/api_config.dart';
import '../widgets/shimmer_placeholder.dart';
import 'modifier_fuite_page.dart';
import 'fuite_chat_page.dart';

/// Construit l'URL complète d'un média stocké côté serveur.
String _photoUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  var base = ApiConfig.apiBaseUrl;
  if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
  if (!base.endsWith('/')) base = '$base/';
  if (path.startsWith('/')) path = path.substring(1);
  return '$base$path';
}

class DetailFuitePage extends StatefulWidget {
  final Fuite fuite;
  final int? utilisateurId;

  const DetailFuitePage({super.key, required this.fuite, this.utilisateurId});

  @override
  State<DetailFuitePage> createState() => _DetailFuitePageState();
}

class _DetailFuitePageState extends State<DetailFuitePage> {
  // ─── Couleurs OCP ─────────────────────────────────────
  static const Color _ocpGreen = Color(0xFF00875A);
  static const Color _ocpLightGreen = Color(0xFFE8F5E9);
  static const Color _ocpBlack = Color(0xFF111111);
  static const Color _ocpGrey = Color(0xFF757575);
  static const Color _ocpLightGrey = Color(0xFFF5F5F5);
  static const Color _ocpRed = Color(0xFFD32F2F);
  static const Color _ocpOrange = Color(0xFFE65100);

  late Fuite _fuite;
  bool _loading = false;
  bool _showMore = false;
  int _photoRefreshKey = 0;
  Future<List<Photo>>? _photosFuture;

  // ─── Mode sélection (suppression en masse) ────────────
  bool _selectionMode = false;
  final Set<int> _selectedPhotoIds = {};
  List<Photo> _photos = const [];
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _fuite = widget.fuite;
    _photosFuture = photo_api.getPhotosByFuite(_fuite.id);
  }

  /// Recharge les photos (appelé après une suppression ou un refresh).
  void _reloadPhotos() {
    setState(() {
      _photoRefreshKey++;
      _photosFuture = photo_api.getPhotosByFuite(_fuite.id);
    });
  }

  /// Pull-to-refresh : recharge les données de la fuite et les photos.
  Future<void> _onRefresh() async {
    try {
      final fuite = await fuite_api.getFuiteById(_fuite.id);
      if (mounted) {
        setState(() => _fuite = fuite);
      }
    } catch (_) {
      // Ignorer l'erreur de rechargement de la fuite
    }
    _reloadPhotos();
  }

  // ─── Statut ───────────────────────────────────────────
  Color _statutColor(String statut) {
    switch (statut) {
      case 'A_REPARER':
        return _ocpRed;
      case 'EN_COURS':
        return _ocpOrange;
      case 'REPAREE':
        return _ocpGreen;
      case 'ANNULEE':
        return _ocpGrey;
      default:
        return _ocpGrey;
    }
  }

  IconData _statutIcon(String statut) {
    switch (statut) {
      case 'A_REPARER':
        return Icons.error_outline_rounded;
      case 'EN_COURS':
        return Icons.construction_rounded;
      case 'REPAREE':
        return Icons.check_circle_rounded;
      case 'ANNULEE':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Met à jour le statut de la fuite (les autres champs sont conservés).
  Future<void> _changerStatut(String nouveauStatut) async {
    if (nouveauStatut == _fuite.statut) return;
    setState(() => _loading = true);
    try {
      await fuite_api.updateFuite(
        id: _fuite.id,
        numeroTag: _fuite.numeroTag,
        statut: nouveauStatut,
        dateDetection: _fuite.dateDetection,
        pressionBar: _fuite.pressionBar,
        diametreOrifice: _fuite.diametreOrifice,
        typeVapeur: _fuite.typeVapeur,
        gpsLatitude: _fuite.gpsLatitude,
        gpsLongitude: _fuite.gpsLongitude,
        zone: _fuite.zone,
        description: _fuite.description,
        coutAnnuelEstime: _fuite.coutAnnuelEstime,
        campagneId: _fuite.campagneId,
      );
      if (!mounted) return;
      setState(() {
        _fuite = Fuite(
          id: _fuite.id,
          campagneId: _fuite.campagneId,
          numeroTag: _fuite.numeroTag,
          dateDetection: _fuite.dateDetection,
          statut: nouveauStatut,
          pressionBar: _fuite.pressionBar,
          diametreOrifice: _fuite.diametreOrifice,
          coutAnnuelEstime: _fuite.coutAnnuelEstime,
          typeVapeur: _fuite.typeVapeur,
          gpsLatitude: _fuite.gpsLatitude,
          gpsLongitude: _fuite.gpsLongitude,
          zone: _fuite.zone,
          description: _fuite.description,
          campagneNom: _fuite.campagneNom,
        );
      });
      _showSnackBar('Statut mis à jour ✓', success: true);
    } catch (e) {
      if (mounted) _showSnackBar('Erreur : ${e.toString()}', success: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Suppression ──────────────────────────────────────
  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
            SizedBox(width: 10),
            Text('Supprimer la fuite ?'),
          ],
        ),
        content: Text(
          'La fuite "${_fuite.numeroTag ?? 'Sans tag'}" ainsi que ses photos, '
          'messages et analyses seront définitivement supprimés.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;
    setState(() => _loading = true);
    try {
      await fuite_api.deleteFuite(_fuite.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar('Erreur : ${e.toString()}', success: false);
    }
  }

  // ─── Édition (ouvrir le formulaire) ───────────────────
  Future<void> _modifier() async {
    final modified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ModifierFuitePage(
          fuite: _fuite,
          utilisateurId: widget.utilisateurId,
        ),
      ),
    );
    if (modified == true && mounted) {
      // Recharger la fuite à jour depuis le backend
      try {
        final updated = await fuite_api.getFuiteById(_fuite.id);
        if (mounted) setState(() => _fuite = updated);
      } catch (_) {}
    }
  }

  // ─── Chat ─────────────────────────────────────────────
  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FuiteChatPage(
        fuiteId: _fuite.id,
        numeroTag: _fuite.numeroTag ?? 'Sans tag',
        utilisateurId: widget.utilisateurId ?? 1,
      ),
    );
  }

  // ─── GPS ──────────────────────────────────────────────
  Future<void> _ouvrirGoogleMaps() async {
    final lat = _fuite.gpsLatitude;
    final lng = _fuite.gpsLongitude;
    if (lat == null || lng == null) return;
    final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Helpers UI ───────────────────────────────────────
  void _showSnackBar(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: success ? _ocpGreen : _ocpRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(String iso) {
    try {
      final d = DateTime.parse(iso.replaceFirst(' ', 'T'));
      var result =
          '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
      if (iso.contains('T') ||
          iso.contains(' ') ||
          d.hour != 0 ||
          d.minute != 0) {
        result +=
            ' - ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
      return result;
    } catch (_) {
      return iso;
    }
  }

  // ─── UI : ligne info compacte ─────────────────────────
  Widget _infoLine({
    required IconData icon,
    required String value,
    Color? valueColor,
    bool bold = false,
    bool multiline = false,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _ocpGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: _ocpGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? _ocpBlack,
                ),
                maxLines: multiline ? null : 2,
                overflow: multiline ? null : TextOverflow.ellipsis,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // ─── UI : photos ──────────────────────────────────────
  Widget _buildPhotosSection() {
    return FutureBuilder<List<Photo>>(
      key: ValueKey(_photoRefreshKey),
      future: _photosFuture,
      builder: (context, snapshot) {
        final photos = snapshot.data ?? const <Photo>[];
        // Mémoriser les photos pour le mode sélection
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          _photos = photos;
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        if (photos.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: _ocpLightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.photo_library_outlined, size: 34, color: _ocpGrey),
                SizedBox(height: 6),
                Text(
                  'Aucun média',
                  style: TextStyle(color: _ocpGrey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.4,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => _buildPhotoThumb(photos[index]),
        );
      },
    );
  }

  Widget _buildPhotoThumb(Photo photo) {
    final ext = photo.cheminFichier.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
    final isTemp = photo.id < 0;

    Widget thumb;
    if (isVideo) {
      final hasThumb =
          photo.thumbnailUrl != null && photo.thumbnailUrl!.isNotEmpty;
      thumb = Stack(
        fit: StackFit.expand,
        children: [
          if (isTemp)
            Image.file(
              File(photo.cheminFichier),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildVideoPlaceholder(),
            )
          else if (hasThumb)
            CachedNetworkImage(
              imageUrl: _photoUrl(photo.thumbnailUrl!),
              fit: BoxFit.cover,
              memCacheWidth: 400,
              memCacheHeight: 300,
              placeholder: (_, _) =>
                  const ShimmerPlaceholder(width: 96, height: 96),
              errorWidget: (_, _, _) => _buildVideoPlaceholder(),
            )
          else
            _buildVideoPlaceholder(),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      );
    } else {
      // Images : on charge la miniature générée par le backend (300px, légère)
      // pour un chargement instantané. Retombe sur l'original si pas de miniature.
      final hasThumb =
          photo.thumbnailUrl != null && photo.thumbnailUrl!.isNotEmpty;
      thumb = isTemp
          ? Image.file(
              File(photo.cheminFichier),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: _ocpLightGrey,
                child: const Icon(
                  Icons.broken_image_rounded,
                  size: 28,
                  color: _ocpGrey,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: _photoUrl(
                hasThumb ? photo.thumbnailUrl! : photo.cheminFichier,
              ),
              fit: BoxFit.cover,
              memCacheWidth: 400,
              memCacheHeight: 300,
              placeholder: (_, _) =>
                  const ShimmerPlaceholder(width: 96, height: 96),
              errorWidget: (_, _, _) => Container(
                color: _ocpLightGrey,
                child: const Icon(
                  Icons.broken_image_rounded,
                  size: 28,
                  color: _ocpGrey,
                ),
              ),
            );
    }

    final isSelected = _selectedPhotoIds.contains(photo.id);

    return GestureDetector(
      onTap: () {
        if (_selectionMode) {
          setState(() {
            if (isSelected) {
              _selectedPhotoIds.remove(photo.id);
            } else {
              _selectedPhotoIds.add(photo.id);
            }
          });
        } else {
          _showPreview(photo);
        }
      },
      onLongPress: () {
        if (!_selectionMode) {
          setState(() {
            _selectionMode = true;
            _selectedPhotoIds.add(photo.id);
          });
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SizedBox.expand(child: thumb),
            // ── Overlay de sélection ──
            if (_selectionMode)
              Container(
                color: isSelected
                    ? _ocpGreen.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.25),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _ocpGreen : Colors.white,
                        border: Border.all(
                          color: isSelected ? _ocpGreen : _ocpGrey,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.videocam_rounded, size: 28, color: Colors.grey),
    );
  }

  void _showPreview(Photo photo) {
    final path = photo.cheminFichier;
    final ext = path.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
    final isTemp = !path.startsWith('/') && !path.startsWith('http');

    if (isVideo) {
      // Lecture vidéo plein écran
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _VideoPreviewScreen(videoUrl: isTemp ? path : _photoUrl(path)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isTemp
                  ? Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: _photoUrl(path),
                      fit: BoxFit.contain,
                      memCacheWidth: 1080,
                      placeholder: (_, _) => Container(
                        color: Colors.black87,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (_, _, _) => const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // ── Bouton télécharger ──
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => _downloadMedia(
                  url: isTemp ? path : _photoUrl(path),
                  filename: path.split('/').last,
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    size: 20,
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

  // ─── Téléchargement d'un média ────────────────────────
  Future<void> _downloadMedia({
    required String url,
    required String filename,
  }) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Téléchargement en cours…'),
          duration: Duration(seconds: 2),
        ),
      );

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erreur de téléchargement (${response.statusCode})'),
            backgroundColor: _ocpRed,
          ),
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      // Nom de fichier sûr (sans chemin)
      final safeName = filename.split('/').last.split('\\').last;
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ Média sauvegardé dans Documents'),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur de téléchargement : $e'),
          backgroundColor: _ocpRed,
        ),
      );
    }
  }

  // ─── Suppression en masse ─────────────────────────────
  Future<void> _deleteSelectedPhotos() async {
    if (_selectedPhotoIds.isEmpty) return;

    final count = _selectedPhotoIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer les médias ?'),
        content: Text(
          'Voulez-vous vraiment supprimer $count média${count > 1 ? 's' : ''} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: _ocpRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    var success = 0;
    var failed = 0;
    try {
      for (final id in _selectedPhotoIds.toList()) {
        try {
          await photo_api.deletePhoto(id);
          success++;
        } catch (_) {
          failed++;
        }
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _selectionMode = false;
        _selectedPhotoIds.clear();
      });
      _reloadPhotos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? '✅ $success média${success > 1 ? 's' : ''} supprimé${success > 1 ? 's' : ''}'
                : '⚠️ $success supprimé(s), $failed en échec',
          ),
          backgroundColor: failed == 0 ? _ocpGreen : _ocpOrange,
        ),
      );
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedPhotoIds.clear();
    });
  }

  // ─── Build ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final statutLabel = Fuite.statuts[_fuite.statut] ?? _fuite.statut;
    final statutClr = _statutColor(_fuite.statut);
    final statutIcn = _statutIcon(_fuite.statut);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Détail de la fuite',
          style: TextStyle(fontWeight: FontWeight.bold, color: _ocpBlack),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ocpBlack),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectionMode)
            // ── Mode sélection : compteur + annuler ──
            Row(
              children: [
                Text(
                  '${_selectedPhotoIds.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _ocpGreen,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  tooltip: 'Quitter la sélection',
                  onPressed: _deleting ? null : _exitSelectionMode,
                  icon: const Icon(Icons.close_rounded, color: _ocpBlack),
                ),
              ],
            )
          else ...[
            // ── Bouton sélection (suppression en masse) ──
            GestureDetector(
              onTap: () {
                setState(() => _selectionMode = true);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _ocpGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  size: 20,
                  color: _ocpGreen,
                ),
              ),
            ),
            // ── Bouton chat ──
            GestureDetector(
              onTap: _openChat,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _ocpGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_rounded, size: 20, color: _ocpGreen),
              ),
            ),
            // ── Bouton éditer ──
            GestureDetector(
              onTap: _loading ? null : _modifier,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _ocpGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, size: 20, color: _ocpGreen),
              ),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: _ocpGreen,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // ── Carte unique : en-tête + infos compactes ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── En-tête : icône + tag + campagne ──
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: statutClr.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(statutIcn, size: 26, color: statutClr),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fuite.numeroTag ?? 'Sans tag',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: _ocpBlack,
                                  ),
                                ),
                                if (_fuite.campagneNom != null &&
                                    _fuite.campagneNom!.isNotEmpty)
                                  Text(
                                    _fuite.campagneNom!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _ocpGrey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ── Badge statut cliquable ──
                      PopupMenuButton<String>(
                        enabled: !_loading,
                        onSelected: _changerStatut,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        offset: const Offset(0, 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: statutClr.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statutClr.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(statutIcn, size: 18, color: statutClr),
                              const SizedBox(width: 8),
                              Text(
                                statutLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: statutClr,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 18,
                                color: statutClr,
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => Fuite.statuts.entries
                            .map(
                              (entry) => PopupMenuItem<String>(
                                value: entry.key,
                                child: Row(
                                  children: [
                                    Icon(
                                      _statutIcon(entry.key),
                                      size: 18,
                                      color: _statutColor(entry.key),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontWeight: entry.key == _fuite.statut
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: entry.key == _fuite.statut
                                            ? _statutColor(entry.key)
                                            : null,
                                      ),
                                    ),
                                    if (entry.key == _fuite.statut) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: _statutColor(entry.key),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 4),
                      // ── Lignes d'infos : essentielles ──
                      _infoLine(
                        icon: Icons.calendar_today_rounded,
                        value: _formatDateTime(_fuite.dateDetection),
                      ),
                      if (_fuite.coutAnnuelEstime != null &&
                          _fuite.coutAnnuelEstime! > 0) ...[
                        _infoLine(
                          icon: Icons.money_rounded,
                          value:
                              '${DebitService.formater(_fuite.coutAnnuelEstime!)} MAD/an',
                          valueColor: _fuite.coutAnnuelEstime! > 50000
                              ? _ocpRed
                              : _ocpGreen,
                          bold: true,
                        ),
                        if (_fuite.pressionBar != null &&
                            _fuite.diametreOrifice != null)
                          _infoLine(
                            icon: Icons.air_rounded,
                            value:
                                '${DebitService.calculerDebit(pressionRel: _fuite.pressionBar!, diametreMm: _fuite.diametreOrifice!).toStringAsFixed(1)} kg/h',
                          ),
                      ],
                      // ── Infos supplémentaires (à la demande) ──
                      if (_showMore) ...[
                        if (_fuite.pressionBar != null) ...[
                          _infoLine(
                            icon: Icons.speed_rounded,
                            value:
                                '${_fuite.pressionBar!.toStringAsFixed(1)} bar',
                          ),
                        ],
                        if (_fuite.diametreOrifice != null) ...[
                          _infoLine(
                            icon: Icons.circle_outlined,
                            value:
                                '${_fuite.diametreOrifice!.toStringAsFixed(1)} mm',
                          ),
                        ],
                        if (_fuite.typeVapeur != null) ...[
                          _infoLine(
                            icon: Icons.local_fire_department_rounded,
                            value:
                                Fuite.typesVapeur[_fuite.typeVapeur] ??
                                _fuite.typeVapeur!,
                          ),
                        ],
                        if (_fuite.zone?.isNotEmpty == true) ...[
                          _infoLine(
                            icon: Icons.place_rounded,
                            value: _fuite.zone!,
                          ),
                        ],
                        if (_fuite.gpsLatitude != null &&
                            _fuite.gpsLongitude != null) ...[
                          _infoLine(
                            icon: Icons.gps_fixed_rounded,
                            value:
                                '${_fuite.gpsLatitude!.toStringAsFixed(5)}, '
                                '${_fuite.gpsLongitude!.toStringAsFixed(5)}',
                            action: IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 16,
                              onPressed: _ouvrirGoogleMaps,
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                color: _ocpGreen,
                              ),
                            ),
                          ),
                        ],
                        if (_fuite.description != null &&
                            _fuite.description!.isNotEmpty) ...[
                          _infoLine(
                            icon: Icons.notes_rounded,
                            value: _fuite.description!,
                            multiline: true,
                          ),
                        ],
                      ],
                      // ── Bouton Voir plus / Voir moins ──
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _showMore = !_showMore),
                          style: TextButton.styleFrom(
                            foregroundColor: _ocpGreen,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: Icon(
                            _showMore
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _showMore ? 'Voir moins' : 'Voir plus',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Section médias (grille 2 colonnes) ──
                _sectionCard(
                  title: 'Médias',
                  icon: Icons.photo_library_rounded,
                  child: _buildPhotosSection(),
                ),
              ],
            ),
          ),
          ),

          // ── Barre d'actions en bas ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: _selectionMode
                  ? const EdgeInsets.fromLTRB(12, 8, 12, 12)
                  : const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                ),
              ),
              child: _selectionMode
                  // ── Barre de sélection (suppression en masse) ──
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_selectedPhotoIds.length} sélectionné${_selectedPhotoIds.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _ocpBlack,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tout sélectionner',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              if (_selectedPhotoIds.length == _photos.length) {
                                _selectedPhotoIds.clear();
                              } else {
                                _selectedPhotoIds
                                  ..clear()
                                  ..addAll(_photos.map((p) => p.id));
                              }
                            });
                          },
                          icon: const Icon(
                            Icons.select_all_rounded,
                            color: _ocpGreen,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Annuler',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: _deleting ? null : _exitSelectionMode,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _ocpGrey,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          onPressed: _deleting || _selectedPhotoIds.isEmpty
                              ? null
                              : _deleteSelectedPhotos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ocpRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _deleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.delete_rounded, size: 18),
                          label: Text(
                            _deleting ? '…' : 'Supprimer',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  // ── Barre d'actions normale ──
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _modifier,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ocpGreen,
                              side: const BorderSide(color: _ocpGreen),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            label: const Text(
                              'Modifier',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _supprimer,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ocpRed,
                              side: const BorderSide(color: _ocpRed),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            label: const Text(
                              'Supprimer',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _ocpGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _ocpBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Écran plein écran de lecture vidéo (utilisé par l'aperçu des médias).
class _VideoPreviewScreen extends StatefulWidget {
  final String videoUrl;
  const _VideoPreviewScreen({required this.videoUrl});

  @override
  State<_VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<_VideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  double _sliderValue = 0;
  String _currentTime = '0:00';
  String _totalDuration = '0:00';

  @override
  void initState() {
    super.initState();
    final isNetwork = widget.videoUrl.startsWith('http');
    _controller = isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.file(File(widget.videoUrl));
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {
            _initialized = true;
            _totalDuration = _formatDuration(_controller.value.duration);
          });
          _controller.play();
          _controller.addListener(_onControllerUpdate);
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() => _initialized = true);
        });
  }

  Future<void> _downloadVideo(BuildContext context) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Téléchargement en cours…'),
          duration: Duration(seconds: 2),
        ),
      );

      final isNetwork = widget.videoUrl.startsWith('http');
      final response = isNetwork
          ? await http.get(Uri.parse(widget.videoUrl))
          : null;
      if (isNetwork && response!.statusCode != 200) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erreur de téléchargement (${response.statusCode})'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = widget.videoUrl.split('/').last.split('\\').last;
      final file = File('${dir.path}/$safeName');
      if (isNetwork) {
        await file.writeAsBytes(response!.bodyBytes);
      } else {
        await File(widget.videoUrl).copy(file.path);
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ Vidéo sauvegardée dans Documents'),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur de téléchargement : $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    if (dur.inMilliseconds > 0) {
      setState(() {
        _sliderValue = pos.inMilliseconds / dur.inMilliseconds;
        _currentTime = _formatDuration(pos);
      });
    }
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
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
        title: const Text('Vidéo', style: TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            tooltip: 'Télécharger',
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => _downloadVideo(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _initialized
            ? _controller.value.isInitialized
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final videoRatio = _controller.value.aspectRatio;
                        final availableWidth = constraints.maxWidth;
                        final availableHeight = constraints.maxHeight;
                        final fitHeight = availableWidth / videoRatio;
                        final finalHeight = fitHeight > availableHeight
                            ? availableHeight
                            : fitHeight;
                        final finalWidth = finalHeight * videoRatio;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _showControls = !_showControls),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Center(
                                child: SizedBox(
                                  width: finalWidth,
                                  height: finalHeight,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                              if (!_controller.value.isPlaying && _showControls)
                                const IgnorePointer(
                                  child: Center(
                                    child: Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: Colors.white,
                                      size: 72,
                                    ),
                                  ),
                                ),
                              if (_showControls)
                                Container(
                                  height: 76,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.85),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          Text(
                                            _currentTime,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderThemeData(
                                                trackHeight: 2,
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                      enabledThumbRadius: 5,
                                                    ),
                                                overlayShape:
                                                    const RoundSliderOverlayShape(
                                                      overlayRadius: 12,
                                                    ),
                                                activeTrackColor: Colors.white,
                                                inactiveTrackColor:
                                                    Colors.white38,
                                                thumbColor: Colors.white,
                                                overlayColor: Colors.white24,
                                              ),
                                              child: Slider(
                                                value: _sliderValue,
                                                onChanged: (v) {
                                                  final dur = _controller
                                                      .value
                                                      .duration;
                                                  setState(() {
                                                    _sliderValue = v;
                                                    _controller.seekTo(
                                                      Duration(
                                                        milliseconds:
                                                            (dur.inMilliseconds *
                                                                    v)
                                                                .round(),
                                                      ),
                                                    );
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _totalDuration,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (_controller.value.isPlaying) {
                                            _controller.pause();
                                          } else {
                                            _controller.play();
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            _controller.value.isPlaying
                                                ? Icons
                                                      .pause_circle_filled_rounded
                                                : Icons
                                                      .play_circle_fill_rounded,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 48,
                        color: Colors.white38,
                      ),
                    )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      ),
    );
  }
}
