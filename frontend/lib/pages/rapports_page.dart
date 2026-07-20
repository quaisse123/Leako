// 📊 Page Rapports & Analyses
// Badges de période + Checklist métriques + Shimmer + Affichage complet

import 'package:flutter/material.dart';
import '../api/rapport_api.dart' as rapport_api;
import '../widgets/pie_chart_widget.dart';
import '../api/rapport_api.dart' as api;
import 'pdf_viewer_page.dart';

class RapportsPage extends StatefulWidget {
  final int utilisateurId;
  final int? projetId;

  const RapportsPage({super.key, required this.utilisateurId, this.projetId});

  @override
  State<RapportsPage> createState() => _RapportsPageState();
}

class _RapportsPageState extends State<RapportsPage> {
  // ─── Constantes OCP ───
  static const Color _ocpGreen = Color(0xFF00875A);
  static const Color _ocpDarkGreen = Color(0xFF005C3E);
  static const Color _ocpBlack = Color(0xFF111111);
  static const Color _ocpGrey = Color(0xFF757575);
  static const Color _ocpLightGrey = Color(0xFFF5F5F5);
  static const Color _red = Color(0xFFD32F2F);
  static const Color _redBg = Color(0xFFFFEBEE);
  static const Color _greenBg = Color(0xFFE8F5E9);
  static const Color _orange = Color(0xFFF57C00);
  static const Color _orangeBg = Color(0xFFFFF3E0);
  static const Color _blue = Color(0xFF1565C0);

  // ─── Périodes ───
  static const List<_Periode> _periodes = [
    _Periode('ALL', 'Tout'),
    _Periode('1M', '1 mois'),
    _Periode('3M', '3 mois'),
    _Periode('6M', '6 mois'),
    _Periode('1Y', '1 an'),
  ];

  // ─── Métriques ───
  static const List<_MetricDef> _toutesLesMetrics = [
    _MetricDef('top_priority', '💰', 'Pertes vs Économies'),
    _MetricDef('nb_campagnes', '📊', 'Nombre de fuites par campagne'),
    _MetricDef('pertes_campagnes', '💸', 'Pertes vs Économies par campagne'),
    _MetricDef('cout_statut', '📋', 'Coût par statut'),
    _MetricDef('taux_reparation', '✅', 'Taux de réparation'),
    _MetricDef('top5_actives', '🔴', 'Top 5 fuites actives'),
    _MetricDef('top5_reparees', '🟢', 'Top 5 fuites réparées'),
    _MetricDef('diagrammes', '🥧', 'Diagrammes circulaires'),
  ];

