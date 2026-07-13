// 📋 Page Détail Campagne — Récap + liste complète des fuites
// Modifier/supprimer la campagne depuis l'AppBar
// Gestion complète des fuites (CRUD, sélection, changement statut)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/campagne.dart';
import '../models/fuite.dart';
import '../models/photo.dart';
import '../services/debit_service.dart';
import '../api/campagne_api.dart' as campagne_api;
import '../api/fuite_api.dart' as fuite_api;
import '../api/photo_api.dart' as photo_api;
import 'creer_fuite_page.dart';
import 'modifier_fuite_page.dart';

class DetailCampagnePage extends StatefulWidget {
  final Campagne campagne;
  final int utilisateurId;

  const DetailCampagnePage({
    super.key,
    required this.campagne,
    required this.utilisateurId,
  });

  @override
  State<DetailCampagnePage> createState() => _DetailCampagnePageState();
}

class _DetailCampagnePageState extends State<DetailCampagnePage>
    with SingleTickerProviderStateMixin {
  late Campagne _campagne;
  List<Fuite> _fuites = [];
  List<Fuite> _filteredFuites = [];
  bool _isLoading = true;

  // ─── Filtres fuites ───────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statutFilter = 'TOUS';
  String _sortCriterion = 'DATE'; // 'DATE' | 'TAG' | 'STATUT'

  // ─── Sélection fuites ─────────────────────────────────
  final Set<int> _selectedIds = {};
  bool _selectionMode = false;

  // ─── Animation ────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ─── Stats ────────────────────────────────────────────
  Map<String, int> _stats = {};

  // ─── Couleurs ─────────────────────────────────────────
  static const Color _ocpGreen = Color(0xFF00875A);
  static const Color _ocpLightGreen = Color(0xFFE8F5E9);
  static const Color _ocpBlack = Color(0xFF111111);
  static const Color _ocpGrey = Color(0xFF757575);
  static const Color _ocpLightGrey = Color(0xFFF5F5F5);
  static const Color _ocpRed = Color(0xFFD32F2F);
  static const Color _ocpBlue = Color(0xFF1565C0);
  static const Color _ocpOrange = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _campagne = widget.campagne;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final fuites = await fuite_api.getFuitesByCampagne(_campagne.id);
      // Recharger la campagne au cas où elle a été modifiée
      try {
        _campagne = await campagne_api.getCampagneById(_campagne.id);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _fuites = fuites;
        _stats = _computeStats(fuites);
        _applyFilters();
        _isLoading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, int> _computeStats(List<Fuite> fuites) {
    return {
      'total': fuites.length,
      'a_reparer': fuites.where((f) => f.statut == 'A_REPARER').length,
      'en_cours': fuites.where((f) => f.statut == 'EN_COURS').length,
      'reparees': fuites.where((f) => f.statut == 'REPAREE').length,
      'annulees': fuites.where((f) => f.statut == 'ANNULEE').length,
    };
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    _applyFilters();
  }

  void _applyFilters() {
    var result = List<Fuite>.from(_fuites);
    if (_statutFilter != 'TOUS') {
      result = result.where((f) => f.statut == _statutFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result.where((f) {
        final tag = f.numeroTag?.toLowerCase() ?? '';
        final zone = f.zone?.toLowerCase() ?? '';
        final desc = f.description?.toLowerCase() ?? '';
        final typeVapeur = Fuite.typesVapeur[f.typeVapeur]?.toLowerCase() ?? '';
        return tag.contains(_searchQuery) ||
            zone.contains(_searchQuery) ||
            desc.contains(_searchQuery) ||
            typeVapeur.contains(_searchQuery);
      }).toList();
    }
    // Tri
    switch (_sortCriterion) {
      case 'DATE':
        result.sort((a, b) {
          final dateA = DateTime.tryParse(a.dateDetection);
          final dateB = DateTime.tryParse(b.dateDetection);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
        break;
      case 'TAG':
        result.sort(
          (a, b) => (a.numeroTag ?? '').toLowerCase().compareTo(
            (b.numeroTag ?? '').toLowerCase(),
          ),
        );
        break;
      case 'STATUT':
        result.sort((a, b) => a.statut.compareTo(b.statut));
        break;
      case 'COUT':
        result.sort((a, b) {
          final coutA = a.coutAnnuelEstime ?? 0;
          final coutB = b.coutAnnuelEstime ?? 0;
          return coutB.compareTo(coutA);
        });
        break;
    }
    _filteredFuites = result;
  }

  // ─── CRUD Campagne ────────────────────────────────────
  Future<void> _modifierCampagne() async {
    final nomCtrl = TextEditingController(text: _campagne.nom);
    final descCtrl = TextEditingController(text: _campagne.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool estCloturee = _campagne.estCloturee;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 1,
              title: const Text(
                'Modifier la campagne',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _ocpBlack,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: _ocpBlack),
                onPressed: () => Navigator.pop(context, false),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context, true);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _ocpGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _ocpLightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: _ocpGreen,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Nom de la campagne'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nomCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [LengthLimitingTextInputFormatter(100)],
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requis' : null,
                      style: const TextStyle(color: _ocpBlack),
                      decoration: _inputDecoration(
                        label: 'Nom',
                        icon: Icons.campaign_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Description (optionnelle)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: _ocpBlack),
                      decoration: _inputDecoration(
                        label: 'Description',
                        icon: Icons.description_outlined,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _ocpLightGrey,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: estCloturee
                                  ? _ocpLightGreen
                                  : const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              estCloturee
                                  ? Icons.lock_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: estCloturee ? _ocpGrey : _ocpBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  estCloturee
                                      ? 'Campagne clôturée'
                                      : 'Campagne active',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _ocpBlack,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  estCloturee
                                      ? 'Aucune nouvelle fuite ne pourra être ajoutée'
                                      : 'Les fuites peuvent encore être signalées',
                                  style: TextStyle(
                                    color: _ocpGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: estCloturee,
                            onChanged: (v) =>
                                setDialogState(() => estCloturee = v),
                            activeTrackColor: _ocpGreen,
                            inactiveThumbColor: _ocpBlue,
                            inactiveTrackColor: const Color(0xFFBBDEFB),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ocpGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 10),
                            Text(
                              'Enregistrer les modifications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      try {
        await campagne_api.updateCampagne(
          id: _campagne.id,
          nom: nomCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty
              ? null
              : descCtrl.text.trim(),
          estCloturee: estCloturee,
          createurId: widget.utilisateurId,
        );
        _loadData();
        _showSnackBar('Campagne modifiée ✓');
      } catch (e) {
        _showSnackBar('Erreur : ${e.toString()}');
      }
    }
    nomCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _supprimerCampagne() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _ocpRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: _ocpRed,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Supprimer cette campagne ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _ocpBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '« ${_campagne.nom} »\nToutes les fuites, photos et données seront définitivement supprimées.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ocpGrey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: _ocpGrey),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ocpRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await campagne_api.deleteCampagne(_campagne.id);
        if (!mounted) return;
        Navigator.pop(context, true); // true = campagne supprimée
      } catch (e) {
        _showSnackBar('Erreur : ${e.toString()}');
      }
    }
  }

  // ─── CRUD Fuites ──────────────────────────────────────
  Future<void> _creerFuite() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreerFuitePage(
          utilisateurId: widget.utilisateurId,
          campagneId: _campagne.id,
        ),
      ),
    );
    if (created == true) _loadData();
  }

  Future<void> _modifierFuite(Fuite fuite) async {
    final modified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => ModifierFuitePage(fuite: fuite)),
    );
    if (modified == true) _loadData();
  }

  // ─── Sélection fuites ─────────────────────────────────
  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
        _selectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  Future<void> _supprimerSelection() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _ocpRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: _ocpRed,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Suppression groupée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _ocpBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedIds.length} fuite(s) seront définitivement supprimées.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ocpGrey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ocpRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final ids = Set<int>.from(_selectedIds);
        _clearSelection();
        for (final id in ids) {
          await fuite_api.deleteFuite(id);
        }
        _loadData();
        _showSnackBar('${ids.length} fuite(s) supprimée(s) ✓');
      } catch (e) {
        _showSnackBar('Erreur : ${e.toString()}');
      }
    }
  }

  Future<void> _changerStatutSelection(String nouveauStatut) async {
    if (_selectedIds.isEmpty) return;
    final ids = Set<int>.from(_selectedIds);
    _clearSelection();
    try {
      for (final id in ids) {
        final fuite = await fuite_api.getFuiteById(id);
        await fuite_api.updateFuite(
          id: id,
          statut: nouveauStatut,
          dateDetection: fuite.dateDetection,
          campagneId: fuite.campagneId,
        );
      }
      _loadData();
      _showSnackBar('${ids.length} fuite(s) mise(s) à jour ✓');
    } catch (e) {
      _showSnackBar('Erreur : ${e.toString()}');
    }
  }

  // ─── Helpers UI ───────────────────────────────────────
  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(msg),
          ],
        ),
        backgroundColor: _ocpGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: Color(0xFF111111),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _ocpGreen, size: 20),
      filled: true,
      fillColor: _ocpLightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _ocpGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _ocpGreen))
          : Column(
              children: [
                if (_selectionMode) _buildSelectionBar(),
                _buildRecapHeader(),
                _buildSearchBar(),
                Expanded(child: _buildFuitesList()),
              ],
            ),
      floatingActionButton: _selectionMode || _campagne.estCloturee
          ? null
          : FloatingActionButton.extended(
              onPressed: _creerFuite,
              backgroundColor: _ocpGreen,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Ajouter une fuite',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final isActive = !_campagne.estCloturee;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _ocpBlack),
        onPressed: () => Navigator.pop(context, true),
      ),
      title: Text(
        _campagne.nom,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: _ocpBlack,
          fontSize: 18,
        ),
      ),
      actions: [
        // Badge actif/clôturé
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? _ocpLightGreen : _ocpLightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                size: 12,
                color: isActive ? _ocpGreen : _ocpGrey,
              ),
              const SizedBox(width: 3),
              Text(
                isActive ? 'Active' : 'Clôturée',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? _ocpGreen : _ocpGrey,
                ),
              ),
            ],
          ),
        ),
        // Modifier campagne
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: _ocpGrey),
          onPressed: _modifierCampagne,
          tooltip: 'Modifier la campagne',
        ),
        // Supprimer campagne
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: _ocpRed),
          onPressed: _supprimerCampagne,
          tooltip: 'Supprimer la campagne',
        ),
      ],
    );
  }

  // ─── Barre de sélection ───────────────────────────────
  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: _ocpLightGreen,
      child: Row(
        children: [
          Text(
            '${_selectedIds.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _ocpGreen,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'sélectionnée(s)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _ocpGreen,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          // Changer statut
          PopupMenuButton<String>(
            onSelected: _changerStatutSelection,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _ocpBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.loop_rounded, size: 18, color: _ocpBlue),
            ),
            itemBuilder: (context) => Fuite.statuts.entries
                .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
          ),
          const SizedBox(width: 6),
          // Supprimer
          GestureDetector(
            onTap: _supprimerSelection,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _ocpRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                size: 18,
                color: _ocpRed,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Annuler
          GestureDetector(
            onTap: _clearSelection,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _ocpGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, size: 18, color: _ocpGrey),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Récap campagne ───────────────────────────────────
  Widget _buildRecapHeader() {
    final totalFuites = _fuites.length;
    final aReparer = _stats['A_REPARER'] ?? 0;
    final enCours = _stats['EN_COURS'] ?? 0;
    final reparees = _stats['REPAREE'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ocpGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ocpGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (_campagne.description != null &&
              _campagne.description!.isNotEmpty) ...[
            Text(
              _campagne.description!,
              style: TextStyle(color: _ocpGrey, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],
          // Stats row
          Row(
            children: [
              _buildStatChip(
                Icons.water_drop_rounded,
                '$totalFuites',
                'Total',
                _ocpGreen,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.error_outline_rounded,
                '$aReparer',
                'À réparer',
                _ocpRed,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.construction_rounded,
                '$enCours',
                'En cours',
                _ocpOrange,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.check_circle_rounded,
                '$reparees',
                'Réparées',
                _ocpGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Date de création
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: _ocpGrey),
              const SizedBox(width: 4),
              Text(
                'Créée le ${_formatDateTime(_campagne.dateCreation)}',
                style: TextStyle(color: _ocpGrey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Barre de recherche fuites ────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: _ocpBlack, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher tag, localisation…',
                hintStyle: TextStyle(color: _ocpGrey.withValues(alpha: 0.7)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _ocpGrey,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: _ocpLightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _ocpGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Tri
          PopupMenuButton<String>(
            icon: Icon(
              _sortCriterion == 'DATE'
                  ? Icons.sort_rounded
                  : Icons.sort_rounded,
              color: _sortCriterion != 'DATE' ? _ocpGreen : _ocpGrey,
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              setState(() {
                _sortCriterion = v;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'COUT',
                child: Row(
                  children: [
                    Icon(
                      Icons.money_rounded,
                      size: 18,
                      color: _sortCriterion == 'COUT' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text('Coût'),
                    if (_sortCriterion == 'COUT') ...[
                      const Spacer(),
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: _ocpGreen,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'DATE',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: _sortCriterion == 'DATE' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text('Date'),
                    if (_sortCriterion == 'DATE') ...[
                      const Spacer(),
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: _ocpGreen,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'TAG',
                child: Row(
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 18,
                      color: _sortCriterion == 'TAG' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text('Tag'),
                    if (_sortCriterion == 'TAG') ...[
                      const Spacer(),
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: _ocpGreen,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'STATUT',
                child: Row(
                  children: [
                    Icon(
                      Icons.loop_rounded,
                      size: 18,
                      color: _sortCriterion == 'STATUT' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text('Statut'),
                    if (_sortCriterion == 'STATUT') ...[
                      const Spacer(),
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: _ocpGreen,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          // Filtre statut
          PopupMenuButton<String>(
            icon: Icon(
              _statutFilter != 'TOUS'
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              color: _statutFilter != 'TOUS' ? _ocpGreen : _ocpGrey,
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              setState(() {
                _statutFilter = v;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'TOUS',
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive_rounded,
                      size: 18,
                      color: _statutFilter == 'TOUS' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text('Tous'),
                  ],
                ),
              ),
              ...Fuite.statuts.entries.map(
                (e) => PopupMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(
                        _statutIcon(e.key),
                        size: 18,
                        color: _statutFilter == e.key
                            ? _statutColor(e.key)
                            : _ocpGrey,
                      ),
                      const SizedBox(width: 10),
                      Text(e.value),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Liste des fuites ─────────────────────────────────
  Widget _buildFuitesList() {
    if (_filteredFuites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.water_drop_outlined,
              size: 64,
              color: _ocpGreen.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucune fuite trouvée'
                  : 'Aucune fuite dans cette campagne',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _ocpBlack,
              ),
            ),
            if (!_campagne.estCloturee) ...[
              const SizedBox(height: 6),
              Text(
                'Ajoute ta première fuite !',
                style: TextStyle(color: _ocpGrey, fontSize: 13),
              ),
            ],
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: _ocpGreen,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          itemCount: _filteredFuites.length,
          itemBuilder: (context, index) =>
              _buildFuiteCard(_filteredFuites[index]),
        ),
      ),
    );
  }

  // ─── Carte Fuite ──────────────────────────────────────
  Widget _buildFuiteCard(Fuite fuite) {
    final isSelected = _selectedIds.contains(fuite.id);
    final statutLabel = Fuite.statuts[fuite.statut] ?? fuite.statut;
    final statutClr = _statutColor(fuite.statut);
    final statutIcn = _statutIcon(fuite.statut);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? _ocpLightGreen : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _selectionMode
              ? () => _toggleSelection(fuite.id)
              : () => _modifierFuite(fuite),
          onLongPress: () => _toggleSelection(fuite.id),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? _ocpGreen : Colors.black12,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_selectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => _toggleSelection(fuite.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? _ocpGreen
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? _ocpGreen : _ocpGrey,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.tag_rounded, size: 14, color: _ocpGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              fuite.numeroTag ?? 'Sans tag',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _ocpBlack,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPerteBadge(fuite),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: _ocpGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(fuite.dateDetection),
                      style: TextStyle(color: _ocpGrey, fontSize: 11),
                    ),
                    if (fuite.zone != null && fuite.zone!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: _ocpGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fuite.zone!,
                          style: TextStyle(color: _ocpGrey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // ── Badge statut cliquable ──
                    PopupMenuButton<String>(
                      onSelected: (nouveauStatut) async {
                        if (nouveauStatut == fuite.statut) return;
                        try {
                          await fuite_api.updateFuite(
                            id: fuite.id,
                            statut: nouveauStatut,
                            dateDetection: fuite.dateDetection,
                            campagneId: fuite.campagneId,
                          );
                          _loadData();
                          _showSnackBar('Statut mis à jour ✓');
                        } catch (e) {
                          _showSnackBar('Erreur : ${e.toString()}');
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      offset: const Offset(0, 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statutClr.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statutIcn, size: 12, color: statutClr),
                            const SizedBox(width: 3),
                            Text(
                              statutLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statutClr,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 14,
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
                                      fontWeight: entry.key == fuite.statut
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: entry.key == fuite.statut
                                          ? _statutColor(entry.key)
                                          : null,
                                    ),
                                  ),
                                  if (entry.key == fuite.statut) ...[
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
                  ],
                ),
                if (fuite.description != null &&
                    fuite.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 12,
                        color: _ocpGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          fuite.description!,
                          style: TextStyle(color: _ocpGrey, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                // ── Photos ──
                _FuiteCardPhotos(fuiteId: fuite.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Badge d'estimation de perte annuelle (valeur stockée en DB)
  Widget _buildPerteBadge(Fuite fuite) {
    final coutAnnuel = fuite.coutAnnuelEstime;

    if (coutAnnuel == null || coutAnnuel <= 0) {
      return const SizedBox.shrink();
    }

    final couleur = coutAnnuel > 50000
        ? Colors.red.shade700
        : coutAnnuel > 20000
        ? Colors.orange.shade800
        : const Color(0xFF00875A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.money_rounded, size: 12, color: couleur),
          const SizedBox(width: 4),
          Text(
            '${DebitService.formater(coutAnnuel)} MAD/an',
            style: TextStyle(
              color: couleur,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche les miniatures des photos d'une fuite dans la carte.
class _FuiteCardPhotos extends StatelessWidget {
  final int fuiteId;
  const _FuiteCardPhotos({required this.fuiteId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Photo>>(
      future: photo_api.getPhotosByFuite(fuiteId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final photos = snapshot.data!;
        final displayCount = photos.length > 4 ? 4 : photos.length;
        final extraCount = photos.length - 4;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (int i = 0; i < displayCount; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: GestureDetector(
                      onTap: () =>
                          _showPreview(context, photos[i].cheminFichier),
                      child: _buildCardThumbnail(photos[i]),
                    ),
                  ),
                ],
                if (extraCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '+$extraCount',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPreview(BuildContext context, String path) {
    final ext = path.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);

    if (isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _VideoPlayerScreen(path: path)),
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
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
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
          ],
        ),
      ),
    );
  }
}

/// Miniature avec indicateur vidéo pour les cartes fuites.
Widget _buildCardThumbnail(Photo photo) {
  final ext = photo.cheminFichier.split('.').last.toLowerCase();
  final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);

  if (isVideo) {
    final thumbPath = '${photo.cheminFichier}.thumb.jpg';
    return Stack(
      children: [
        Image.file(
          File(thumbPath),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 56,
            height: 56,
            color: Colors.grey.shade900,
            child: const Icon(
              Icons.movie_rounded,
              size: 28,
              color: Colors.white38,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  return Stack(
    children: [
      Image.file(
        File(photo.cheminFichier),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 56,
          height: 56,
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.broken_image_rounded,
            size: 20,
            color: Colors.grey,
          ),
        ),
      ),
    ],
  );
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
