// 💧 Page de création de fuite
// Date par défaut = aujourd'hui, modifiable
// Type vapeur : dropdown
// GPS : bouton sans logique pour l'instant

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fuite.dart';
import '../models/campagne.dart';
import '../services/debit_service.dart';
import '../services/gps_service.dart';
import '../api/fuite_api.dart' as fuite_api;
import '../api/campagne_api.dart' as campagne_api;
import '../api/photo_api.dart' as photo_api;
import '../widgets/image_picker_widget.dart';
import 'config_page.dart';

class CreerFuitePage extends StatefulWidget {
  final int utilisateurId;
  final int? campagneId; // Optionnel : pré-sélectionner une campagne
  final int? projetId; // Optionnel : filtrer les campagnes par projet

  const CreerFuitePage({
    super.key,
    required this.utilisateurId,
    this.campagneId,
    this.projetId,
  });

  @override
  State<CreerFuitePage> createState() => _CreerFuitePageState();
}

class _CreerFuitePageState extends State<CreerFuitePage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ─── Contrôleurs ──────────────────────────────────────
  final _tagCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _pressionCtrl = TextEditingController();
  final _localisationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // ─── Dropdowns ────────────────────────────────────────
  int? _selectedCampagneId;
  String _statut = 'A_REPARER';
  String? _typeVapeur;

  // ─── GPS ──────────────────────────────────────────────
  double? _gpsLatitude;
  double? _gpsLongitude;
  bool _gpsLoading = false;

  // ─── Diamètre orifice (slider) ───────────────────────
  double _diametreOrifice = 5.0; // mm, valeur par défaut

  // ─── Photos ───────────────────────────────────────────
  final List<String> _photoPaths = [];

  // ─── Données ──────────────────────────────────────────
  List<Campagne> _campagnes = [];
  bool _loadingCampagnes = true;

  @override
  void initState() {
    super.initState();
    // Date et heure du jour préremplies
    final now = DateTime.now();
    _dateCtrl.text =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    _selectedCampagneId = widget.campagneId;
    _loadCampagnes();
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    _dateCtrl.dispose();
    _pressionCtrl.dispose();
    _localisationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCampagnes() async {
    try {
      final campagnes = await campagne_api.getCampagnes(
        utilisateurId: widget.projetId == null ? widget.utilisateurId : null,
        projetId: widget.projetId,
      );
      if (!mounted) return;
      setState(() {
        _campagnes = campagnes;
        _loadingCampagnes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCampagnes = false);
    }
  }

  Future<void> _pickerDate() async {
    final now = DateTime.now();
    final initial =
        DateTime.tryParse(_dateCtrl.text.trim().replaceFirst(' ', 'T')) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00875A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!mounted) return;
      // Demander l'heure après la date
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF00875A)),
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        _dateCtrl.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} '
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      } else {
        // Si l'utilisateur annule l'heure, on garde minuit
        _dateCtrl.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')} '
            '00:00:00';
      }
    }
  }

  Future<void> _capturerGps() async {
    setState(() => _gpsLoading = true);

    final position = await GpsService.capturer(
      context: context,
      onStateChanged: () {},
    );

    if (!mounted) return;

    if (position != null) {
      setState(() {
        _gpsLatitude = position.latitude;
        _gpsLongitude = position.longitude;
      });
    }
    setState(() => _gpsLoading = false);
  }

  Future<void> _ouvrirGoogleMaps() async {
    if (_gpsLatitude == null || _gpsLongitude == null) return;
    await GpsService.ouvrirGoogleMaps(
      context: context,
      latitude: _gpsLatitude!,
      longitude: _gpsLongitude!,
    );
  }

  Future<void> _creerFuite() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCampagneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner une campagne'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final pression = double.tryParse(_pressionCtrl.text.trim()) ?? 0;
      final debit = DebitService.calculerDebit(
        pressionRel: pression,
        diametreMm: _diametreOrifice,
      );
      final coutAnnuel = await DebitService.calculerCoutAnnuel(
        debitKgh: debit,
        pressionRel: pression,
      );

      final nouvelleFuite = await fuite_api.createFuite(
        campagneId: _selectedCampagneId!,
        numeroTag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
        dateDetection: '${_dateCtrl.text.trim().replaceFirst(' ', 'T')}.000000',
        statut: _statut,
        pressionBar: pression,
        typeVapeur: _typeVapeur,
        gpsLatitude: _gpsLatitude,
        gpsLongitude: _gpsLongitude,
        zone: _localisationCtrl.text.trim().isEmpty
            ? null
            : _localisationCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        coutAnnuelEstime: coutAnnuel,
      );

      // Uploader les photos avec l'ID de la nouvelle fuite
      for (final path in _photoPaths) {
        await photo_api.createPhoto(
          fuiteId: nouvelleFuite.id,
          cheminFichier: path,
          datePrise: DateTime.now().toIso8601String(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Fuite créée avec succès !'),
            ],
          ),
          backgroundColor: const Color(0xFF00875A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Nouvelle fuite',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ── Bouton chat (désactivé : fuite pas encore créée) ──
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('Enregistrez d\'abord la fuite'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF00875A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chat_rounded,
                size: 20,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête illustré ──
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00875A).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        size: 36,
                        color: Color(0xFF00875A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Signaler une fuite',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Renseigne les informations de la fuite',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Campagne ──
              _buildLabel('Campagne *'),
              const SizedBox(height: 8),
              _loadingCampagnes
                  ? const SizedBox(
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00875A),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: _selectedCampagneId,
                      decoration: _inputDecoration(
                        hint: 'Sélectionner une campagne',
                        icon: Icons.campaign_rounded,
                      ),
                      style: const TextStyle(color: Color(0xFF111111)),
                      dropdownColor: Colors.white,
                      items: _campagnes.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.nom,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCampagneId = v),
                    ),
              const SizedBox(height: 24),

              // ── Numéro de tag ──
              _buildLabel('Numéro de tag (optionnel)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tagCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                style: const TextStyle(color: Color(0xFF111111)),
                decoration: _inputDecoration(
                  hint: 'Ex: FTE-001',
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(height: 24),

              // ── Date de détection ──
              _buildLabel('Date de détection'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                style: const TextStyle(color: Color(0xFF111111)),
                decoration: _inputDecoration(
                  hint: 'AAAA-MM-JJ',
                  icon: Icons.calendar_today_rounded,
                ),
                onTap: _pickerDate,
              ),
              const SizedBox(height: 24),

              // ── Statut ──
              _buildLabel('Statut'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _statut,
                decoration: _inputDecoration(
                  hint: 'Statut',
                  icon: Icons.flag_rounded,
                ),
                style: const TextStyle(color: Color(0xFF111111)),
                dropdownColor: Colors.white,
                items: Fuite.statuts.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _statut = v!),
              ),
              const SizedBox(height: 24),

              // ── Type de vapeur ──
              _buildLabel('Type de vapeur'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _typeVapeur,
                decoration: _inputDecoration(
                  hint: 'Sélectionner un type',
                  icon: Icons.gas_meter_rounded,
                ),
                style: const TextStyle(color: Color(0xFF111111)),
                dropdownColor: Colors.white,
                items: Fuite.typesVapeur.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _typeVapeur = v),
              ),
              const SizedBox(height: 24),

              // ── Pression ──
              _buildLabel('Pression (bar) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pressionCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                style: const TextStyle(color: Color(0xFF111111)),
                decoration: _inputDecoration(
                  hint: 'Ex: 7.5',
                  icon: Icons.speed_rounded,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'La pression est requise';
                  }
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) {
                    return 'Valeur invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Diamètre orifice (slider) ──
              _buildLabel('Diamètre orifice (mm)'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Diamètre',
                          style: TextStyle(color: Color(0xFF111111)),
                        ),
                        Text(
                          '${_diametreOrifice.toStringAsFixed(1)} mm',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF00875A),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _diametreOrifice,
                      min: 1.0,
                      max: 30.0,
                      divisions: 58, // pas de 0.5 mm
                      activeColor: const Color(0xFF00875A),
                      inactiveColor: const Color(
                        0xFF00875A,
                      ).withValues(alpha: 0.2),
                      label: '${_diametreOrifice.toStringAsFixed(1)} mm',
                      onChanged: (v) => setState(() => _diametreOrifice = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1 mm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          '30 mm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Estimation débit / coût (juste après le diamètre) ──
              _buildEstimation(),
              const SizedBox(height: 24),

              // ── Localisation (zone) ──
              _buildLabel('Localisation (zone)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _localisationCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Color(0xFF111111)),
                decoration: _inputDecoration(
                  hint: 'Ex: Échangeur T1, niveau +15m',
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 24),

              // ── GPS ──
              GpsService.boutonGps(
                latitude: _gpsLatitude,
                longitude: _gpsLongitude,
                loading: _gpsLoading,
                onCapturer: _capturerGps,
                onOuvrirMaps: _ouvrirGoogleMaps,
              ),
              const SizedBox(height: 24),
              // ── Description ──
              _buildLabel('Description (optionnelle)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Color(0xFF111111)),
                decoration: _inputDecoration(
                  hint: 'Ex: Fuite sur joint de bride, côté chaudière',
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 24),
              // ── Photos ──
              _buildLabel('Photos (optionnelles)'),
              const SizedBox(height: 8),
              ImagePickerWidget(
                onPhotosChanged: (paths) {
                  _photoPaths
                    ..clear()
                    ..addAll(paths);
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),

              // ── Bouton Créer ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _creerFuite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.water_drop_rounded),
                            SizedBox(width: 10),
                            Text(
                              'Créer la fuite',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
    );
  }

  /// Construit le widget d'estimation débit/coût en temps réel
  Widget _buildEstimation() {
    final pression = double.tryParse(_pressionCtrl.text.trim());

    if (pression == null || pression <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calculate_rounded,
              color: Colors.grey.shade500,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'Estimation disponible après avoir saisi la pression',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final debit = DebitService.calculerDebit(
      pressionRel: pression,
      diametreMm: _diametreOrifice,
    );

    return FutureBuilder<double>(
      future: DebitService.calculerCoutAnnuel(
        debitKgh: debit,
        pressionRel: pression,
      ),
      builder: (context, snapshot) {
        final coutAnnuel = snapshot.data ?? 0;
        final erreur = snapshot.hasError;

        return Column(
          children: [
            // ⚠️ Alerte si le prix kWh est à 0
            if (coutAnnuel == 0 && !erreur)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 4,
                  top: 10,
                  bottom: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE65100),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Prix kWh à 0,00 MAD — configurez-le',
                        style: const TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, size: 20),
                      color: const Color(0xFFE65100),
                      tooltip: 'Paramètres',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ConfigPage(onSaved: () => setState(() {})),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00875A).withValues(alpha: 0.08),
                    const Color(0xFF00875A).withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00875A).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Débit
                  _estimationRow(
                    label: 'Débit estimé',
                    value: '${DebitService.formater(debit)} kg/h',
                    icon: Icons.water_drop_rounded,
                  ),
                  const SizedBox(height: 6),
                  // Coût annuel
                  _estimationRow(
                    label: 'Coût annuel estimé',
                    value: erreur
                        ? '—'
                        : '${DebitService.formater(coutAnnuel)} MAD',
                    icon: Icons.payments_rounded,
                    valueBold: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _estimationRow({
    required String label,
    required String value,
    required IconData icon,
    bool valueBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00875A), size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: 15,
            color: const Color(0xFF111111),
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
        color: Color(0xFF111111),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: const Color(0xFF00875A), size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: Color(0xFF00875A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}
