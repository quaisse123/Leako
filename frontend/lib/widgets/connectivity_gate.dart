// 🚧 ConnectivityGate — Bloque l'écran si pas de connexion internet
// Affiche une boîte pleine page avec bouton "Réessayer"
// À placer tout en haut du widget tree (dans MaterialApp.builder)

import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityGate extends StatefulWidget {
  final Widget child;

  const ConnectivityGate({super.key, required this.child});

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  bool _hasInternet = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final service = ConnectivityService();
    _hasInternet = service.hasInternet;

    // Écouter les changements en temps réel
    service.onConnectivityChanged.listen((connected) {
      if (mounted) setState(() => _hasInternet = connected);
    });
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    await ConnectivityService().checkNow();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 56,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 32),
                // Titre
                const Text(
                  'Aucune connexion internet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 12),
                // Sous-titre
                Text(
                  'Vérifiez votre connexion Wi-Fi ou vos\ndonnées mobiles, puis réessayez.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                // Bouton Réessayer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _checking ? null : _retry,
                    icon: _checking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      _checking ? 'Vérification…' : 'Réessayer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00875A),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
