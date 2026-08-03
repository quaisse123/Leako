class ApiConfig {
  /// URL de base de l'API backend.
  /// ─────────────────────────────────────────────
  /// 👇 Décommenter la ligne souhaitée :
  ///
  /// ☑️ VPS (production)
  static const String apiBaseUrl = 'http://84.235.230.47:8080/api';

  ///
  /// ☑️ Local (développement)
  // static const String apiBaseUrl = 'http://10.0.2.2:8080/api';
  // static const String apiBaseUrl = 'http://localhost:8080/api';

  /// ─────────────────────────────────────────────

  /// Timeout standard pour les requêtes HTTP.
  static const Duration timeout = Duration(seconds: 30);
}
