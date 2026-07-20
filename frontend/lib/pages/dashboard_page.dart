import 'package:flutter/material.dart';
import 'package:frontend/api/fuite_api.dart' as fuite_api;
import 'package:frontend/services/debit_service.dart';
import 'package:frontend/models/fuite.dart';
import 'creer_campagne_page.dart';
import 'fuites_page.dart';
import 'gestion_projets_page.dart';

class DashboardPage extends StatefulWidget {
  final int utilisateurId;
  final String nom;
  final String email;
  final int? projetId;

  const DashboardPage({
    super.key,
    required this.utilisateurId,
    required this.nom,
    required this.email,
    this.projetId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color ocpGreen = Color(0xFF00875A);
  static const Color ocpLightGreen = Color(0xFFE8F5E9);
  static const Color ocpBlack = Color(0xFF111111);
  static const Color ocpGrey = Color(0xFF757575);
  static const Color ocpLightGrey = Color(0xFFF5F5F5);

  bool _loading = true;
  List<Fuite> _toutesLesFuites = [];
  List<Fuite> _fuitesRecommandees = [];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _loading = true);

    List<Fuite> toutes = [];
    try {
      if (widget.projetId == null) {
        setState(() => _loading = false);
        return;
      }
      toutes = await fuite_api.getFuites(projetId: widget.projetId);
      toutes.sort((a, b) => b.dateDetection.compareTo(a.dateDetection));
    } catch (e) {
      debugPrint('Erreur chargement fuites dashboard: $e');
    }

    if (mounted) {
      setState(() {
        _toutesLesFuites = toutes;
        _fuitesRecommandees = toutes.take(5).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : widget.projetId == null
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _chargerDonnees,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 20),
                    _buildNouvelleCampagneBtn(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildRecentLeaksTable(),
                  ],
                ),
              ),
            ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  EMPTY STATE — Aucun projet sélectionné       ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: ocpLightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: ocpGreen,
              ),
            ),
            const SizedBox(height: 32),
            // Titre
            const Text(
              'Aucun projet sélectionné',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: ocpBlack,
              ),
            ),
            const SizedBox(height: 12),
            // Sous-titre
            Text(
              'Créez votre premier projet pour commencer\nà surveiller les fuites de vapeur.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: ocpGrey, height: 1.5),
            ),
            const SizedBox(height: 36),
            // Bouton : Créer un projet
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GestionProjetsPage(
                        utilisateurId: widget.utilisateurId,
                        nom: widget.nom,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Créer mon premier projet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ocpGreen,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  HEADER DE BIENVENUE                         ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tableau de bord',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: ocpBlack,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: ocpGreen, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Complexe Industriel de Jorf Lasfar & Safi · OCP',
                style: TextStyle(color: ocpGrey, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  GRILLE DE STATISTIQUES (calculées depuis API)║
  // ╚══════════════════════════════════════════════╝
  Widget _buildStatsGrid() {
    final annee = DateTime.now().year;
    // Calculer les stats depuis la liste des fuites
    final totalFuites = _toutesLesFuites.length;
    final aReparer = _toutesLesFuites
        .where((f) => f.statut == 'A_REPARER')
        .length;
    final enCours = _toutesLesFuites
        .where((f) => f.statut == 'EN_COURS')
        .length;
    final reparees = _toutesLesFuites
        .where((f) => f.statut == 'REPAREE')
        .length;
    final sommeActivesKdh = _toutesLesFuites
        .where((f) => f.statut == 'A_REPARER' || f.statut == 'EN_COURS')
        .fold<double>(0, (sum, f) => sum + (f.coutAnnuelEstime ?? 0));
    final sommeRepareesKdh = _toutesLesFuites
        .where((f) => f.statut == 'REPAREE')
        .fold<double>(0, (sum, f) => sum + (f.coutAnnuelEstime ?? 0));

    return Column(
      children: [
        // Carte 1 : Coût total des fuites actives
        _buildStatCard(
          'Coût fuites actives ($annee)',
          _formatCout(sommeActivesKdh),
          '$aReparer à réparer · $enCours en cours',
          Icons.trending_up_rounded,
          const Color(0xFFD32F2F),
          const Color(0xFFFFEBEE),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FuitesPage(
                utilisateurId: widget.utilisateurId,
                initialStatutFilter: 'ACTIVES',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Carte 2 : Économies réalisées
        _buildStatCard(
          'Économisé ($annee)',
          _formatCout(sommeRepareesKdh),
          '$reparees fuites réparées',
          Icons.savings_rounded,
          ocpGreen,
          ocpLightGreen,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FuitesPage(
                utilisateurId: widget.utilisateurId,
                projetId: widget.projetId,
                initialStatutFilter: 'REPAREE',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Ligne : compteurs par statut
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Fuites actives',
                '${aReparer + enCours}',
                'Total $totalFuites',
                Icons.warning_amber_rounded,
                const Color(0xFFD32F2F),
                const Color(0xFFFFEBEE),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FuitesPage(
                      utilisateurId: widget.utilisateurId,
                      projetId: widget.projetId,
                      initialStatutFilter: 'ACTIVES',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Taux réparation',
                totalFuites > 0
                    ? '${((reparees / totalFuites) * 100).toStringAsFixed(0)} %'
                    : '—',
                '$reparees / $totalFuites',
                Icons.task_alt_rounded,
                ocpGreen,
                ocpLightGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
    Color bgIconColor, {
    VoidCallback? onTap,
  }) {
    final bool isLarge = MediaQuery.of(context).size.width > 900;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 18 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                    style: TextStyle(
                      color: ocpGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: isLarge ? 13 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.all(isLarge ? 8 : 6),
                  decoration: BoxDecoration(
                    color: bgIconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: isLarge ? 20 : 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ocpBlack,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: ocpGrey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  TABLE DES FUITES RÉCENTES (BDD)              ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildRecentLeaksTable() {
    if (_fuitesRecommandees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Center(
          child: Text(
            'Aucune fuite signalée en ${DateTime.now().year}',
            style: const TextStyle(color: ocpGrey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dernières Fuites Signalées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ocpBlack,
                ),
              ),
              Icon(Icons.keyboard_arrow_right_rounded, color: ocpBlack),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(ocpLightGrey),
              horizontalMargin: 12,
              columnSpacing: 20,
              columns: const [
                DataColumn(
                  label: Text(
                    'Tag',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ocpBlack,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Détecté le',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ocpBlack,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Statut',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ocpBlack,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Débit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ocpBlack,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Coût Estimé',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ocpBlack,
                    ),
                  ),
                ),
              ],
              rows: _fuitesRecommandees.map((fuite) {
                final debit =
                    (fuite.pressionBar != null && fuite.diametreOrifice != null)
                    ? DebitService.calculerDebit(
                        pressionRel: fuite.pressionBar!,
                        diametreMm: fuite.diametreOrifice!,
                      )
                    : 0.0;

                // Formater date + heure
                String dateAffichee = '—';
                try {
                  final dt = DateTime.parse(fuite.dateDetection);
                  final mois = dt.month.toString().padLeft(2, '0');
                  final jour = dt.day.toString().padLeft(2, '0');
                  final heures = dt.hour.toString().padLeft(2, '0');
                  final minutes = dt.minute.toString().padLeft(2, '0');
                  dateAffichee = '$jour/$mois/${dt.year} $heures:$minutes';
                } catch (_) {}

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        fuite.numeroTag ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ocpGreen,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(dateAffichee, style: const TextStyle(fontSize: 11)),
                    ),
                    DataCell(_buildStatusBadge(_labelStatut(fuite.statut))),
                    DataCell(
                      Text(
                        '${debit.toStringAsFixed(1)} kg/h',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatCout(fuite.coutAnnuelEstime ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Formate un coût en MAD de façon intelligente :
  /// - < 1 000 → "X MAD"
  /// - < 1 000 000 → "X XXX kMAD"
  /// - < 1 000 000 000 → "X,XX M MAD"
  /// - >= 1 000 000 000 → "X,XX Md MAD"
  /// Avec séparateur de milliers (espace).
  String _formatCout(double valeur) {
    if (valeur < 1000) {
      return '${valeur.toStringAsFixed(0)} MAD';
    } else if (valeur < 1_000_000) {
      final milliers = (valeur / 1000).toStringAsFixed(0);
      // Ajouter séparateur de milliers
      final buf = StringBuffer();
      for (var i = 0; i < milliers.length; i++) {
        if (i > 0 && (milliers.length - i) % 3 == 0) buf.write(' ');
        buf.write(milliers[i]);
      }
      return '$buf kMAD';
    } else if (valeur < 1_000_000_000) {
      final millions = valeur / 1_000_000;
      return '${millions.toStringAsFixed(2)} M MAD';
    } else {
      final milliards = valeur / 1_000_000_000;
      return '${milliards.toStringAsFixed(2)} Md MAD';
    }
  }

  String _labelStatut(String? statut) {
    switch (statut) {
      case 'A_REPARER':
        return 'À réparer';
      case 'EN_COURS':
        return 'En cours';
      case 'REPAREE':
        return 'Réparée';
      case 'ANNULEE':
        return 'Annulée';
      default:
        return statut ?? '—';
    }
  }

  Widget _buildStatusBadge(String statut) {
    Color bgColor;
    Color textColor;

    switch (statut) {
      case 'Réparée':
        bgColor = ocpLightGreen;
        textColor = ocpGreen;
        break;
      case 'En cours':
        bgColor = const Color(0xFFFFF9C4);
        textColor = const Color(0xFFF57F17);
        break;
      case 'À réparer':
      default:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statut,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════════╗
  // ║  BOUTON NOUVELLE CAMPAGNE                    ║
  // ╚══════════════════════════════════════════════╝
  Widget _buildNouvelleCampagneBtn() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreerCampagnePage(
              utilisateurId: widget.utilisateurId,
              projetId: widget.projetId,
            ),
          ),
        );
      },
      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
      label: const Text(
        'Lancer une campagne',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ocpGreen,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
