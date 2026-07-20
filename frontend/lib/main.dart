import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'api/auth_api.dart' as auth_api;
import 'services/connectivity_service.dart';
import 'widgets/connectivity_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Démarrer la surveillance de la connexion internet
  await ConnectivityService().init();

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LEAKO',
      debugShowCheckedModeBanner: false,
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF6EDAA0))),
    );
  }
}
