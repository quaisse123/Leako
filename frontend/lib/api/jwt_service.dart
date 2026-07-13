import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Récupère un access token valide.
/// Si le token actuel est expiré, tente un refresh automatique.
Future<String> getValidAccessToken() async {
  var tokens = await _getTokens();
  String accessToken = tokens['accessToken'] ?? '';

  final testUrl = Uri.parse('${ApiConfig.apiBaseUrl}/jwt/ping');
  final response = await http.get(
    testUrl,
    headers: {'Authorization': 'Bearer $accessToken'},
  );

  if (response.statusCode == 200) {
    return accessToken;
  }

  if (response.statusCode == 401 || response.statusCode == 403) {
    try {
      await _refreshToken();
    } catch (_) {
      await logout();
      rethrow;
    }
    tokens = await _getTokens();
    accessToken = tokens['accessToken'] ?? '';
  }

  return accessToken;
}

/// Stocke les tokens (access + refresh) dans SharedPreferences.
Future<void> saveTokens(Map<String, dynamic> tokens) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('accessToken', tokens['accessToken'] ?? '');
  await prefs.setString('refreshToken', tokens['refreshToken'] ?? '');
}

/// Récupère les tokens stockés.
Future<Map<String, String>> _getTokens() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'accessToken': prefs.getString('accessToken') ?? '',
    'refreshToken': prefs.getString('refreshToken') ?? '',
  };
}

/// Tente de rafraîchir l'access token via le refresh token.
Future<void> _refreshToken() async {
  final tokens = await _getTokens();
  final refreshToken = tokens['refreshToken'] ?? '';

  if (refreshToken.isEmpty) {
    throw Exception('Aucun refresh token trouvé');
  }

  final url = Uri.parse('${ApiConfig.apiBaseUrl}/jwt/refresh');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refreshToken': refreshToken}),
  );

  if (response.statusCode == 200) {
    final newTokens = jsonDecode(response.body) as Map<String, dynamic>;
    await saveTokens(newTokens);
  } else if (response.statusCode == 401) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    throw Exception('Session expirée. Veuillez vous reconnecter.');
  } else {
    throw Exception('Échec du rafraîchissement du token');
  }
}

/// Supprime les tokens (déconnexion).
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('accessToken');
  await prefs.remove('refreshToken');
}

/// Vérifie si l'utilisateur est connecté.
Future<bool> isUserLoggedIn() async {
  try {
    final token = await getValidAccessToken();
    return token.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Retourne l'en-tête d'authentification à inclure dans chaque requête.
Future<Map<String, String>> authHeaders() async {
  String token;
  try {
    token = await getValidAccessToken();
  } catch (_) {
    token = '';
  }
  return {
    'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
