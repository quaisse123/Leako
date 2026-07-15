// ✏️ Page de modification d'une fuite
// Design épuré, fond blanc, champs modifiables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fuite.dart';
import '../services/debit_service.dart';
import '../services/gps_service.dart';
import '../api/fuite_api.dart' as fuite_api;
import '../widgets/image_picker_widget.dart';
import 'config_page.dart';

class ModifierFuitePage extends StatefulWidget {
  final Fuite fuite;

  const ModifierFuitePage({super.key, required this.fuite});

  @override
  State<ModifierFuitePage> createState() => _ModifierFuitePageState();
}

class _ModifierFuitePageState extends State<ModifierFuitePage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ─── Contrôleurs ──────────────────────────────────────
  late final TextEditingController _tagCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _pressionCtrl;
  late final TextEditingController _localisationCtrl;
  late final TextEditingController _descriptionCtrl;

  // ─── GPS ──────────────────────────────────────────────
  double? _gpsLatitude;
  double? _gpsLongitude;
  bool _gpsLoading = false;

  // ─── Diamètre orifice (slider) ───────────────────────
  late double _diametreOrifice;

  // ─── Dropdowns ────────────────────────────────────────
  late String _statut;
  String? _typeVapeur;

  @override
  void initState() {
    super.initState();
    _tagCtrl = TextEditingController(text: widget.fuite.numeroTag ?? '');
    // Formater la date pour affichage lisible (yyyy-MM-dd HH:mm:ss)
    final dateStr = widget.fuite.dateDetection.replaceFirst('T', ' ');
    _dateCtrl = TextEditingController(text: dateStr);
    _pressionCtrl = TextEditingController(
      text: widget.fuite.pressionBar?.toStringAsFixed(1) ?? '',
    );
    _localisationCtrl = TextEditingController(text: widget.fuite.zone ?? '');
    _descriptionCtrl = TextEditingController(
      text: widget.fuite.description ?? '',
    );
    _statut = widget.fuite.statut;
    _typeVapeur = widget.fuite.typeVapeur;
    _gpsLatitude = widget.fuite.gpsLatitude;
    _gpsLongitude = widget.fuite.gpsLongitude;
    _diametreOrifice = widget.fuite.diametreOrifice ?? 5.0;
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

  Future<void> _pickerDate() async {
    final now = DateTime.now();
    final initial =
        DateTime.tryParse(widget.fuite.dateDetection.replaceFirst(' ', 'T')) ??
        now;
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

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

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

      await fuite_api.updateFuite(
        id: widget.fuite.id,
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
        campagneId: widget.fuite.campagneId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Fuite modifiée ✓'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Modifier la fuite',
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
          TextButton(
            onPressed: _loading ? null : _enregistrer,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00875A),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              'Enregistrer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              // ── En-tête ──
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF00875A),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Campagne (lecture seule) ──
              _buildLabel('Campagne'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign_rounded,
                      size: 20,
                      color: Color(0xFF757575),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.fuite.campagneNom ?? '—',
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tag ──
              _buildLabel('Numéro de tag'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tagCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                style: const TextStyle(color: Color(0xFF111111)),
                decoration: _inputDecoration(
                  label: 'Tag',
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(height: 24),

              // ── Date ──
              _buildLabel('Date de détection'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                style: const TextStyle(color: Color(0xFF111111)),
                decoration: _inputDecoration(
                  label: 'Date',
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
                  label: 'Statut',
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

              // ── Type gaz ──
              // ── Type de vapeur ──
              _buildLabel('Type de vapeur'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _typeVapeur,
                decoration: _inputDecoration(
                  label: 'Type de vapeur',
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
                  label: 'Pression',
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
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
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
                      divisions: 58,
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
                  label: 'Ex: Échangeur T1, niveau +15m',
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
                  label: 'Description',
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 24),

              // ── Photos ──
              _buildLabel('Photos (optionnelles)'),
              const SizedBox(height: 8),
              ImagePickerWidget(fuiteId: widget.fuite.id),
              const SizedBox(height: 24),

              // ── Bouton sauvegarde ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _enregistrer,
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
                            Icon(Icons.save_rounded),
                            SizedBox(width: 10),
                            Text(
                              'Enregistrer les modifications',
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

  /// Estimation débit/coût en temps réel
  Widget _buildEstimation() {
    final pression = double.tryParse(_pressionCtrl.text.trim());

    if (pression == null || pression <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
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
              'Estimation après saisie de la pression',
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
        return Column(
          children: [
            // ⚠️ Alerte si le prix kWh est à 0
            if (coutAnnuel == 0)
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
                  _estimationRow(
                    label: 'Débit estimé',
                    value: '${DebitService.formater(debit)} kg/h',
                    icon: Icons.water_drop_rounded,
                  ),
                  const SizedBox(height: 6),
                  _estimationRow(
                    label: 'Coût annuel estimé',
                    value: '${DebitService.formater(coutAnnuel)} MAD',
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
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00875A), size: 22),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00875A), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