  // ─── State ───
  String _periodeSelectionnee = 'ALL';
  final Set<String> _metricsVisibles = _toutesLesMetrics
      .map((m) => m.id)
      .toSet();
  api.RapportResponse? _rapport;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerRapport();
  }

  Future<void> _chargerRapport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = widget.projetId != null
          ? await rapport_api.getRapportByProjet(
              projetId: widget.projetId!,
              periode: _periodeSelectionnee,
            )
          : await rapport_api.getRapport(
              utilisateurId: widget.utilisateurId,
              periode: _periodeSelectionnee,
            );
      if (mounted) {
        setState(() {
          _rapport = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur : ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rapports & Analyses',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _ocpBlack,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: _ocpBlack),
        actions: [
          // ── Bouton filtres métriques ──
          PopupMenuButton(
            icon: const Icon(Icons.tune_rounded, color: _ocpBlack),
            tooltip: 'Métriques à afficher',
            onSelected: (_) {},
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                height: 40,
                child: Text(
                  'Métriques à inclure',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _ocpGrey,
                    fontSize: 13,
                  ),
                ),
              ),
              ..._toutesLesMetrics.map(
                (m) => PopupMenuItem(
                  height: 44,
                  child: StatefulBuilder(
                    builder: (context, setInnerState) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        m.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: _metricsVisibles.contains(m.id),
                      activeColor: _ocpGreen,
                      onChanged: (checked) {
                        setInnerState(() {
                          if (checked == true) {
                            _metricsVisibles.add(m.id);
                          } else {
                            _metricsVisibles.remove(m.id);
                          }
                        });
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barre de période ──
          _buildPeriodeBar(),
          // ── Séparateur ──
          const Divider(height: 1, color: Colors.black12),
          // ── Contenu ──
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════╗
  // ║  BARRE DE PÉRIODE (Badges)                  ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildPeriodeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: _ocpGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _periodes.map((p) {
                  final selected = _periodeSelectionnee == p.code;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected ? Colors.white : _ocpGrey,
                        ),
                      ),
                      selected: selected,
                      selectedColor: _ocpGreen,
                      backgroundColor: _ocpLightGrey,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        if (_periodeSelectionnee != p.code) {
                          setState(() => _periodeSelectionnee = p.code);
                          _chargerRapport();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════╗
  // ║  CONTENU PRINCIPAL                          ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildContent() {
    if (_loading) return _buildShimmer();
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _red),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: _red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _chargerRapport,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_rapport == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return RefreshIndicator(
      onRefresh: _chargerRapport,
      color: _ocpGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // En-tête période
          _buildPeriodeHeader(),
          const SizedBox(height: 16),

          // TOP PRIORITY
          if (_metricsVisibles.contains('top_priority')) ...[
            _buildTopPriority(),
            const SizedBox(height: 16),
          ],

          // Nombre de fuites par campagne
          if (_metricsVisibles.contains('nb_campagnes')) ...[
            _buildSectionCard(
              icon: Icons.bar_chart_rounded,
              title: 'Nombre de fuites par campagne',
              child: _buildMapList(
                _rapport!.fuitesParCampagne,
                suffixe: ' fuite(s)',
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Pertes vs Économies par campagne
          if (_metricsVisibles.contains('pertes_campagnes')) ...[
            _buildPertesVsEconomiesParCampagne(),
            const SizedBox(height: 12),
          ],

          // Coût par statut
          if (_metricsVisibles.contains('cout_statut')) ...[
            _buildCoutParStatut(),
            const SizedBox(height: 12),
          ],

          // Taux de réparation
          if (_metricsVisibles.contains('taux_reparation')) ...[
            _buildTauxReparation(),
            const SizedBox(height: 12),
          ],

          // Top 5 fuites actives
          if (_metricsVisibles.contains('top5_actives')) ...[
            _buildTop5Liste(
              titre: '🔴 Top 5 fuites actives les plus coûteuses',
              liste: _rapport!.top5Actives,
              accentColor: _red,
            ),
            const SizedBox(height: 12),
          ],

          // Top 5 fuites réparées
          if (_metricsVisibles.contains('top5_reparees')) ...[
            _buildTop5Liste(
              titre: '🟢 Top 5 fuites réparées les plus coûteuses',
              liste: _rapport!.top5Reparees,
              accentColor: _ocpGreen,
            ),
            const SizedBox(height: 12),
          ],

          // Diagrammes circulaires
          if (_metricsVisibles.contains('diagrammes')) ...[
            _buildDiagrammesCirculaires(),
            const SizedBox(height: 12),
          ],

          // Bouton PDF
          const SizedBox(height: 16),
          _buildPdfButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════╗
  // ║  SHIMMER (SQUELETTE DE CHARGEMENT)          ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _shimmerBox(height: 60),
        const SizedBox(height: 16),
        _shimmerRow(),
        const SizedBox(height: 16),
        _shimmerBox(height: 100),
        const SizedBox(height: 12),
        _shimmerBox(height: 80),
        const SizedBox(height: 12),
        _shimmerBox(height: 120),
        const SizedBox(height: 12),
        _shimmerBox(height: 80),
        const SizedBox(height: 12),
        _shimmerBox(height: 100),
      ],
    );
  }

  Widget _shimmerBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _ocpLightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _shimmerRow() {
    return Row(
      children: [
        Expanded(child: _shimmerBox(height: 80)),
        const SizedBox(width: 12),
        Expanded(child: _shimmerBox(height: 80)),
      ],
    );
  }

  // ═══════════════════════════════════════════════╗
  // ║  SECTIONS DU RAPPORT                        ║
  // ╚══════════════════════════════════════════════╝

  Widget _buildPeriodeHeader() {
    final r = _rapport!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _ocpGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            r.periodeLibelle,
            style: const TextStyle(
              color: _ocpDarkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${r.dateDebut} → ${r.dateFin}',
          style: const TextStyle(color: _ocpGrey, fontSize: 12),
        ),
      ],
    );
  }

  // ── TOP PRIORITY ──
  Widget _buildTopPriority() {
    final r = _rapport!;
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.warning_amber_rounded,
            title: 'Coût fuites actives',
            value: _formatCout(r.coutFuitesActives),
            accentColor: _red,
            bgColor: _redBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.savings_rounded,
            title: 'Économies réalisées',
            value: _formatCout(r.economiesRealisees),
            accentColor: _ocpGreen,
            bgColor: _greenBg,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ocpGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _ocpBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'MAD/an',
            style: TextStyle(
              color: _ocpGrey.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── CARTE GÉNÉRIQUE ──
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  fontWeight: FontWeight.w900,
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

  // ── MAP → LISTE ──
  Widget _buildMapList(Map<String, dynamic> map, {String suffixe = ''}) {
    if (map.isEmpty) {
      return const Text('Aucune donnée', style: TextStyle(color: _ocpGrey));
    }
    return Column(
      children: map.entries.map((e) {
        final total = map.values.fold<num>(0, (a, b) => a + b);
        final ratio = total > 0 ? (e.value as num) / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 13, color: _ocpBlack),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${e.value}$suffixe',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _ocpBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.toDouble(),
                  backgroundColor: _ocpLightGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(_ocpGreen),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── PERTES VS ÉCONOMIES PAR CAMPAGNE ──
  Widget _buildPertesVsEconomiesParCampagne() {
    final r = _rapport!;
    final campagnes = r.fuitesParCampagne.keys.toList();
    return _buildSectionCard(
      icon: Icons.compare_arrows_rounded,
      title: 'Pertes vs Économies par campagne',
      child: Column(
        children: campagnes.map((nom) {
          final pertes = r.pertesParCampagne[nom] ?? 0.0;
          final economies = r.economiesParCampagne[nom] ?? 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _ocpBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniBar(label: 'Pertes', value: pertes, color: _red),
                    const SizedBox(width: 12),
                    _buildMiniBar(
                      label: 'Économies',
                      value: economies,
                      color: _ocpGreen,
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniBar({
    required String label,
    required double value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ${_formatCout(value)}',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: _ocpLightGrey,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value > 0 ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── COÛT PAR STATUT ──
  Widget _buildCoutParStatut() {
    final r = _rapport!;
    final labels = {
      'A_REPARER': 'À réparer',
      'EN_COURS': 'En cours',
      'REPAREE': 'Réparée',
      'ANNULEE': 'Annulée',
    };
    final couleurs = {
      'A_REPARER': _red,
      'EN_COURS': _orange,
      'REPAREE': _ocpGreen,
      'ANNULEE': _ocpGrey,
    };
    return _buildSectionCard(
      icon: Icons.pie_chart_rounded,
      title: 'Coût total par statut',
      child: Column(
        children: r.coutParStatut.entries.map((e) {
          final total = r.coutParStatut.values.fold<double>(0, (a, b) => a + b);
          final ratio = total > 0 ? e.value / total : 0.0;
          final label = labels[e.key] ?? e.key;
          final color = couleurs[e.key] ?? _ocpGrey;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13, color: _ocpBlack),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: _ocpLightGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: Text(
                    _formatCout(e.value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _ocpBlack,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── TAUX DE RÉPARATION ──
  Widget _buildTauxReparation() {
    final r = _rapport!;
    return _buildSectionCard(
      icon: Icons.check_circle_rounded,
      title: 'Taux de réparation',
      child: Column(
        children: [
          // Taux global
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: r.tauxReparationGlobal / 100,
                        backgroundColor: _ocpLightGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          r.tauxReparationGlobal >= 50 ? _ocpGreen : _orange,
                        ),
                        strokeWidth: 8,
                      ),
                    ),
                    Text(
                      '${r.tauxReparationGlobal.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _ocpBlack,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _ocpBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.totalFuites} fuites · ${r.top5Reparees.length} réparées',
                      style: const TextStyle(color: _ocpGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.tauxReparationParCampagne.isNotEmpty) ...[
            const Divider(height: 24),
            ...r.tauxReparationParCampagne.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(fontSize: 13, color: _ocpBlack),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: e.value >= 50 ? _greenBg : _orangeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${e.value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: e.value >= 50 ? _ocpGreen : _orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TOP 5 LISTE ──
  Widget _buildTop5Liste({
    required String titre,
    required List<api.FuiteResume> liste,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _ocpBlack,
            ),
          ),
          const SizedBox(height: 12),
          if (liste.isEmpty)
            const Text('Aucune fuite', style: TextStyle(color: _ocpGrey))
          else
            ...liste.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: i < liste.length - 1 ? 8 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.numeroTag ?? 'Sans tag',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _ocpBlack,
                            ),
                          ),
                          Text(
                            f.campagneNom,
                            style: const TextStyle(
                              color: _ocpGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCout(f.coutAnnuelEstime),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── DIAGRAMMES CIRCULAIRES ──
  Widget _buildDiagrammesCirculaires() {
    final r = _rapport!;
    return _buildSectionCard(
      icon: Icons.donut_large_rounded,
      title: 'Répartition par campagne',
      child: Column(
        children: [
          _buildDiagrammeRow(
            icon: Icons.numbers_rounded,
            label: 'Nombre de fuites',
            data: r.repartitionNbrCampagnes.map(
              (k, v) => MapEntry(k, v as num),
            ),
            color: _blue,
          ),
          const SizedBox(height: 16),
          _buildDiagrammeRow(
            icon: Icons.trending_up_rounded,
            label: 'Pertes estimées (MAD)',
            data: r.repartitionPertesCampagnes.map(
              (k, v) => MapEntry(k, v as num),
            ),
            color: _red,
          ),
          const SizedBox(height: 16),
          _buildDiagrammeRow(
            icon: Icons.savings_rounded,
            label: 'Économies (MAD)',
            data: r.repartitionEconomiesCampagnes.map(
              (k, v) => MapEntry(k, v as num),
            ),
            color: _ocpGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagrammeRow({
    required IconData icon,
    required String label,
    required Map<String, num> data,
    required Color color,
  }) {
    final total = data.values.fold<num>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _ocpBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PieChartWidget(data: data),
        const Divider(height: 24),
      ],
    );
  }

  // ── BOUTON PDF ──
  Widget _buildPdfButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _downloadPdf,
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('Visualiser le rapport PDF'),
        style: FilledButton.styleFrom(
          backgroundColor: _ocpDarkGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    final projetId = widget.projetId;
    if (projetId == null) {
      _showSnack('❌ Aucun projet sélectionné');
      return;
    }

    if (!mounted) return;
    // Naviguer vers la page de visualisation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          projetId: projetId,
          periode: _periodeSelectionnee,
          titre: 'Rapport OCP - ${_rapport?.periodeLibelle ?? ''}',
          metrics: _metricsVisibles,
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ═══════════════════════════════════════════════╗
  // ║  UTILITAIRES                                ║
  // ╚══════════════════════════════════════════════╝

  String _formatCout(double valeur) {
    final parties = valeur.toStringAsFixed(0).split('.');
    final intPart = parties[0];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()} MAD';
  }
}

// ─── Structures internes ───

class _Periode {
  final String code;
  final String label;
  const _Periode(this.code, this.label);
}

class _MetricDef {
  final String id;
  final String emoji;
  final String label;
  const _MetricDef(this.id, this.emoji, this.label);
}
