// 👤 Page Profil — modifier nom, prénom, email et mot de passe
// Design OCP — mêmes conventions que ConfigPage

import 'package:flutter/material.dart';
import '../api/auth_api.dart' as auth_api;
import '../api/utilisateur_api.dart' as utilisateur_api;
import '../models/utilisateur.dart';

class ProfilePage extends StatefulWidget {
  final Utilisateur utilisateur;

  const ProfilePage({super.key, required this.utilisateur});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _ocpGreen = Color(0xFF00875A);
  static const Color _ocpDarkGreen = Color(0xFF005C3E);
  static const Color _ocpBlack = Color(0xFF111111);
  static const Color _ocpGrey = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();

  // ── Contrôleurs : infos personnelles ──
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _emailCtrl;

  // ── Contrôleurs : mot de passe ──
  late final TextEditingController _motDePasseActuelCtrl;
  late final TextEditingController _nouveauMotDePasseCtrl;
  late final TextEditingController _confirmationCtrl;

  bool _obscureActuel = true;
  bool _obscureNouveau = true;
  bool _obscureConfirmation = true;

  bool _loading = true;
  bool _saving = false;
  bool _changingPassword = false;

  Utilisateur? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.utilisateur;

    _nomCtrl = TextEditingController(text: widget.utilisateur.nom);
    _prenomCtrl = TextEditingController(text: widget.utilisateur.prenom);
    _emailCtrl = TextEditingController(text: widget.utilisateur.email);

    _motDePasseActuelCtrl = TextEditingController();
    _nouveauMotDePasseCtrl = TextEditingController();
    _confirmationCtrl = TextEditingController();

    _loadMe();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _motDePasseActuelCtrl.dispose();
    _nouveauMotDePasseCtrl.dispose();
    _confirmationCtrl.dispose();
    super.dispose();
  }

  /// Recharge le profil depuis le backend (données à jour).
  Future<void> _loadMe() async {
    try {
      final user = await utilisateur_api.getMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _nomCtrl.text = user.nom;
        _prenomCtrl.text = user.prenom;
        _emailCtrl.text = user.email;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = await utilisateur_api.updateProfil(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      // Mettre à jour la session locale pour la HomePage
      await auth_api.updateSessionUser(
        id: updated.id,
        nom: updated.nom,
        prenom: updated.prenom,
        email: updated.email,
      );

      if (!mounted) return;
      setState(() {
        _user = updated;
        _saving = false;
      });
      _showMessage('Informations mises à jour ✓', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _changerMotDePasse() async {
    // Validation de confirmation
    if (_nouveauMotDePasseCtrl.text != _confirmationCtrl.text) {
      _showMessage(
        'La confirmation ne correspond pas au nouveau mot de passe.',
        isError: true,
      );
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await utilisateur_api.changerMotDePasse(
        motDePasseActuel: _motDePasseActuelCtrl.text,
        nouveauMotDePasse: _nouveauMotDePasseCtrl.text,
      );

      if (!mounted) return;
      setState(() {
        _changingPassword = false;
        _motDePasseActuelCtrl.clear();
        _nouveauMotDePasseCtrl.clear();
        _confirmationCtrl.clear();
      });
      _showMessage('Mot de passe modifié avec succès ✓', isError: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _changingPassword = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : _ocpGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mon profil',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _ocpGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Carte identité ──
                  _buildIdentityCard(),
                  const SizedBox(height: 24),

                  // ── Section : Informations personnelles ──
                  _buildSectionHeader('Informations personnelles'),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Nom'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nomCtrl,
                            style: const TextStyle(color: _ocpBlack),
                            decoration: _inputDecoration(
                              hint: 'Nom',
                              icon: Icons.badge_rounded,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Le nom est requis';
                              }
                              if (v.trim().length < 2) {
                                return 'Au moins 2 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Prénom'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _prenomCtrl,
                            style: const TextStyle(color: _ocpBlack),
                            decoration: _inputDecoration(
                              hint: 'Prénom',
                              icon: Icons.person_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: _ocpBlack),
                            decoration: _inputDecoration(
                              hint: 'email@exemple.com',
                              icon: Icons.email_rounded,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "L'email est requis";
                              }
                              if (!v.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _saveProfil,
                              style: FilledButton.styleFrom(
                                backgroundColor: _ocpGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                _saving ? 'Enregistrement…' : 'Enregistrer',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section : Changer le mot de passe ──
                  _buildSectionHeader('Changer le mot de passe'),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Mot de passe actuel'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _motDePasseActuelCtrl,
                          obscureText: _obscureActuel,
                          style: const TextStyle(color: _ocpBlack),
                          decoration:
                              _inputDecoration(
                                hint: 'Mot de passe actuel',
                                icon: Icons.lock_rounded,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureActuel
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: _ocpGrey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureActuel = !_obscureActuel,
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Nouveau mot de passe'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nouveauMotDePasseCtrl,
                          obscureText: _obscureNouveau,
                          style: const TextStyle(color: _ocpBlack),
                          decoration:
                              _inputDecoration(
                                hint: 'Au moins 6 caractères',
                                icon: Icons.lock_reset_rounded,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNouveau
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: _ocpGrey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureNouveau = !_obscureNouveau,
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Confirmer le nouveau mot de passe'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmationCtrl,
                          obscureText: _obscureConfirmation,
                          style: const TextStyle(color: _ocpBlack),
                          decoration:
                              _inputDecoration(
                                hint: 'Confirmer',
                                icon: Icons.lock_rounded,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmation
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: _ocpGrey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmation =
                                        !_obscureConfirmation,
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _changingPassword
                                ? null
                                : _changerMotDePasse,
                            style: FilledButton.styleFrom(
                              backgroundColor: _ocpGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _changingPassword
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.password_rounded, size: 18),
                            label: Text(
                              _changingPassword
                                  ? 'Changement…'
                                  : 'Changer le mot de passe',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────
  //  Widgets internes
  // ─────────────────────────────────────────────

  /// Carte identité avec avatar (initiales) + nom complet + email.
  Widget _buildIdentityCard() {
    final user = _user ?? widget.utilisateur;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_ocpDarkGreen, _ocpGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              user.initiales.isEmpty ? '?' : user.initiales,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nomComplet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte blanche arrondie avec bordure légère.
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _ocpGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _ocpBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: _ocpBlack,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: _ocpGreen, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _ocpGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
