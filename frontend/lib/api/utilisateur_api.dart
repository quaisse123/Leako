import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/utilisateur.dart';

/// Récupère le profil de l'utilisateur connecté (via JWT).
Future<Utilisateur> getMe() async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse('${ApiConfig.apiBaseUrl}/utilisateurs/me'),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Utilisateur.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Met à jour nom / prénom / email du profil connecté.
Future<Utilisateur> updateProfil({
  required String nom,
  String? prenom,
  required String email,
}) async {
  final headers = await authHeaders();
  final response = await http
      .put(
        Uri.parse('${ApiConfig.apiBaseUrl}/utilisateurs/me'),
        headers: headers,
        body: jsonEncode({'nom': nom, 'prenom': prenom ?? '', 'email': email}),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Utilisateur.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  final msg = _extractError(response.body) ?? 'Erreur lors de la mise à jour';
  throw Exception(msg);
}

/// Change le mot de passe de l'utilisateur connecté.
Future<void> changerMotDePasse({
  required String motDePasseActuel,
  required String nouveauMotDePasse,
}) async {
  final headers = await authHeaders();
  final response = await http
      .put(
        Uri.parse('${ApiConfig.apiBaseUrl}/utilisateurs/me/mot-de-passe'),
        headers: headers,
        body: jsonEncode({
          'motDePasseActuel': motDePasseActuel,
          'nouveauMotDePasse': nouveauMotDePasse,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return;
  }

  final msg =
      _extractError(response.body) ??
      'Erreur lors du changement de mot de passe';
  throw Exception(msg);
}

/// Extrait le message d'erreur du corps JSON de réponse (champ "error").
String? _extractError(String body) {
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['error'] as String?;
  } catch (_) {
    return null;
  }
}
