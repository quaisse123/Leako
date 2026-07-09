/// Configuration globale de l'application OCP.
/// Stockée dans la table `parametres_globaux`.
class ConfigApp {
  final int id;
  final String langue; // 'fr', 'en', 'ar'
  final int heuresActiviteParJour; // 24 par défaut
  final int joursActiviteParAn; // 365 par défaut
  final double coutKwhEnDiram; // Coût par kWh en MAD

  ConfigApp({
    this.id = 1,
    this.langue = 'fr',
    this.heuresActiviteParJour = 24,
    this.joursActiviteParAn = 365,
    this.coutKwhEnDiram = 0.0,
  });

  factory ConfigApp.fromMap(Map<String, dynamic> map) {
    return ConfigApp(
      id: map['id'] as int? ?? 1,
      langue: map['langue'] as String? ?? 'fr',
      heuresActiviteParJour: map['heures_activite_par_jour'] as int? ?? 24,
      joursActiviteParAn: map['jours_activite_par_an'] as int? ?? 365,
      coutKwhEnDiram: (map['cout_kwh_diram'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'langue': langue,
      'heures_activite_par_jour': heuresActiviteParJour,
      'jours_activite_par_an': joursActiviteParAn,
      'cout_kwh_diram': coutKwhEnDiram,
    };
  }
}
