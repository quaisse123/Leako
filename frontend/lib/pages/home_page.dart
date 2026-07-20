// 🏠 Page principale avec GNAV design + Drawer global
// Barre de navigation inspirée du Material 3 avec style OCP

import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'campagnes_page.dart';
import 'fuites_page.dart';
import 'config_page.dart';
import 'rapports_page.dart';
import 'gestion_projets_page.dart';
import 'login_page.dart';
import '../models/projet.dart';
import '../api/projet_api.dart' as projet_api;
import '../api/jwt_service.dart' as jwt_service;
import '../api/auth_api.dart' as auth_api;

class HomePage extends StatefulWidget {
  final int utilisateurId;
  final String nom;
  final String email;

  const HomePage({
    super.key,
    required this.utilisateurId,
    required this.nom,
    required this.email,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const Color _ocpGreen = Color(0xFF00875A);
  static const Color _ocpDarkGreen = Color(0xFF005C3E);
  static const Color _ocpBlack = Color(0xFF111111);

  late List<Widget> _pages;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.campaign_rounded, label: 'Campagnes'),
    _NavItem(icon: Icons.water_drop_rounded, label: 'Fuites'),
    _NavItem(icon: Icons.analytics_rounded, label: 'Rapports'),
  ];

  // ─── Projet state ───
  List<Projet> _mesProjets = [];
  Projet? _projetActif;
  int _invitationsCount = 0;

  @override
  void initState() {
    super.initState();
    _buildPages();
    _loadProjets();
  }

  void _buildPages() {
    _pages = [
      DashboardPage(
        utilisateurId: widget.utilisateurId,
        nom: widget.nom,
        email: widget.email,
        projetId: _projetActif?.id,
        projetNom: _projetActif?.nom,
        createurNom: _projetActif?.createurNom,
      ),
      CampagnesPage(
        utilisateurId: widget.utilisateurId,
        projetId: _projetActif?.id,
      ),
      FuitesPage(
        utilisateurId: widget.utilisateurId,
        projetId: _projetActif?.id,
      ),
      RapportsPage(
        utilisateurId: widget.utilisateurId,
        projetId: _projetActif?.id,
      ),
    ];
  }

  Future<void> _loadProjets() async {
    try {
      final projets = await projet_api.getMesProjets(widget.utilisateurId);
      final invitations = await projet_api.getMesInvitations(
        widget.utilisateurId,
      );

      if (!mounted) return;
      setState(() {
        _mesProjets = projets;
        _invitationsCount = invitations.length;

        // Si un projet était sélectionné et existe encore, le garder
        if (_projetActif != null) {
          final exists = projets.any((p) => p.id == _projetActif!.id);
          if (!exists) _projetActif = null;
        }
        // Sinon sélectionner le premier si aucun
        if (_projetActif == null && projets.isNotEmpty) {
          _projetActif = projets.first;
        }

        _buildPages();
      });
    } catch (e) {
      // ignore
    }
  }

  void _onProjetChanged() {
    _loadProjets();
  }

  List<Projet> get _mesProjetsCrees =>
      _mesProjets.where((p) => p.createurId == widget.utilisateurId).toList();

  List<Projet> get _mesProjetsMembre =>
      _mesProjets.where((p) => p.createurId != widget.utilisateurId).toList();

