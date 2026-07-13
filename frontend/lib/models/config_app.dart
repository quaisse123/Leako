class ConfigApp {
  final int id;
  final String langue;
  final int heuresActiviteParJour;
  final int joursActiviteParAn;
  final double coutKwhDiram;

  ConfigApp({
    this.id = 1,
    this.langue = 'fr',
    this.heuresActiviteParJour = 24,
    this.joursActiviteParAn = 365,
    this.coutKwhDiram = 0.0,
  });

  factory ConfigApp.fromJson(Map<String, dynamic> json) {
    return ConfigApp(
      id: json['id'] as int? ?? 1,
      langue: json['langue'] as String? ?? 'fr',
      heuresActiviteParJour: json['heuresActiviteParJour'] as int? ?? 24,
      joursActiviteParAn: json['joursActiviteParAn'] as int? ?? 365,
      coutKwhDiram: (json['coutKwhDiram'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
