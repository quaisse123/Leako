// ✏️ Page de modification d'une fuite
// Design épuré, fond blanc, champs modifiables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fuite.dart';
import '../services/debit_service.dart';
import '../services/gps_service.dart';
import '../api/fuite_api.dart' as fuite_api;
import '../api/photo_api.dart' as photo_api;
import '../api/parametre_global_api.dart' as parametre_api;
import '../models/config_app.dart';
import '../widgets/image_picker_widget.dart';
import '../services/analyse_ia_service.dart';
import 'config_page.dart';
import 'fuite_chat_page.dart';

class ModifierFuitePage extends StatefulWidget {
  final Fuite fuite;
  final int? utilisateurId;

  const ModifierFuitePage({super.key, required this.fuite, this.utilisateurId});

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

  // ─── Photos ───────────────────────────────────────────
  final List<String> _photoPaths = [];

  // ─── IA ───────────────────────────────────────────────
  bool _iaLoading = false;
  bool _iaEffectuee = false;
  AnalyseIAReponse? _iaReponse;

  /// true si les photos ont changé depuis l'analyse persistée →
  /// la carte IA affichée n'est plus valide.
  bool _photosModifiees = false;

  // ─── Paramètres globaux (coût kWh) ───────────────────
  ConfigApp? _config;

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

