import 'dart:io';

class ApiConfig {
  /// URL de base de l'API backend.
  /// S'adapte automatiquement selon la plateforme :
  ///   - Émulateur Android → 10.0.2.2 (accès au host)
  ///   - Web / iOS / Desktop → localhost
  static String get apiBaseUrl {
    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 = host machine depuis l'émulateur Android
        // Pour un vrai téléphone en USB, utiliser 'adb reverse tcp:8080 tcp:8080'
        return 'http://10.0.2.2:8080/api';
      }
    } catch (_) {}
    return 'http://localhost:8080/api';
  }

  /// Timeout standard pour les requêtes HTTP.
  static const Duration timeout = Duration(seconds: 30);
}
