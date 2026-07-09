// 🌐 Service API
// C'est le seul endroit qui fait des appels HTTP vers le backend.
// Toutes les autres parties du code passent par ce service.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/campagne.dart';

class ApiService {
  /// Récupère toutes les campagnes d'un utilisateur
  /// [utilisateurId] = l'ID de l'utilisateur connecté
  Future<List<Campagne>> getCampagnes(int utilisateurId) async {
    // 1. On appelle le backend : GET /api/campagnes?utilisateurId=1
    final response = await http.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/campagnes?utilisateurId=$utilisateurId',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    // 2. Si le backend répond OK (200), on transforme le JSON en liste de Campagne
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => Campagne.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      // 3. Si erreur, on lance une exception
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }
}
