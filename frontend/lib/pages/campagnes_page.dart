// 📋 Page Campagnes — Gestion complète des campagnes d'inspection
// CRUD, recherche, sélection multiple, tri, statistiques
// Design moderne OCP — thème dashboard

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/campagne.dart';
import '../services/local_db_service.dart';
import 'creer_campagne_page.dart';
import 'detail_campagne_page.dart';

class CampagnesPage extends StatefulWidget {
  final int utilisateurId;

  const CampagnesPage({super.key, required this.utilisateurId});

  @override
  State<CampagnesPage> createState() => _CampagnesPageState();
}

class _CampagnesPageState extends State<CampagnesPage>
    with SingleTickerProviderStateMixin {
  // ─── Services & Données ───────────────────────────────
  final LocalDbService _db = LocalDbService();
  List<Campagne> _allCampagnes = [];
  List<Campagne> _filteredCampagnes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ─── Recherche & Filtres ──────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showActiveOnly = false;
  String _sortBy = 'date'; // 'date' | 'nom' | 'statut'

  // ─── Sélection multiple ───────────────────────────────
  final Set<int> _selectedIds = {};
  bool _selectionMode = false;

  // ─── Animation ────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ─── Couleurs ─────────────────────────────────────────
  static const Color _ocpGreen = Color(0xFF00875A);
  // static const Color _ocpDarkGreen = Color(0xFF005C3E);
  static const Color _ocpLightGreen = Color(0xFFE8F5E9);
  static const Color _ocpBlack = Color(0xFF111111);
  static const Color _ocpGrey = Color(0xFF757575);
  static const Color _ocpLightGrey = Color(0xFFF5F5F5);
  static const Color _ocpRed = Color(0xFFD32F2F);
  static const Color _ocpBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(_onSearchChanged);
    _loadCampagnes();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Chargement ───────────────────────────────────────
  Future<void> _loadCampagnes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await _db.getCampagnes(widget.utilisateurId);
      if (!mounted) return;
      setState(() {
        _allCampagnes = rows.map((row) => Campagne.fromMap(row)).toList();
        _applyFilters();
        _isLoading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur lors du chargement des campagnes.';
        _isLoading = false;
      });
    }
  }

  // ─── Filtrage & Recherche ─────────────────────────────
  void _onSearchChanged() {
    setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    _applyFilters();
  }

  void _applyFilters() {
    var result = List<Campagne>.from(_allCampagnes);

    // Filtre actif/clôturé
    if (_showActiveOnly) {
      result = result.where((c) => !c.estCloturee).toList();
    }

    // Recherche textuelle
    if (_searchQuery.isNotEmpty) {
      result = result.where((c) {
        final nom = c.nom.toLowerCase();
        final desc = c.description?.toLowerCase() ?? '';
        final zone = c.zone?.toLowerCase() ?? '';
        return nom.contains(_searchQuery) ||
            desc.contains(_searchQuery) ||
            zone.contains(_searchQuery);
      }).toList();
    }

    // Tri
    switch (_sortBy) {
      case 'nom':
        result.sort((a, b) => a.nom.compareTo(b.nom));
        break;
      case 'statut':
        result.sort(
          (a, b) => (a.estCloturee ? 1 : 0).compareTo(b.estCloturee ? 1 : 0),
        );
        break;
      default: // date
        result.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
    }

    _filteredCampagnes = result;
  }

  // ─── CRUD ─────────────────────────────────────────────
  Future<void> _creerCampagne() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreerCampagnePage(utilisateurId: widget.utilisateurId),
      ),
    );
    if (created == true) _loadCampagnes();
  }

  Future<void> _voirCampagne(Campagne campagne) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DetailCampagnePage(
          campagne: campagne,
          utilisateurId: widget.utilisateurId,
        ),
      ),
    );
    if (changed == true) _loadCampagnes();
  }

  Future<void> _modifierCampagne(Campagne campagne) async {
    final nomCtrl = TextEditingController(text: campagne.nom);
    final descCtrl = TextEditingController(text: campagne.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool estCloturee = campagne.estCloturee;

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
                    // ── En-tête ──
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

                    // ── Nom ──
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

                    // ── Description ──
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

                    // ── Statut ──
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

                    // ── Bouton plein écran ──
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
        await _db.updateCampagne(campagne.id, {
          'nom': nomCtrl.text.trim(),
          'description': descCtrl.text.trim().isEmpty
              ? null
              : descCtrl.text.trim(),
          'est_cloturee': estCloturee ? 1 : 0,
        });
        _loadCampagnes();
        _showActionSnackBar('Campagne modifiée ✓');
      } catch (e) {
        _showActionSnackBar('Erreur : ${e.toString()}');
      }
    }
    nomCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _supprimerCampagne(Campagne campagne) async {
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
              '« ${campagne.nom} »\nToutes les fuites, photos et données associées seront définitivement supprimées.',
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.supprimerCampagne(campagne.id);
        _loadCampagnes();
        _showActionSnackBar('Campagne supprimée ✓');
      } catch (e) {
        _showActionSnackBar('Erreur : ${e.toString()}');
      }
    }
  }

  Future<void> _basculerStatut(Campagne campagne) async {
    final newStatut = !campagne.estCloturee;
    await _db.updateCampagne(campagne.id, {'est_cloturee': newStatut ? 1 : 0});
    _loadCampagnes();
    _showActionSnackBar(
      newStatut ? 'Campagne clôturée ✓' : 'Campagne réouverte ✓',
    );
  }

  // ─── Sélection multiple ───────────────────────────────
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

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _filteredCampagnes.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(_filteredCampagnes.map((c) => c.id));
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
              '${_selectedIds.length} campagne(s) seront définitivement supprimées.',
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
        for (final id in _selectedIds) {
          await _db.supprimerCampagne(id);
        }
        _clearSelection();
        _loadCampagnes();
        _showActionSnackBar(
          '${_selectedIds.length} campagne(s) supprimée(s) ✓',
        );
      } catch (e) {
        _showActionSnackBar('Erreur : ${e.toString()}');
      }
    }
  }

  Future<void> _cloturerSelection() async {
    if (_selectedIds.isEmpty) return;
    try {
      for (final id in _selectedIds) {
        await _db.updateCampagne(id, {'est_cloturee': 1});
      }
      _clearSelection();
      _loadCampagnes();
      _showActionSnackBar('${_selectedIds.length} campagne(s) clôturée(s) ✓');
    } catch (e) {
      _showActionSnackBar('Erreur : ${e.toString()}');
    }
  }

  // ─── Helpers UI ───────────────────────────────────────
  void _showActionSnackBar(String message) {
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
            Text(message),
          ],
        ),
        backgroundColor: _ocpGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
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

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_selectionMode) _buildSelectionBar(),
          _buildSearchAndFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _creerCampagne,
              backgroundColor: _ocpGreen,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nouvelle campagne',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campagnes',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _ocpBlack,
              fontSize: 22,
            ),
          ),
          Text(
            '${_filteredCampagnes.length} campagne${_filteredCampagnes.length > 1 ? 's' : ''}',
            style: TextStyle(color: _ocpGrey, fontSize: 12),
          ),
        ],
      ),
      actions: [
        if (_selectionMode)
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _clearSelection,
            tooltip: 'Annuler la sélection',
          )
        else ...[
          IconButton(
            icon: Icon(
              _showActiveOnly
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              color: _showActiveOnly ? _ocpGreen : null,
            ),
            onPressed: () => setState(() {
              _showActiveOnly = !_showActiveOnly;
              _applyFilters();
            }),
            tooltip: _showActiveOnly ? 'Filtrer : actives' : 'Filtrer : toutes',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Trier par',
            onSelected: (value) => setState(() {
              _sortBy = value;
              _applyFilters();
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: _sortBy == 'date' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: _sortBy == 'date'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'nom',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha_rounded,
                      size: 18,
                      color: _sortBy == 'nom' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Nom',
                      style: TextStyle(
                        fontWeight: _sortBy == 'nom'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'statut',
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 18,
                      color: _sortBy == 'statut' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Statut',
                      style: TextStyle(
                        fontWeight: _sortBy == 'statut'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadCampagnes,
            tooltip: 'Rafraîchir',
          ),
        ],
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
          // Tout sélectionner / désélectionner
          GestureDetector(
            onTap: _selectAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: _ocpGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedIds.length == _filteredCampagnes.length
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 16,
                    color: _ocpGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedIds.length == _filteredCampagnes.length
                        ? 'Tout désél.'
                        : 'Tout sél.',
                    style: const TextStyle(
                      color: _ocpGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedIds.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              height: 20,
              width: 1,
              color: _ocpGreen.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 6),
            // Clôturer
            GestureDetector(
              onTap: _cloturerSelection,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _ocpGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: _ocpGreen,
                ),
              ),
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
          ],
        ],
      ),
    );
  }

  // ─── Barre de recherche ───────────────────────────────
  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: _ocpBlack, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher une campagne…',
          hintStyle: TextStyle(color: _ocpGrey.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.search_rounded, color: _ocpGrey, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: _ocpLightGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _ocpGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ─── Corps ────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _ocpGreen),
            SizedBox(height: 16),
            Text(
              'Chargement des campagnes…',
              style: TextStyle(color: _ocpGrey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: _ocpGrey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ocpGrey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCampagnes,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ocpGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredCampagnes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.campaign_outlined,
                size: 72,
                color: _ocpGreen.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Aucune campagne trouvée'
                    : 'Aucune campagne pour le moment',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _ocpBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Essaie un autre mot-clé'
                    : 'Lance ta première inspection !',
                style: TextStyle(color: _ocpGrey),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _loadCampagnes,
        color: _ocpGreen,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          itemCount: _filteredCampagnes.length,
          itemBuilder: (context, index) {
            return _buildCampagneCard(_filteredCampagnes[index]);
          },
        ),
      ),
    );
  }

  // ─── Carte Campagne ───────────────────────────────────
  Widget _buildCampagneCard(Campagne campagne) {
    final isSelected = _selectedIds.contains(campagne.id);
    final isActive = !campagne.estCloturee;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? _ocpLightGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _selectionMode
              ? () => _toggleSelection(campagne.id)
              : () => _voirCampagne(campagne),
          onLongPress: () => _toggleSelection(campagne.id),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _ocpGreen : Colors.black12,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1 : Checkbox + Nom + Badge ──
                Row(
                  children: [
                    if (_selectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => _toggleSelection(campagne.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
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
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        campagne.nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _ocpBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatutBadge(isActive),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Row 2 : Description ──
                if (campagne.description != null &&
                    campagne.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      campagne.description!,
                      style: TextStyle(
                        color: _ocpGrey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // ── Row 3 : Métadonnées ──
                Row(
                  children: [
                    _buildMetaChip(
                      Icons.calendar_today_rounded,
                      _formatDateTime(campagne.dateCreation),
                    ),
                    const SizedBox(width: 16),
                    _buildMetaChip(
                      Icons.water_drop_rounded,
                      '${campagne.nombreFuites} fuite${campagne.nombreFuites > 1 ? 's' : ''}',
                    ),
                    if (campagne.zone != null && campagne.zone!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      _buildMetaChip(Icons.location_on_rounded, campagne.zone!),
                    ],
                  ],
                ),

                // ── Row 4 : Actions (hors mode sélection) ──
                if (!_selectionMode) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Modifier',
                        color: _ocpBlue,
                        onTap: () => _modifierCampagne(campagne),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: isActive
                            ? Icons.lock_outline_rounded
                            : Icons.lock_open_rounded,
                        label: isActive ? 'Clôturer' : 'Réouvrir',
                        color: isActive ? _ocpGreen : _ocpGrey,
                        onTap: () => _basculerStatut(campagne),
                      ),
                      const Spacer(),
                      _buildActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: '',
                        color: _ocpRed,
                        onTap: () => _supprimerCampagne(campagne),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatutBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE3F2FD) : _ocpLightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _ocpBlue : _ocpGrey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Clôturée',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? _ocpBlue : _ocpGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _ocpGreen),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: _ocpGrey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Petit label de champ de formulaire (même style que CreerCampagnePage)
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _ocpBlack,
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
}
