import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'api/auth_api.dart' as auth_api;
import 'services/connectivity_service.dart';
import 'widgets/connectivity_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Démarrer la surveillance de la connexion internet.
  // Ne PAS bloquer le lancement : si le premier ping échoue (réseau pas
  // encore prêt au boot), l'app démarre quand même et le gate se corrige
  // tout seul dès que la connexion revient.
  unawaited(ConnectivityService().init());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LeakoApp());
}

class LeakoApp extends StatelessWidget {
  const LeakoApp({super.key});

  static const Color mintGreen = Color(0xFF6EDAA0);
  static const Color bgDark = Color(0xFF0D1B14);

  // Clé globale du Navigator, partagée avec ConnectivityGate pour pouvoir
  // ouvrir/fermer le dialogue de connexion (qui est placé au-dessus du
  // Navigator via MaterialApp.builder).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Exposer la clé au ConnectivityGate
    ConnectivityGate.navigatorKey = navigatorKey;
    return MaterialApp(
      title: 'LEAKO',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      builder: (context, child) => ConnectivityGate(child: child!),
      home: const _SplashChecker(),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: mintGreen,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
    );
  }
}

/// Vérifie si une session existe au démarrage
/// - Si oui → va directement au HomePage
/// - Si non → affiche la LoginPage
class _SplashChecker extends StatefulWidget {
  const _SplashChecker();

  @override
  State<_SplashChecker> createState() => _SplashCheckerState();
}

class _SplashCheckerState extends State<_SplashChecker> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await auth_api.getSessionUser();

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            utilisateurId: user.id,
            nom: user.nom,
            prenom: user.prenom,
            email: user.email,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écran de chargement rapide pendant la vérification
    // Fond blanc avec le logo (pas le thème sombre global)
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 96,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF00875A),
                  size: 72,
                );
              },
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF00875A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
