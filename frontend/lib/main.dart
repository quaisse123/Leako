import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    final session = await SessionService().getSession();

    if (!mounted) return;

    if (session != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            utilisateurId: session['id'] as int,
            nom: session['nom'] as String,
            email: session['email'] as String,
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
