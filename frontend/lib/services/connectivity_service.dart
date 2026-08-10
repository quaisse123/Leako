// 📡 ConnectivityService — Surveillance de la connexion internet
// Utilise connectivity_plus + un ping HTTP pour détecter la vraie connexion
// Singleton : une seule instance dans toute l'app

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'upload_progress_service.dart';

class ConnectivityService {
  // ── Singleton ───────────────────────────────────────────────
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  // Stream exposé pour que les widgets écoutent
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  // État interne
  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;

  // URLs fiables pour le ping
  // La 1ère est l'API backend de l'app : c'est elle qui compte vraiment.
  // Les autres servent de secours si le réseau bloque certaines domaines.
  static const List<String> _pingUrls = [
    'https://leako.quaisse.me/api',
    'https://clients3.google.com/generate_204',
    'https://www.google.com',
  ];

  /// Initialise l'écoute continue de la connexion
  Future<void> init() async {
    // Vérification initiale
    await _checkConnectivity();

    // Écoute des changements réseau (WiFi on/off, données mobiles, etc.)
    // NOTE : plus de ping périodique. La connexion n'est testée que :
    //  - lors d'un changement d'interface réseau (onConnectivityChanged)
    //  - juste avant chaque requête API (via checkNow)
    // Cela évite les faux positifs (page "Aucune connexion" affichée à tort
    // pendant une requête longue, un upload, un déverrouillage d'écran, etc.)
    _connectivity.onConnectivityChanged.listen((_) => _checkConnectivity());
  }

  /// Vérifie la connexion : interface réseau + ping HTTP
  Future<void> _checkConnectivity() async {
    // Ne PAS vérifier pendant un upload : la bande passante est saturée,
    // un ping échouerait à tort et afficherait la fausse page "Aucune
    // connexion" en plein milieu d'un envoi de vidéo.
    if (UploadProgressService.instance.isUploading) return;

    // 1. Vérifier si une interface réseau est active
    final result = await _connectivity.checkConnectivity();
    final hasNetworkInterface = !result.contains(ConnectivityResult.none);

    if (!hasNetworkInterface) {
      _updateStatus(false);
      return;
    }

    // 2. Vérifier la vraie connexion internet par ping HTTP
    final hasRealInternet = await _pingTest();
    _updateStatus(hasRealInternet);
  }

  /// Ping une URL fiable pour vérifier l'accès internet réel
  /// Une réponse HTTP (même 401/403) prouve que le réseau fonctionne.
  Future<bool> _pingTest() async {
    for (final url in _pingUrls) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 3);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        client.close();
        // Toute réponse < 500 = serveur joignable = connexion OK
        if (response.statusCode < 500) {
          return true;
        }
      } catch (_) {
        // Timeout ou erreur → essayer l'URL suivante
      }
    }
    return false;
  }

  void _updateStatus(bool connected) {
    if (_hasInternet != connected) {
      _hasInternet = connected;
      _controller.add(connected);
    }
  }

  /// Vérification ponctuelle (pour les appels API)
  Future<bool> checkNow() async {
    await _checkConnectivity();
    return _hasInternet;
  }

  /// Attend que la connexion soit rétablie.
  /// Utilisé par le wrapper HTTP : si pas de connexion, on affiche le
  /// dialogue global et on bloque la requête jusqu'au retour du réseau.
  Future<void> waitForConnection() async {
    if (_hasInternet) return;
    // Boucle : on reteste périodiquement (toutes les 2s) jusqu'au retour
    while (!_hasInternet) {
      await Future.delayed(const Duration(seconds: 2));
      await _checkConnectivity();
    }
  }

  void dispose() {
    _controller.close();
  }
}
