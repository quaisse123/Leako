import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'jwt_service.dart' as jwt;
import '../models/utilisateur.dart';

/// Enregistre un nouvel utilisateur.
/// Retourne l'utilisateur créé.
Future<Utilisateur> register({
  required String nom,
  required String email,
  required String motDePasse,
}) async {
  final response = await http
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nom,
          'email': email,
          'motDePasse': motDePasse,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 201) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final user = Utilisateur.fromJson(json);
    return user;
  } else {
    final msg = jsonDecode(response.body)['message'] as String?;
    throw Exception(msg ?? "Erreur lors de l'inscription");
  }
}

/// Connecte un utilisateur.
/// Retourne l'utilisateur connecté.
Future<Utilisateur> login({
  required String email,
  required String motDePasse,
}) async {
  final response = await http
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'motDePasse': motDePasse}),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Sauvegarder les tokens JWT
    await jwt.saveTokens(json);

    // Sauvegarder les infos utilisateur en session
    await _saveSession(
      id: int.parse(json['userId'] ?? '0'),
      nom: json['userNom'] ?? '',
      email: json['userEmail'] ?? '',
    );

    return Utilisateur(
      id: int.parse(json['userId'] ?? '0'),
      nom: json['userNom'] ?? '',
      email: json['userEmail'] ?? '',
    );
  } else {
    final errorBody = jsonDecode(response.body);
    final msg =
        errorBody['error'] as String? ?? 'Email ou mot de passe incorrect';
    throw Exception(msg);
  }
}

/// Stocke l'utilisateur dans SharedPreferences (session locale).
Future<void> _saveSession({
  required int id,
  required String nom,
  required String email,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('userId', id);
  await prefs.setString('userNom', nom);
  await prefs.setString('userEmail', email);
}

/// Récupère l'utilisateur connecté depuis SharedPreferences.
Future<Utilisateur?> getSessionUser() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt('userId');
  if (id == null) return null;
  return Utilisateur(
    id: id,
    nom: prefs.getString('userNom') ?? '',
    email: prefs.getString('userEmail') ?? '',
  );
}

/// Déconnecte l'utilisateur (efface la session locale et les tokens).
Future<void> logout() async {
  await jwt.logout();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userId');
  await prefs.remove('userNom');
  await prefs.remove('userEmail');
}
