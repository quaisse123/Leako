// ⚙️ Page de configuration OCP
// Paramètres de calcul du coût des fuites.

import 'package:flutter/material.dart';
import '../api/parametre_global_api.dart' as parametre_api;

class ConfigPage extends StatefulWidget {
  final VoidCallback? onSaved;

  const ConfigPage({super.key, this.onSaved});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  late final TextEditingController _heuresCtrl;
  late final TextEditingController _joursCtrl;
  late final TextEditingController _coutCtrl;

  String _langue = 'fr';
  bool _loading = true;

  static const _ocpGreen = Color(0xFF00875A);
  static const _ocpBlack = Color(0xFF111111);
  static const _ocpGrey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _heuresCtrl = TextEditingController();
    _joursCtrl = TextEditingController();
    _coutCtrl = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _heuresCtrl.dispose();
    _joursCtrl.dispose();
    _coutCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await parametre_api.getParametresGlobaux();
      if (!mounted) return;
      setState(() {
        _langue = config.langue;
        _heuresCtrl.text = config.heuresActiviteParJour.toString();
        _joursCtrl.text = config.joursActiviteParAn.toString();
        _coutCtrl.text = config.coutKwhDiram.toStringAsFixed(2);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await parametre_api.updateParametresGlobaux(
        devise: 'MAD',
        coutVapeurParTonne: 0,
        heuresFonctionnementAnnuelles: int.tryParse(_heuresCtrl.text) ?? 24,
        facteurEmissionCO2: 0,
        langue: _langue,
        heuresActiviteParJour: int.tryParse(_heuresCtrl.text) ?? 24,
        joursActiviteParAn: int.tryParse(_joursCtrl.text) ?? 365,
        coutKwhDiram:
            double.tryParse(_coutCtrl.text.replaceAll(',', '.')) ?? 0.0,
      );
      if (!mounted) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Configuration sauvegardée ✓'),
            ],
          ),
          backgroundColor: _ocpGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      // Retour automatique si on vient d'un formulaire
      if (widget.onSaved != null) {
        widget.onSaved!();
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Configuration OCP',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _ocpGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section : Général ──
                    _buildSectionHeader('Général'),
                    const SizedBox(height: 16),

                    _buildLabel('Langue de l\'application'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _langue,
                      decoration: _inputDecoration(
                        icon: Icons.language_rounded,
                      ),
                      style: const TextStyle(color: _ocpBlack),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _langue = v);
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Heures d\'activité par jour'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _heuresCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: _ocpBlack),
                      decoration: _inputDecoration(
                        hint: '24',
                        icon: Icons.schedule_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final n = int.tryParse(v);
                        if (n == null || n < 1 || n > 24) {
                          return 'Entre 1 et 24';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Jours d\'activité par an'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _joursCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: _ocpBlack),
                      decoration: _inputDecoration(
                        hint: '365',
                        icon: Icons.calendar_month_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final n = int.tryParse(v);
                        if (n == null || n < 1 || n > 366) {
                          return 'Entre 1 et 366';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // ── Section : Coût de fuite ──
                    _buildSectionHeader('Coût de fuite'),
                    const SizedBox(height: 16),

                    _buildLabel('Coût par kWh (en Diram)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _coutCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: _ocpBlack),
                      decoration: _inputDecoration(
                        hint: '0.00',
                        icon: Icons.monetization_on_rounded,
                        suffixText: 'MAD/kWh',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n < 0) return 'Valeur invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    // ── Bouton sauvegarder ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _sauvegarder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ocpGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Sauvegarder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Helpers UI ───────────────────────────────────────

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

  InputDecoration _inputDecoration({
    String? hint,
    IconData? icon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: _ocpGreen, size: 20) : null,
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: _ocpGrey, fontSize: 12),
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
