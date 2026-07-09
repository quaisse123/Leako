// 💧 Modèle Fuite (Leak)

import '../services/debit_service.dart';

class Fuite {
  final int id;
  final int campagneId;
  final String? numeroTag;
  final String dateDetection;
  final String statut; // A_REPARER, EN_COURS, REPAREE, ANNULEE
  final double? pressionBar;
  final double? diametreOrifice; // mm
  final double? coutAnnuelEstime; // MAD, stocké en DB
  final String? typeVapeur;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? zone;
  final String? description;
  final String? nomCampagne; // Joigné depuis la table campagnes

  Fuite({
    required this.id,
    required this.campagneId,
    this.numeroTag,
    required this.dateDetection,
    required this.statut,
    this.pressionBar,
    this.diametreOrifice,
    this.coutAnnuelEstime,
    this.typeVapeur,
    this.gpsLatitude,
    this.gpsLongitude,
    this.zone,
    this.description,
    this.nomCampagne,
  });

  factory Fuite.fromMap(Map<String, dynamic> map) {
    return Fuite(
      id: (map['id'] as num?)?.toInt() ?? 0,
      campagneId: (map['campagne_id'] as num?)?.toInt() ?? 0,
      numeroTag: map['numero_tag'] as String?,
      dateDetection: (map['date_detection'] as String?) ?? '',
      statut: (map['statut'] as String?) ?? 'A_REPARER',
      pressionBar: (map['pression_bar'] as num?)?.toDouble(),
      diametreOrifice: (map['diametre_orifice'] as num?)?.toDouble(),
      coutAnnuelEstime: (map['cout_annuel_estime'] as num?)?.toDouble(),
      typeVapeur: map['type_vapeur'] as String?,
      gpsLatitude: (map['gps_latitude'] as num?)?.toDouble(),
      gpsLongitude: (map['gps_longitude'] as num?)?.toDouble(),
      zone: map['zone'] as String?,
      description: map['description'] as String?,
      nomCampagne: map['nom_campagne'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campagne_id': campagneId,
      'numero_tag': numeroTag,
      'date_detection': dateDetection,
      'statut': statut,
      'pression_bar': pressionBar,
      'diametre_orifice': diametreOrifice,
      'cout_annuel_estime': coutAnnuelEstime,
      'type_vapeur': typeVapeur,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'zone': zone,
      'description': description,
    };
  }

  /// Calcule le débit estimé (kg/h) via la formule de Napier.
  double? get debitEstimeKgh {
    if (pressionBar == null || diametreOrifice == null) return null;
    return DebitService.calculerDebit(
      pressionRel: pressionBar!,
      diametreMm: diametreOrifice!,
    );
  }

  /// Statuts possibles avec leur libellé
  static const Map<String, String> statuts = {
    'A_REPARER': 'À réparer',
    'EN_COURS': 'En cours',
    'REPAREE': 'Réparée',
    'ANNULEE': 'Annulée',
  };

  /// Types de vapeur possibles
  static const Map<String, String> typesVapeur = {
    'VAPEUR_SATUREE': 'Vapeur saturée',
    'VAPEUR_SURCHAUFFEE': 'Vapeur surchauffée',
    'VAPEUR_HAUTE_PRESSION': 'Vapeur haute pression (HP)',
    'VAPEUR_BASSE_PRESSION': 'Vapeur basse pression (BP)',
    'VAPEUR_RESIDUELLE': 'Vapeur résiduelle',
  };
}
