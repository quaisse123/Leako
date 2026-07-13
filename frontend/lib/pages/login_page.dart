// 🔐 Page de connexion / inscription
// Utilise l'API backend avec JWT.

import 'package:flutter/material.dart';
import '../api/auth_api.dart' as auth_api;
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    try {
      if (_isLogin) {
        // 🔐 Connexion
        await auth_api.login(
          email: _emailCtrl.text.trim(),
          motDePasse: _passwordCtrl.text,
        );
      } else {
        // 📝 Inscription
        if (_nomCtrl.text.trim().isEmpty) {
          _showError('Le nom est requis');
          setState(() => _loading = false);
          return;
        }
        await auth_api.register(
          nom: _nomCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          motDePasse: _passwordCtrl.text,
        );
      }

      // Récupérer l'utilisateur depuis la session locale
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
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF142A1E),
                    border: Border.all(
                      color: const Color(0xFF6EDAA0).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    size: 40,
                    color: Color(0xFF6EDAA0),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  _isLogin ? 'Connexion' : 'Nouveau compte',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF5F5F5),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Connecte-toi pour continuer'
                      : 'Crée ton compte technicien',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
                const SizedBox(height: 40),

                // Nom (inscription seulement)
                if (!_isLogin) ...[
                  TextField(
                    controller: _nomCtrl,
                    style: const TextStyle(color: Color(0xFFF5F5F5)),
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF6EDAA0),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF142A1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFFF5F5F5)),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF6EDAA0),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF142A1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Color(0xFFF5F5F5)),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF6EDAA0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF6EDAA0),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF142A1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton submit
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6EDAA0),
                      foregroundColor: const Color(0xFF0D1B14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0D1B14),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Se connecter' : "S'inscrire",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Lien basculer connexion/inscription
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Pas encore de compte ? S'inscrire"
                        : 'Déjà un compte ? Se connecter',
                    style: const TextStyle(
                      color: Color(0xFF6EDAA0),
                      fontSize: 14,
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
}
