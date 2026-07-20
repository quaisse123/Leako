// 🔐 Page de connexion / inscription
// Design créatif OCP — split screen avec vague verte

import 'package:flutter/material.dart';
import '../api/auth_api.dart' as auth_api;
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color _ocpGreen = Color(0xFF00875A);
  static const Color _ocpDark = Color(0xFF005C3E);
  static const Color _ocpBlack = Color(0xFF111111);
  static const Color _ocpGrey = Color(0xFF757575);
  static const Color _ocpLightGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nomCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validation des champs requis
    if (_emailCtrl.text.trim().isEmpty) {
      _showError("L'email est requis");
      setState(() => _loading = false);
      return;
    }
    if (_passwordCtrl.text.isEmpty) {
      _showError('Le mot de passe est requis');
      setState(() => _loading = false);
      return;
    }
    if (!_isLogin && _nomCtrl.text.trim().isEmpty) {
      _showError('Le nom est requis');
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await auth_api.login(
          email: _emailCtrl.text.trim(),
          motDePasse: _passwordCtrl.text,
        );
      } else {
        await auth_api.register(
          nom: _nomCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          motDePasse: _passwordCtrl.text,
        );
      }

      final user = await auth_api.getSessionUser();
      if (user == null) {
        _showError('Erreur de session');
        setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            utilisateurId: user.id,
            nom: user.nom,
            email: user.email,
          ),
        ),
      );
    } catch (e) {
      _showError('Erreur : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ╔════════════════════════════════════╗
                // ║  LOGO (grand)                      ║
                // ╚════════════════════════════════════╝
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.water_drop_rounded,
                          size: 96,
                          color: _ocpGreen,
                        ),
                      ),
                    ),
                  ),
                ),

                // ╔════════════════════════════════════╗
                // ║  FORMULAIRE                         ║
                // ╚════════════════════════════════════╝
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: _ocpGreen.withValues(alpha: 0.04),
                              blurRadius: 60,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Titre du formulaire
                            Text(
                              _isLogin ? 'Connexion' : 'Nouveau compte',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _ocpBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLogin
                                  ? 'Connectez-vous pour continuer'
                                  : 'Créez votre compte technicien',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _ocpGrey,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Nom (inscription)
                            if (!_isLogin) ...[
                              _buildField(
                                controller: _nomCtrl,
                                label: 'Nom complet',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Email
                            _buildField(
                              controller: _emailCtrl,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),

                            // Mot de passe
                            _buildPasswordField(),

                            const SizedBox(height: 28),

                            // Bouton
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _ocpGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isLogin
                                                ? Icons.login_rounded
                                                : Icons
                                                      .person_add_alt_1_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _isLogin
                                                ? 'Se connecter'
                                                : "S'inscrire",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Lien basculer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? "Pas encore de compte ? "
                                      : 'Déjà un compte ? ',
                                  style: const TextStyle(
                                    color: _ocpGrey,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _isLogin = !_isLogin),
                                  child: Text(
                                    _isLogin ? "S'inscrire" : 'Se connecter',
                                    style: const TextStyle(
                                      color: _ocpGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _ocpBlack, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _ocpGreen, size: 20),
        filled: true,
        fillColor: _ocpLightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _ocpGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: _ocpGrey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      style: const TextStyle(color: _ocpBlack, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock_outline, color: _ocpGreen, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _ocpGreen,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: _ocpLightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _ocpGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: _ocpGrey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