    // Charger la dernière analyse IA persistée pour préremplir
    // la carte IA + la description si elle est à jour.
    _chargerAnalysePersistee();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await parametre_api.getParametresGlobaux();
      if (mounted) setState(() => _config = config);
    } catch (_) {
      // Silencieux — le prix kWh reste à 0 par défaut
    }
  }

  /// Charge la dernière analyse IA persistée en DB (si elle existe et si
  /// les photos de la fuite n'ont pas changé depuis) puis préremplit la
  /// carte IA et la description.
  Future<void> _chargerAnalysePersistee() async {
    debugPrint(
      '🔍 [DEBUG] _chargerAnalysePersistee fuite#${widget.fuite.id} '
      '→ chargement de l\'analyse persistée…',
    );
    try {
      final reponse = await AnalyseIAService.getDerniereAnalyse(
        fuiteId: widget.fuite.id,
      );
      if (!mounted || reponse == null) {
        debugPrint(
          '🔍 [DEBUG] _chargerAnalysePersistee fuite#${widget.fuite.id} '
          '→ aucune analyse à jour (null)',
        );
        return;
      }

      // La description actuelle est vide → on la préremplit avec la synthèse.
      final synthese = reponse.synthese?.trim() ?? '';
      debugPrint(
        '🔍 [DEBUG] _chargerAnalysePersistee fuite#${widget.fuite.id} '
        '→ analyse trouvée, ${reponse.resultats.length} média(s), '
        'synthese=${synthese.isEmpty ? "vide" : "présente"}',
      );
      setState(() {
        _iaReponse = reponse;
        _iaEffectuee = true;
        if (_descriptionCtrl.text.trim().isEmpty && synthese.isNotEmpty) {
          _descriptionCtrl.text = synthese;
          debugPrint(
            '🔍 [DEBUG] _chargerAnalysePersistee → description '
            'préremplie avec la synthèse',
          );
        }
      });
    } catch (e) {
      debugPrint(
        '🔍 [DEBUG] _chargerAnalysePersistee fuite#${widget.fuite.id} '
        '→ erreur: $e',
      );
      // Silencieux : pas d'analyse persistée → formulaire normal.
    }
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

  // ─── IA : Analyser les photos (fonction réutilisable) ──
  // Renvoie la réponse IA, ou null en cas d'échec.
  // Ne modifie NI le diamètre NI la description NI _iaReponse :
  // chaque bouton décide ensuite quoi faire du résultat.
  Future<AnalyseIAReponse?> _analyserPhotos() async {
    setState(() => _iaLoading = true);

    try {
      // ── Uploader d'abord les nouvelles photos pour que l'analyse
      //    porte sur l'ensemble (existantes + nouvelles) ──
      if (_photoPaths.isNotEmpty) {
        for (final path in _photoPaths) {
          await photo_api.createPhoto(
            fuiteId: widget.fuite.id,
            cheminFichier: path,
            datePrise: DateTime.now().toIso8601String(),
          );
        }
        if (!mounted) return null;
        setState(() => _photoPaths.clear());
      }

      final reponse = await AnalyseIAService.analyserParFuite(
        fuiteId: widget.fuite.id,
      );

      if (!mounted) return null;

      return reponse;
    } on AnalyseIAException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(e.message, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return null;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    } finally {
      if (mounted) setState(() => _iaLoading = false);
    }
  }

  // ─── IA : Prédire le diamètre (indépendant de la description) ──
  Future<void> _predireDiametre() async {
    final reponse = await _analyserPhotos();
    if (!mounted || reponse == null) return;

    setState(() {
      // Seul ce bouton remplit _iaReponse → affiche la carte d'analyse.
      _iaReponse = reponse;
      _iaEffectuee = true;
      _photosModifiees = false; // La carte est à nouveau à jour.
      // Borner le diamètre dans la plage du slider (1.0 - 50.0).
      // Quand aucune fuite n'est détectée, diametreMoyenMm vaut 0.0.
      _diametreOrifice = reponse.resume.diametreMoyenMm.clamp(1.0, 50.0);
    });
    debugPrint(
      '🔍 [DEBUG] _predireDiametre fuite#${widget.fuite.id} → '
      'nouvelle analyse OK, ${reponse.resultats.length} média(s), '
      'diamètre=${reponse.resume.diametreMoyenMm.toStringAsFixed(1)} mm '
      '(persistée en DB par le backend)',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                '${reponse.resultats.length} analysé(s) — Diamètre : ${reponse.resume.diametreMoyenMm.toStringAsFixed(1)} mm',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00875A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ─── IA : Générer la description (indépendant du diamètre) ──
  Future<void> _genererDescriptionIA() async {
    // Si l'analyse n'a pas encore été faite, on la déclenche ici.
    // Ainsi l'utilisateur peut générer une description sans avoir
    // prédit le diamètre au préalable.
    var reponse = _iaReponse;
    if (reponse == null || reponse.resultats.isEmpty) {
      reponse = await _analyserPhotos();
      if (!mounted || reponse == null) return;
    }

    // Priorité à la synthèse globale de l'IA si elle existe,
    // sinon concaténer les observations des médias avec fuite visible.
    final synthese = reponse.synthese?.trim() ?? '';
    final descriptions = synthese.isNotEmpty
        ? [synthese]
        : reponse.resultats
              .where((r) => r.fuiteVisible)
              .map((r) => r.observation.trim())
              .where((o) => o.isNotEmpty)
              .toList();

    if (descriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucune description générée par l\'IA'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    final actuelle = _descriptionCtrl.text.trim();
    final nouvelle = actuelle.isEmpty
        ? descriptions.join('\n')
        : '$actuelle\n${descriptions.join('\n')}';

    _descriptionCtrl.text = nouvelle;
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synthese.isNotEmpty
                ? 'Synthèse IA ajoutée'
                : '${descriptions.length} description(s) ajoutée(s)',
          ),
          backgroundColor: const Color(0xFF00875A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
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
        diametreOrifice: _diametreOrifice,
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

      // Uploader tous les médias (existants + nouveaux)
      for (final path in _photoPaths) {
        await photo_api.createPhoto(
          fuiteId: widget.fuite.id,
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

  // ─── Chat ─────────────────────────────────────────────
  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FuiteChatPage(
        fuiteId: widget.fuite.id,
        numeroTag: widget.fuite.numeroTag ?? 'Sans tag',
        utilisateurId: widget.utilisateurId ?? 1,
      ),
    );
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
          // ── Bouton chat ──
          GestureDetector(
            onTap: () => _openChat(),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00875A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chat_rounded,
                size: 20,
                color: Color(0xFF00875A),
              ),
            ),
          ),
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
                readOnly: true,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  label: 'Tag',
                  icon: Icons.tag_rounded,
                  suffixIcon: const Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: Color(0xFF00875A),
                  ),
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
                      max: 50.0,
                      divisions: 98, // pas de 0.5 mm
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
                          '50 mm',
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
              const SizedBox(height: 16),

              // ── Bouton Prédire le diamètre avec IA ──
              // Masqué tant que le prix kWh n'est pas configuré (0,00 MAD).
              if ((_config?.coutKwhDiram ?? 0) > 0)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _iaLoading ? null : _predireDiametre,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: _iaLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.straighten_rounded, size: 20),
                    label: Text(
                      _iaLoading
                          ? 'Analyse IA en cours…'
                          : _iaEffectuee
                          ? '🔄 Ré-prédire le diamètre'
                          : '📏 Prédire le diamètre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

              // ── Carte de résultat IA ──
              // Masquée si les photos ont changé depuis l'analyse persistée.
              if (_iaReponse != null && !_photosModifiees) ...[
                const SizedBox(height: 12),
                _buildCartePredictionIA(_iaReponse!),
              ],
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
              const SizedBox(height: 8),
              // ── Bouton Générer description avec IA ──
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: _genererDescriptionIA,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B1FA2),
                    side: const BorderSide(color: Color(0xFF7B1FA2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text(
                    '✨ Générer avec IA',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Photos ──
              _buildLabel('Photos (optionnelles)'),
              const SizedBox(height: 8),
              ImagePickerWidget(
                fuiteId: widget.fuite.id,
                onNouvellesPhotosChanged: (paths) {
                  _photoPaths
                    ..clear()
                    ..addAll(paths);
                  setState(() {});
                },
                onPhotosModifiees: () {
                  // Les photos ont changé → l'analyse persistée n'est plus à jour :
                  // on invalide la carte IA pour forcer une nouvelle prédiction.
                  debugPrint(
                    '🔍 [DEBUG] onPhotosModifiees fuite#${widget.fuite.id} '
                    '→ photos modifiées, analyse persistée invalidée',
                  );
                  setState(() {
                    _photosModifiees = true;
                    _iaReponse = null;
                    _iaEffectuee = false;
                  });
                },
              ),
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

  Widget _buildCartePredictionIA(AnalyseIAReponse reponse) {
    final r = reponse.resume;
    final confiancePourcent = (r.confianceMoyenne * 100).round();

    // Icône selon le type
    IconData typeIcon;
    Color typeColor;
    switch (r.typeFuite) {
      case 'liquide':
        typeIcon = Icons.water_drop_rounded;
        typeColor = const Color(0xFF1565C0);
        break;
      case 'vapeur':
        typeIcon = Icons.cloud_rounded;
        typeColor = const Color(0xFF78909C);
        break;
      case 'mixte':
        typeIcon = Icons.water_drop_rounded;
        typeColor = const Color(0xFF6A1B9A);
        break;
      default:
        typeIcon = Icons.help_outline_rounded;
        typeColor = Colors.grey;
    }

    // Icône selon l'intensité
    IconData intensiteIcon;
    Color intensiteColor;
    switch (r.intensite) {
      case 'faible':
        intensiteIcon = Icons.signal_cellular_alt_1_bar_rounded;
        intensiteColor = const Color(0xFFF9A825);
        break;
      case 'moyenne':
        intensiteIcon = Icons.signal_cellular_alt_2_bar_rounded;
        intensiteColor = const Color(0xFFEF6C00);
        break;
      case 'forte':
        intensiteIcon = Icons.signal_cellular_alt_rounded;
        intensiteColor = const Color(0xFFD32F2F);
        break;
      default:
        intensiteIcon = Icons.signal_cellular_off_rounded;
        intensiteColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7B1FA2).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7B1FA2).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: Color(0xFF7B1FA2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Analyse IA',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF7B1FA2),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00875A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Color(0xFF00875A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Utilisé',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00875A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Grille d'infos (3 chips sur une seule ligne) ──
          Row(
            children: [
              // Type
              Expanded(
                child: _iaInfoChip(
                  icon: typeIcon,
                  label: r.typeFuite,
                  subtitle: 'Type',
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 8),
              // Intensité
              Expanded(
                child: _iaInfoChip(
                  icon: intensiteIcon,
                  label: r.intensite,
                  subtitle: 'Intensité',
                  color: intensiteColor,
                ),
              ),
              const SizedBox(width: 8),
              // Diamètre
              Expanded(
                child: _iaInfoChip(
                  icon: Icons.straighten_rounded,
                  label: '${r.diametreMoyenMm.toStringAsFixed(1)} mm',
                  subtitle: 'Diamètre',
                  color: const Color(0xFF00875A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Barre de confiance ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confiance',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Text(
                    '$confiancePourcent%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: r.confianceMoyenne,
                  minHeight: 6,
                  backgroundColor: const Color(
                    0xFF7B1FA2,
                  ).withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    confiancePourcent >= 70
                        ? const Color(0xFF00875A)
                        : confiancePourcent >= 40
                        ? const Color(0xFFF9A825)
                        : const Color(0xFFD32F2F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Nombre de médias analysés ──
          Row(
            children: [
              Icon(Icons.image_rounded, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(
                '${reponse.resultats.length} média(s)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: const Color(0xFF00875A),
              ),
              const SizedBox(width: 3),
              Text(
                '${reponse.resultats.where((r) => r.fuiteVisible).length} fuite(s)',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF00875A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.cancel_rounded, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 3),
              Text(
                '${reponse.resultats.where((r) => !r.fuiteVisible).length} ignorée(s)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              if (reponse.warnings.isNotEmpty) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.warning_amber_rounded,
                  size: 13,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    reponse.warnings.first,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _iaInfoChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00875A), size: 22),
      suffixIcon: suffixIcon,
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
