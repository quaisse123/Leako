// 📋 Page Gestion des Projets
// Mes projets (owner) + Projets d'équipe (member) + Invitations

import 'package:flutter/material.dart';
import '../models/projet.dart';
import '../api/projet_api.dart' as projet_api;

class GestionProjetsPage extends StatefulWidget {
  final int utilisateurId;
  final String nom;
  final VoidCallback? onProjetChanged;

  const GestionProjetsPage({
    super.key,
    required this.utilisateurId,
    required this.nom,
    this.onProjetChanged,
  });

  @override
  State<GestionProjetsPage> createState() => _GestionProjetsPageState();
}

class _GestionProjetsPageState extends State<GestionProjetsPage> {
  static const Color _ocpGreen = Color(0xFF00875A);
  static const Color _ocpBlack = Color(0xFF111111);
  static const Color _ocpGrey = Color(0xFF757575);
  static const Color _ocpLightGrey = Color(0xFFF5F5F5);
  static const Color _red = Color(0xFFD32F2F);
  static const Color _orange = Color(0xFFF57C00);
  static const Color _blue = Color(0xFF1565C0);

  List<Projet> _mesProjets = [];
  List<Projet> _teamProjets = [];
  List<Map<String, dynamic>> _invitations = [];
  bool _loading = true;
  final Set<int> _expandedProjets = {}; // projet ids with visible member list

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
    });
    try {
      final projets = await projet_api.getMesProjets(widget.utilisateurId);
      final invitations = await projet_api.getMesInvitations(
        widget.utilisateurId,
      );

      // Séparer mes projets (owner) vs team projets (member)
      final mes = <Projet>[];
      final team = <Projet>[];
      for (final p in projets) {
        if (p.createurId == widget.utilisateurId) {
          mes.add(p);
        } else {
          team.add(p);
        }
      }

      if (mounted) {
        setState(() {
          _mesProjets = mes;
          _teamProjets = team;
          _invitations = invitations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
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
          'Gestion des Projets',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _ocpBlack,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: _ocpBlack),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: _ocpGreen,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Invitations ──
                  if (_invitations.isNotEmpty) ...[
                    _buildSectionTitle('Invitations en attente', _orange),
                    const SizedBox(height: 8),
                    ..._invitations.map((inv) => _buildInvitationCard(inv)),
                    const SizedBox(height: 24),
                  ],

                  // ── Créer un projet ──
                  _buildCreerProjetCard(),
                  const SizedBox(height: 24),

                  // ── Mes projets (owner) ──
                  _buildSectionTitle('Mes projets', _ocpGreen),
                  const SizedBox(height: 8),
                  if (_mesProjets.isEmpty)
                    _buildEmptyState("Vous n'avez créé aucun projet")
                  else
                    ..._mesProjets.map(
                      (p) => _buildProjetCard(p, isOwner: true),
                    ),
                  const SizedBox(height: 24),

                  // ── Projets d'équipe (member) ──
                  _buildSectionTitle("Projets d'équipe", _blue),
                  const SizedBox(height: 8),
                  if (_teamProjets.isEmpty)
                    _buildEmptyState("Vous n'êtes membre d'aucune équipe")
                  else
                    ..._teamProjets.map(
                      (p) => _buildProjetCard(p, isOwner: false),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: _ocpBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ocpLightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: _ocpGrey)),
      ),
    );
  }

  // ── Carte Créer Projet ──
  Widget _buildCreerProjetCard() {
    return Container(
      decoration: BoxDecoration(
        color: _ocpLightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _ocpGreen, shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
        title: const Text(
          'Créer un nouveau projet',
          style: TextStyle(fontWeight: FontWeight.bold, color: _ocpGreen),
        ),
        trailing: const Icon(Icons.chevron_right, color: _ocpGrey),
        onTap: _showCreateDialog,
      ),
    );
  }

  // ── Carte Projet ──
  Widget _buildProjetCard(Projet projet, {required bool isOwner}) {
    final membres = projet.membres;
    final accepted = membres.where((m) => m.statut == 'ACCEPTE').toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: nom + badge ──
            Row(
              children: [
                Icon(
                  isOwner ? Icons.star_rounded : Icons.group_rounded,
                  color: isOwner ? _orange : _blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    projet.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _ocpBlack,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isOwner
                        ? _orange.withValues(alpha: 0.1)
                        : _blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOwner ? 'Owner' : 'Membre',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOwner ? _orange : _blue,
                    ),
                  ),
                ),
              ],
            ),
            if (projet.description != null &&
                projet.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                projet.description!,
                style: const TextStyle(color: _ocpGrey, fontSize: 13),
              ),
            ],

            // ── Membres count + expand/collapse ──
            const SizedBox(height: 8),
            _buildMembresRow(projet, accepted, isOwner),

            // ── Actions ──
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isOwner) ...[
                  _buildActionBtn(
                    Icons.edit_rounded,
                    'Modifier',
                    _ocpGreen,
                    () => _showEditDialog(projet),
                  ),
                  const SizedBox(width: 8),
                  _buildActionBtn(
                    Icons.person_add_rounded,
                    'Inviter',
                    _blue,
                    () => _showInviteDialog(projet),
                  ),
                  const SizedBox(width: 8),
                  _buildActionBtn(
                    Icons.delete_rounded,
                    'Supprimer',
                    _red,
                    () => _confirmDelete(projet),
                  ),
                ] else ...[
                  _buildActionBtn(
                    Icons.exit_to_app_rounded,
                    'Quitter',
                    _red,
                    () => _confirmQuit(projet),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Ligne membres avec expand/collapse ──
  Widget _buildMembresRow(
    Projet projet,
    List<ProjetMembre> accepted,
    bool isOwner,
  ) {
    final expanded = _expandedProjets.contains(projet.id);
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (expanded) {
                _expandedProjets.remove(projet.id);
              } else {
                _expandedProjets.add(projet.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.people_rounded, size: 14, color: _ocpGrey),
                const SizedBox(width: 4),
                Text(
                  '${accepted.length} membre(s)',
                  style: const TextStyle(color: _ocpGrey, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Créé par ${projet.createurNom}',
                  style: const TextStyle(color: _ocpGrey, fontSize: 11),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: _ocpGrey,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 4),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
          const SizedBox(height: 6),
          ...accepted.map(
            (m) => _buildMembreTile(m, projet.createurId, projet.id),
          ),
        ],
      ],
    );
  }

  // ── Ligne d'un membre ──
  Widget _buildMembreTile(ProjetMembre membre, int createurId, int projetId) {
    final isOwner = membre.utilisateurId == createurId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isOwner
                ? _orange.withValues(alpha: 0.15)
                : _ocpGreen.withValues(alpha: 0.1),
            child: Text(
              membre.utilisateurNom.isNotEmpty
                  ? membre.utilisateurNom[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOwner ? _orange : _ocpGreen,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membre.utilisateurNom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _ocpBlack,
                  ),
                ),
                if (membre.utilisateurEmail.isNotEmpty)
                  Text(
                    membre.utilisateurEmail,
                    style: const TextStyle(fontSize: 11, color: _ocpGrey),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isOwner
                  ? _orange.withValues(alpha: 0.1)
                  : _ocpGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isOwner ? 'Owner' : 'Membre',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isOwner ? _orange : _ocpGreen,
              ),
            ),
          ),
          // Bouton retirer (visible seulement pour l'owner, pas sur lui-même)
          if (!isOwner && widget.utilisateurId == createurId) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _confirmRetirerMembre(
                projetId,
                membre.utilisateurId,
                membre.utilisateurNom,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 16,
                  color: _red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmRetirerMembre(int projetId, int membreId, String membreNom) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer "$membreNom" du projet ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () async {
              try {
                await projet_api.retirerMembre(
                  projetId: projetId,
                  membreId: membreId,
                  createurId: widget.utilisateurId,
                );
                Navigator.pop(ctx);
                await _loadAll();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$membreNom a été retiré du projet'),
                      backgroundColor: _ocpGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: _red,
                    ),
                  );
                }
              }
            },
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ── Carte Invitation ──
  Widget _buildInvitationCard(Map<String, dynamic> inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orange.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mail_rounded, color: _orange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invitation: ${inv['projetNom'] ?? 'Projet'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _ocpBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Par ${inv['createurNom'] ?? '—'}',
                    style: const TextStyle(color: _ocpGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: _ocpGreen),
              tooltip: 'Accepter',
              onPressed: () => _repondreInvitation(inv['id'] as int, true),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: _red),
              tooltip: 'Refuser',
              onPressed: () => _repondreInvitation(inv['id'] as int, false),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ──

  Future<void> _repondreInvitation(int invitationId, bool accepte) async {
    try {
      await projet_api.repondreInvitation(
        invitationId: invitationId,
        accepte: accepte,
        utilisateurId: widget.utilisateurId,
      );
      widget.onProjetChanged?.call();
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepte ? 'Invitation acceptée !' : 'Invitation refusée',
            ),
            backgroundColor: accepte ? _ocpGreen : _red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _red),
        );
      }
    }
  }

  void _showCreateDialog() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Nouveau Projet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du projet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (nomCtrl.text.trim().isEmpty) return;
              try {
                await projet_api.createProjet(
                  nom: nomCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  createurId: widget.utilisateurId,
                );
                Navigator.pop(ctx);
                widget.onProjetChanged?.call();
                await _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Projet projet) {
    final nomCtrl = TextEditingController(text: projet.nom);
    final descCtrl = TextEditingController(text: projet.description ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Modifier le projet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du projet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (nomCtrl.text.trim().isEmpty) return;
              try {
                await projet_api.updateProjet(
                  id: projet.id,
                  nom: nomCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  utilisateurId: widget.utilisateurId,
                );
                Navigator.pop(ctx);
                widget.onProjetChanged?.call();
                await _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(Projet projet) async {
    // Charger les utilisateurs + invitations en attente avant d'ouvrir le dialog
    List<Map<String, dynamic>> allUsers = [];
    List<Map<String, dynamic>> filteredUsers = [];
    Set<int> pendingInviteIds = {};
    bool loadingUsers = true;

    try {
      final users = await projet_api.getAllUtilisateurs();
      // Membres déjà acceptés (exclus de la liste)
      final acceptedIds = projet.membres
          .where((m) => m.statut == 'ACCEPTE')
          .map((m) => m.utilisateurId)
          .toSet();

      // Récupérer les invitations en attente pour ce projet
      try {
        final invitations = await projet_api.getInvitationsByProjet(
          projet.id,
          widget.utilisateurId,
        );
        pendingInviteIds = invitations
            .where((inv) => inv['statut'] == 'INVITE')
            .map((inv) => inv['utilisateurId'] as int)
            .toSet();
      } catch (_) {
        // Ignorer si l'appel échoue
      }

      // Exclure les membres déjà acceptés, mais GARDER ceux en attente
      allUsers = users
          .where((u) => !acceptedIds.contains(u['id'] as int))
          .toList();
      filteredUsers = allUsers;
      loadingUsers = false;
    } catch (_) {
      loadingUsers = false;
    }

    if (!mounted) return;

    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Inviter un membre',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Rechercher par nom ou email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchCtrl.clear();
                                setDialogState(() {
                                  filteredUsers = allUsers;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        filteredUsers = allUsers
                            .where(
                              (u) =>
                                  (u['nom'] as String).toLowerCase().contains(
                                    value.toLowerCase(),
                                  ) ||
                                  (u['email'] as String).toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (loadingUsers)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
                  else if (filteredUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucun utilisateur disponible',
                        style: TextStyle(color: _ocpGrey),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView(
                        children: filteredUsers.map((u) {
                          final userId = u['id'] as int;
                          final nom = u['nom'] as String;
                          final email = u['email'] as String;
                          final isPending = pendingInviteIds.contains(userId);
                          return ListTile(
                            dense: true,
                            enabled: !isPending,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: isPending
                                  ? _ocpGrey.withValues(alpha: 0.15)
                                  : _ocpGreen.withValues(alpha: 0.1),
                              child: Text(
                                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isPending ? _ocpGrey : _ocpGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              nom,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isPending ? _ocpGrey : null,
                              ),
                            ),
                            subtitle: isPending
                                ? const Text(
                                    'Déjà invité · En attente de réponse',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Text(
                                    email,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                            onTap: isPending
                                ? null
                                : () async {
                                    final navigatorCtx = ctx;
                                    Navigator.pop(navigatorCtx);
                                    try {
                                      await projet_api.inviterMembre(
                                        projetId: projet.id,
                                        utilisateurIdInvite: userId,
                                        createurId: widget.utilisateurId,
                                      );
                                      await _loadAll();
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '$nom invité avec succès !',
                                            ),
                                            backgroundColor: _ocpGreen,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Erreur: $e'),
                                            backgroundColor: _red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(Projet projet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le projet ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${projet.nom}" ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () async {
              try {
                await projet_api.deleteProjet(projet.id, widget.utilisateurId);
                Navigator.pop(ctx);
                widget.onProjetChanged?.call();
                await _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmQuit(Projet projet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le projet ?'),
        content: Text('Êtes-vous sûr de vouloir quitter "${projet.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () async {
              try {
                await projet_api.quitterProjet(projet.id, widget.utilisateurId);
                Navigator.pop(ctx);
                widget.onProjetChanged?.call();
                await _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
