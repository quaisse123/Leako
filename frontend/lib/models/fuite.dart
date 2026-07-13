class Fuite {
  final int id;
  final int campagneId;
  final String? numeroTag;
  final String dateDetection;
  final String statut;
  final double? pressionBar;
  final double? diametreOrifice;
  final double? coutAnnuelEstime;
  final String? typeVapeur;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? zone;
  final String? description;
  final String? campagneNom;

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
    this.campagneNom,
  });

  factory Fuite.fromJson(Map<String, dynamic> json) {
    return Fuite(
      id: json['id'] as int,
      campagneId: json['campagneId'] as int,
      numeroTag: json['numeroTag'] as String?,
      dateDetection: json['dateDetection'] as String,
      statut: json['statut'] as String,
      pressionBar: (json['pressionBar'] as num?)?.toDouble(),
      diametreOrifice: (json['diametreOrifice'] as num?)?.toDouble(),
      coutAnnuelEstime: (json['coutAnnuelEstime'] as num?)?.toDouble(),
      typeVapeur: json['typeVapeur'] as String?,
      gpsLatitude: (json['gpsLatitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gpsLongitude'] as num?)?.toDouble(),
      zone: json['zone'] as String?,
      description: json['description'] as String?,
      campagneNom: json['campagneNom'] as String?,
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
