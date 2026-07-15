// 💧 Page Fuites — Gestion complète des fuites d'inspection
// CRUD, recherche, filtres, sélection multiple, tri
// Design moderne OCP — thème dashboard

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/fuite.dart';
import '../models/photo.dart';
import '../services/debit_service.dart';
import '../api/fuite_api.dart' as fuite_api;
import '../api/photo_api.dart' as photo_api;
import '../api/api_config.dart';
import '../widgets/photo_editor_widget.dart';
import 'creer_fuite_page.dart';
import 'modifier_fuite_page.dart';

String _photoUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  var base = ApiConfig.apiBaseUrl;
  if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
  if (!base.endsWith('/')) base = '$base/';
  if (path.startsWith('/')) path = path.substring(1);
  return '$base$path';
}

class FuitesPage extends StatefulWidget {
  final int utilisateurId;
  final String? initialStatutFilter;

  const FuitesPage({
    super.key,
    required this.utilisateurId,
    this.initialStatutFilter,
  });

  @override
  State<FuitesPage> createState() => _FuitesPageState();
}

class _FuitesPageState extends State<FuitesPage>
    with SingleTickerProviderStateMixin {
  // ─── Services & Données ───────────────────────────────
  List<Fuite> _allFuites = [];
  List<Fuite> _filteredFuites = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _photoRefreshKey = 0;

  // ─── Recherche & Filtres ──────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statutFilter = 'TOUS';
  String _sortBy = 'cout'; // 'cout' | 'date' | 'statut' | 'campagne'

  // ─── Sélection multiple ───────────────────────────────
  final Set<int> _selectedIds = {};
  bool _selectionMode = false;

  // ─── Animation ────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

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
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _searchCtrl.addListener(_onSearchChanged);
    if (widget.initialStatutFilter != null) {
      _statutFilter = widget.initialStatutFilter!;
    }
    _loadFuites();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Chargement ───────────────────────────────────────
  Future<void> _loadFuites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fuites = await fuite_api.getFuitesByUtilisateur(
        widget.utilisateurId,
      );
      if (!mounted) return;
      setState(() {
        _allFuites = fuites;
        _applyFilters();
        _isLoading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur lors du chargement des fuites.';
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
    var result = List<Fuite>.from(_allFuites);

    // Filtre par statut
    if (_statutFilter == 'ACTIVES') {
      result = result
          .where((f) => f.statut == 'A_REPARER' || f.statut == 'EN_COURS')
          .toList();
    } else if (_statutFilter != 'TOUS') {
      result = result.where((f) => f.statut == _statutFilter).toList();
    }

    // Recherche textuelle
    if (_searchQuery.isNotEmpty) {
      result = result.where((f) {
        final tag = f.numeroTag?.toLowerCase() ?? '';
        final zone = f.zone?.toLowerCase() ?? '';
        final desc = f.description?.toLowerCase() ?? '';
        final campagne = f.campagneNom?.toLowerCase() ?? '';
        final typeVapeur = Fuite.typesVapeur[f.typeVapeur]?.toLowerCase() ?? '';
        return tag.contains(_searchQuery) ||
            zone.contains(_searchQuery) ||
            desc.contains(_searchQuery) ||
            campagne.contains(_searchQuery) ||
            typeVapeur.contains(_searchQuery);
      }).toList();
    }

    // Tri
    switch (_sortBy) {
      case 'statut':
        result.sort((a, b) => a.statut.compareTo(b.statut));
        break;
      case 'campagne':
        result.sort(
          (a, b) => (a.campagneNom ?? '').compareTo(b.campagneNom ?? ''),
        );
        break;
      case 'date':
        result.sort((a, b) {
          final dateA = DateTime.tryParse(a.dateDetection) ?? DateTime(0);
          final dateB = DateTime.tryParse(b.dateDetection) ?? DateTime(0);
          return dateB.compareTo(dateA);
        });
        break;
      default: // cout — plus coûteux en premier
        result.sort((a, b) {
          final coutA = a.coutAnnuelEstime ?? 0;
          final coutB = b.coutAnnuelEstime ?? 0;
          return coutB.compareTo(coutA);
        });
    }

    _filteredFuites = result;
  }

  // ─── CRUD ─────────────────────────────────────────────
  Future<void> _creerFuite() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreerFuitePage(utilisateurId: widget.utilisateurId),
      ),
    );
    if (created == true) _loadFuites();
  }

  Future<void> _modifierFuite(Fuite fuite) async {
    final modified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => ModifierFuitePage(fuite: fuite)),
    );
    if (modified == true) _loadFuites();
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
      if (_selectedIds.length == _filteredFuites.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(_filteredFuites.map((f) => f.id));
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
        _loadFuites();
        _showActionSnackBar('${ids.length} fuite(s) supprimée(s) ✓');
      } catch (e) {
        _showActionSnackBar('Erreur : ${e.toString()}');
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
          numeroTag: fuite.numeroTag,
          statut: nouveauStatut,
          dateDetection: fuite.dateDetection,
          pressionBar: fuite.pressionBar,
          diametreOrifice: fuite.diametreOrifice,
          typeVapeur: fuite.typeVapeur,
          gpsLatitude: fuite.gpsLatitude,
          gpsLongitude: fuite.gpsLongitude,
          zone: fuite.zone,
          description: fuite.description,
          coutAnnuelEstime: fuite.coutAnnuelEstime,
          campagneId: fuite.campagneId,
        );
      }
      _loadFuites();
      _showActionSnackBar('${_selectedIds.length} fuite(s) mise(s) à jour ✓');
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
              onPressed: _creerFuite,
              backgroundColor: _ocpGreen,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nouvelle fuite',
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
            'Fuites',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _ocpBlack,
              fontSize: 22,
            ),
          ),
          Text(
            '${_filteredFuites.length} fuite${_filteredFuites.length > 1 ? 's' : ''}',
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
          PopupMenuButton<String>(
            icon: Icon(
              _statutFilter != 'TOUS'
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              color: _statutFilter != 'TOUS' ? _ocpGreen : null,
            ),
            tooltip: 'Filtrer par statut',
            onSelected: (value) {
              setState(() {
                _statutFilter = value;
                _applyFilters();
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                    Text(
                      'Tous',
                      style: TextStyle(
                        fontWeight: _statutFilter == 'TOUS'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              ...Fuite.statuts.entries.map((entry) {
                final isSelected = _statutFilter == 'ACTIVES'
                    ? (entry.key == 'A_REPARER' || entry.key == 'EN_COURS')
                    : _statutFilter == entry.key;
                return PopupMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        _statutIcon(entry.key),
                        size: 18,
                        color: isSelected ? _statutColor(entry.key) : _ocpGrey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
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
                value: 'cout',
                child: Row(
                  children: [
                    Icon(
                      Icons.money_rounded,
                      size: 18,
                      color: _sortBy == 'cout' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Coût',
                      style: TextStyle(
                        fontWeight: _sortBy == 'cout'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
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
              PopupMenuItem(
                value: 'campagne',
                child: Row(
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      size: 18,
                      color: _sortBy == 'campagne' ? _ocpGreen : _ocpGrey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Campagne',
                      style: TextStyle(
                        fontWeight: _sortBy == 'campagne'
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
            onPressed: _loadFuites,
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
                    _selectedIds.length == _filteredFuites.length
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 16,
                    color: _ocpGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedIds.length == _filteredFuites.length
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
            // Menu statut
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
                child: const Icon(
                  Icons.loop_rounded,
                  size: 18,
                  color: _ocpBlue,
                ),
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
          hintText: 'Rechercher tag, localisation, gaz…',
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
            Text('Chargement des fuites…', style: TextStyle(color: _ocpGrey)),
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
                onPressed: _loadFuites,
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

    if (_filteredFuites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.water_drop_outlined,
                size: 72,
                color: _ocpGreen.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Aucune fuite trouvée'
                    : 'Aucune fuite signalée',
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
                    : 'Ajoute ta première fuite !',
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
        onRefresh: _loadFuites,
        color: _ocpGreen,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          itemCount: _filteredFuites.length,
          itemBuilder: (context, index) {
            return _buildFuiteCard(_filteredFuites[index]);
          },
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
                            numeroTag: fuite.numeroTag,
                            statut: nouveauStatut,
                            dateDetection: fuite.dateDetection,
                            pressionBar: fuite.pressionBar,
                            diametreOrifice: fuite.diametreOrifice,
                            typeVapeur: fuite.typeVapeur,
                            gpsLatitude: fuite.gpsLatitude,
                            gpsLongitude: fuite.gpsLongitude,
                            zone: fuite.zone,
                            description: fuite.description,
                            coutAnnuelEstime: fuite.coutAnnuelEstime,
                            campagneId: fuite.campagneId,
                          );
                          _loadFuites();
                          _showActionSnackBar('Statut mis à jour ✓');
                        } catch (e) {
                          _showActionSnackBar('Erreur : ${e.toString()}');
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
                _FuiteCardPhotos(
                  fuiteId: fuite.id,
                  refreshKey: _photoRefreshKey,
                  onPhotoEdited: () {
                    setState(() => _photoRefreshKey++);
                  },
                ),
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

/// Widget qui affiche les miniatures des photos d'une fuite dans la carte.
class _FuiteCardPhotos extends StatelessWidget {
  final int fuiteId;
  final int refreshKey;
  final VoidCallback? onPhotoEdited;
  const _FuiteCardPhotos({
    required this.fuiteId,
    required this.refreshKey,
    this.onPhotoEdited,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Photo>>(
      key: ValueKey('photos_${fuiteId}_$refreshKey'),
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
                      onTap: () => _showPreview(context, photos[i]),
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

  void _showPreview(BuildContext context, Photo photo) {
    final path = photo.cheminFichier;
    final ext = path.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
    final isTemp = !path.startsWith('/') && !path.startsWith('http');

    if (isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _VideoPlayerScreen(path: isTemp ? path : _photoUrl(path)),
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
            // Bouton éditer — utilise le helper centralisé
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await editPhoto(
                    context,
                    photo: photo,
                    photoUrl: _photoUrl,
                    onSaved: onPhotoEdited,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Éditer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
  final isTemp = photo.id < 0;

  if (isVideo) {
    final hasThumb =
        photo.thumbnailUrl != null && photo.thumbnailUrl!.isNotEmpty;
    return Stack(
      children: [
        if (isTemp)
          Image.file(
            File(photo.cheminFichier),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildVideoPlaceholder(),
          )
        else if (hasThumb)
          CachedNetworkImage(
            imageUrl: _photoUrl(photo.thumbnailUrl!),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (_, _) => _buildVideoPlaceholder(),
            errorWidget: (_, _, _) => _buildVideoPlaceholder(),
          )
        else
          _buildVideoPlaceholder(),
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
      isTemp
          ? Image.file(
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
            )
          : CachedNetworkImage(
              imageUrl: _photoUrl(photo.cheminFichier),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  Container(width: 56, height: 56, color: Colors.grey.shade200),
              errorWidget: (_, _, _) => Container(
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

Widget _buildVideoPlaceholder() {
  return Container(
    width: 56,
    height: 56,
    color: Colors.grey.shade900,
    child: const Icon(Icons.movie_rounded, size: 28, color: Colors.white38),
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
    final isNetwork = widget.path.startsWith('http');
    _controller = isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));
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
