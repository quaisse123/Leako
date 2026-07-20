// 📡 ConnectivityService — Surveillance de la connexion internet
// Utilise connectivity_plus + un ping HTTP pour détecter la vraie connexion
// Singleton : une seule instance dans toute l'app

import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  // Timer pour vérification périodique (toutes les 10s)
  Timer? _pingTimer;

  // URLs fiables pour le ping
  static const List<String> _pingUrls = [
    'https://clients3.google.com/generate_204',
    'https://www.google.com',
  ];

  /// Initialise l'écoute continue de la connexion
  Future<void> init() async {
    // Vérification initiale
    await _checkConnectivity();

    // Écoute des changements réseau (WiFi on/off, données mobiles, etc.)
    _connectivity.onConnectivityChanged.listen((_) => _checkConnectivity());

    // Ping périodique toutes les 10s pour détecter les coupures réelles
    _pingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  /// Vérifie la connexion : interface réseau + ping HTTP
  Future<void> _checkConnectivity() async {
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
  Future<bool> _pingTest() async {
    for (final url in _pingUrls) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 3);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        client.close();
        if (response.statusCode == 204 || response.statusCode == 200) {
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

  void dispose() {
    _pingTimer?.cancel();
    _controller.close();
  }
}
