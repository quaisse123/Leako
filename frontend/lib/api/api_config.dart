import 'dart:io';

class ApiConfig {
  /// URL de base de l'API backend.
  /// Détection automatique :
  ///   - Émulateur Android → 10.0.2.2 (accès au host)
  ///   - Téléphone physique / autre → localhost (via adb reverse)
  static String get apiBaseUrl {
    try {
      if (Platform.isAndroid) {
        // Lit les propriétés système Android pour détecter l'émulateur
        final hardware = _getAndroidProperty('ro.hardware');
        if (hardware != null &&
            (hardware.contains('qemu') ||
                hardware.contains('ranchu') ||
                hardware.contains('goldfish'))) {
          return 'http://10.0.2.2:8080/api';
        }
        return 'http://localhost:8080/api';
      }
    } catch (_) {}
    return 'http://localhost:8080/api';
  }

  /// Récupère une propriété système Android via getprop.
  /// Retourne null si la commande échoue ou si la propriété n'existe pas.
  static String? _getAndroidProperty(String prop) {
    try {
      final result = Process.runSync('getprop', [prop]);
      if (result.exitCode == 0) {
        final value = result.stdout.toString().trim();
        return value.isNotEmpty ? value : null;
      }
    } catch (_) {}
    return null;
  }

  /// Timeout standard pour les requêtes HTTP.
  static const Duration timeout = Duration(seconds: 30);
}