  List<DropdownMenuItem<int>> _buildDropdownItems() {
    final items = <DropdownMenuItem<int>>[];
    final crees = _mesProjetsCrees;
    final membre = _mesProjetsMembre;

    // Section : Mes projets
    if (crees.isNotEmpty) {
      items.add(
        DropdownMenuItem<int>(
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              'Mes projets',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
      for (final p in crees) {
        items.add(
          DropdownMenuItem<int>(
            value: p.id,
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: _ocpGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.nom,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _ocpBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Section : Projets membre
    if (membre.isNotEmpty) {
      if (crees.isNotEmpty) {
        items.add(
          const DropdownMenuItem<int>(
            enabled: false,
            child: Divider(height: 1),
          ),
        );
      }
      items.add(
        DropdownMenuItem<int>(
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              'Membre invité',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
      for (final p in membre) {
        items.add(
          DropdownMenuItem<int>(
            value: p.id,
            child: Row(
              children: [
                Icon(Icons.group_rounded, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.nom,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _ocpBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Message si aucun projet
    if (items.isEmpty) {
      items.add(
        const DropdownMenuItem<int>(
          enabled: false,
          child: Text(
            'Aucun projet disponible',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return items;
  }

  void _logout() async {
    await jwt_service.logout();
    await auth_api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 62,
        iconTheme: const IconThemeData(color: _ocpBlack),
        title: Image.asset(
          'assets/images/logo.png',
          height: 48,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.water_drop_rounded,
              color: _ocpGreen,
              size: 24,
            );
          },
        ),
        centerTitle: true,
        actions: [
          // ── Icône invitations ──
          if (_invitationsCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.mail_outline_rounded,
                    color: _ocpBlack,
                  ),
                  onPressed: () => _openGestionProjets(),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_invitationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: KeyedSubtree(
          key: ValueKey('${_currentIndex}_${_projetActif?.id ?? 0}'),
          child: _pages[_currentIndex],
        ),
      ),
      // ═══════════════════════════════════════════
      //  GNAV — Google Navigation Bar design OCP
      // ═══════════════════════════════════════════
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final isSelected = _currentIndex == index;
                final item = _navItems[index];
                return _GnavItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => setState(() => _currentIndex = index),
                );
              }),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // ── Header avec fond dégradé OCP ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_ocpDarkGreen, _ocpGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          widget.nom.isNotEmpty
                              ? widget.nom[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.nom,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Sélecteur de projet ──
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 16,
                        color: Color(0xFF757575),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Projet actif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _projetActif?.id,
                        isExpanded: true,
                        hint: const Text(
                          'Sélectionner un projet',
                          style: TextStyle(fontSize: 14, color: _ocpBlack),
                        ),
                        icon: const Icon(
                          Icons.expand_more_rounded,
                          color: _ocpGreen,
                        ),
                        style: const TextStyle(color: _ocpBlack),
                        dropdownColor: Colors.white,
                        selectedItemBuilder: (context) {
                          return _buildDropdownItems().map((item) {
                            // Trouver le projet correspondant pour afficher son nom
                            final projet = item.value != null
                                ? _mesProjets.cast<Projet?>().firstWhere(
                                    (p) => p?.id == item.value,
                                    orElse: () => null,
                                  )
                                : null;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                projet?.nom ?? 'Sélectionner un projet',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _ocpBlack,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        items: _buildDropdownItems(),
                        onChanged: (id) {
                          if (id == null) return;
                          setState(() {
                            _projetActif = _mesProjets.firstWhere(
                              (p) => p.id == id,
                            );
                            _buildPages();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  if (_projetActif != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Données centralisées • ${_projetActif!.membresCount} membre(s)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // const Divider(height: 1),
            // const SizedBox(height: 4),
            // ── Gestion des projets (juste sous le dropdown) ──
            _DrawerItem(
              icon: Icons.folder_special_rounded,
              label: 'Gérer mes projets',
              isSelected: false,
              trailing: _invitationsCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_invitationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _openGestionProjets();
              },
            ),
            const Divider(height: 1),
            // ── Items de navigation ──
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.dashboard_rounded,
              label: 'Tableau de bord',
              isSelected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.campaign_rounded,
              label: 'Campagnes',
              isSelected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.water_drop_rounded,
              label: 'Fuites signalées',
              isSelected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            _DrawerItem(
              icon: Icons.analytics_rounded,
              label: 'Rapports',
              isSelected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.settings_rounded,
              label: 'Configuration OCP',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConfigPage()),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Déconnexion',
              isSelected: false,
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openGestionProjets() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GestionProjetsPage(
          utilisateurId: widget.utilisateurId,
          nom: widget.nom,
          onProjetChanged: _onProjetChanged,
        ),
      ),
    );
    // Recharger après retour
    _loadProjets();
  }
}

// ─────────────────────────────────────────────
//  Modèle interne pour les items de navigation
// ─────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────
//  Widget GNAV Item — barre du bas style Google
// ─────────────────────────────────────────────
class _GnavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GnavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00875A).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey('$label-$isSelected'),
                size: 24,
                color: isSelected
                    ? const Color(0xFF00875A)
                    : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF00875A)
                    : Colors.grey.shade500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Widget Drawer Item — avec indicateur latéral
// ─────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDestructive;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isDestructive = false,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red
        : isSelected
        ? const Color(0xFF00875A)
        : const Color(0xFF111111);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00875A).withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF00875A),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
