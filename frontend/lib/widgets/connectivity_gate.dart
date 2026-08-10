// 🚧 ConnectivityGate — Affiche un dialogue global si pas de connexion internet
// Au lieu de remplacer tout l'écran par une page pleine, on affiche une boîte
// de dialogue au-dessus de tout (avec assombrissement/flou en arrière-plan).
// - barrierDismissible: false → l'utilisateur ne peut pas fermer sans rétablir
//   la connexion (il ne peut pas retourner dans l'app).
// - Se ferme automatiquement dès que la connexion revient.
// - Bouton "Réessayer" pour retester manuellement.
// À placer tout en haut du widget tree (dans MaterialApp.builder).

import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityGate extends StatefulWidget {
  final Widget child;

  const ConnectivityGate({super.key, required this.child});

  // Clé globale du Navigator de l'app (définie dans main.dart).
  // Utilisée pour ouvrir/fermer le dialogue car ConnectivityGate est placé
  // dans MaterialApp.builder, donc AU-DESSUS du Navigator : son propre
  // context n'est pas un descendant d'un Navigator.
  static GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  bool _hasInternet = true;
  bool _checking = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    final service = ConnectivityService();
    _hasInternet = service.hasInternet;

    // Écouter les changements en temps réel
    service.onConnectivityChanged.listen((connected) {
      if (!mounted) return;
      setState(() => _hasInternet = connected);
      // Si la connexion revient, fermer le dialogue automatiquement
      if (connected && _dialogVisible) {
        _dialogVisible = false;
        ConnectivityGate.navigatorKey?.currentState?.pop();
      }
    });
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    final connected = await ConnectivityService().checkNow();
    if (!mounted) return;
    setState(() {
      _hasInternet = connected;
      _checking = false;
    });
    if (connected && _dialogVisible) {
      _dialogVisible = false;
      ConnectivityGate.navigatorKey?.currentState?.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si pas de connexion et dialogue pas encore affiché → l'afficher
    if (!_hasInternet && !_dialogVisible) {
      _dialogVisible = true;
      // Afficher après le build pour éviter les erreurs de contexte
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_dialogVisible) return;
        _showDialog();
      });
    }

    return widget.child;
  }

  void _showDialog() {
    final nav = ConnectivityGate.navigatorKey?.currentState;
    if (nav == null) return;
    showDialog(
      context: nav.context,
      barrierDismissible: false, // Ne pas fermer en tapant à côté
      barrierColor: Colors.black.withValues(alpha: 0.6), // Assombrissement
      builder: (dialogContext) => PopScope(
        canPop: false, // Empêcher la fermeture par retour système
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 44,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 24),
                // Titre
                const Text(
                  'Aucune connexion internet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 10),
                // Sous-titre
                Text(
                  'Vérifiez votre connexion Wi-Fi ou vos\ndonnées mobiles, puis réessayez.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Bouton Réessayer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _checking ? null : _retry,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
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
                      minimumSize: const Size(0, 50),
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
      ),
    );
  }
}
