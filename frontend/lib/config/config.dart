// ⚙️ Configuration centralisée de l'application
// Toutes les URLs et constantes sont ici, modifiables en un seul endroit.

class AppConfig {
  // ─── Backend API ───────────────────────────────────────────────
  /// 👇 Décommenter la ligne souhaitée :
  ///
  /// ☑️ VPS (production)
  static const String apiBaseUrl = 'https://leako.quaisse.me/api';

  ///
  /// ☑️ Local (développement)
  // static const String apiBaseUrl = 'http://10.0.2.2:8080/api';  // émulateur Android
  // static const String apiBaseUrl = 'http://localhost:8080/api';  // web / adb reverse
  /// ──────────────────────────────────────────────────────────────

  /// Timeout standard pour les requêtes HTTP.
  static const Duration timeout = Duration(seconds: 30);

  // ─── Utilisateur par défaut (pour le développement) ────────────
  static const int defaultUtilisateurId = 1;
}
