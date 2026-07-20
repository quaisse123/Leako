import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/projet.dart';

/// Récupère les projets de l'utilisateur (owner + membre accepté).
Future<List<Projet>> getMesProjets(int utilisateurId) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets?utilisateurId=$utilisateurId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => Projet.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère un projet par son ID.
Future<Projet> getProjetById(int projetId, int utilisateurId) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/$projetId?utilisateurId=$utilisateurId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Projet.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Crée un nouveau projet.
Future<Projet> createProjet({
  required String nom,
  String? description,
  required int createurId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/projets?createurId=$createurId'),
        headers: headers,
        body: jsonEncode({'nom': nom, 'description': description}),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 201) {
    return Projet.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Met à jour un projet.
Future<Projet> updateProjet({
  required int id,
  required String nom,
  String? description,
  required int utilisateurId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .put(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/$id?utilisateurId=$utilisateurId',
        ),
        headers: headers,
        body: jsonEncode({'nom': nom, 'description': description}),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Projet.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Supprime un projet (owner only).
Future<void> deleteProjet(int id, int utilisateurId) async {
  final headers = await authHeaders();
  final response = await http
      .delete(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/$id?utilisateurId=$utilisateurId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 204) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}

/// Invite un utilisateur dans un projet.
Future<Map<String, dynamic>> inviterMembre({
  required int projetId,
  required int utilisateurIdInvite,
  required int createurId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .post(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/$projetId/invitations?createurId=$createurId',
        ),
        headers: headers,
        body: jsonEncode({'utilisateurId': utilisateurIdInvite}),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 201) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère les invitations en attente de l'utilisateur.
Future<List<Map<String, dynamic>>> getMesInvitations(int utilisateurId) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/invitations?utilisateurId=$utilisateurId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Répond à une invitation (accepter/refuser).
Future<void> repondreInvitation({
  required int invitationId,
  required bool accepte,
  required int utilisateurId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .put(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/invitations/$invitationId?accepte=$accepte&utilisateurId=$utilisateurId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 200) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}

/// Quitter un projet (member only, pas l'owner).
Future<void> quitterProjet(int projetId, int utilisateurId) async {
  final headers = await authHeaders();
  final response = await http
      .post(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/$projetId/quitter?utilisateurId=$utilisateurId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 204) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}

/// Retirer un membre du projet (owner only).
Future<void> retirerMembre({
  required int projetId,
  required int membreId,
  required int createurId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .delete(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/$projetId/membres/$membreId?createurId=$createurId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 204) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}

/// Récupère les invitations en attente pour un projet donné.
Future<List<Map<String, dynamic>>> getInvitationsByProjet(
  int projetId,
  int utilisateurId,
) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/projets/$projetId/invitations?utilisateurId=$utilisateurId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère tous les utilisateurs (pour autocomplétion invitation).
Future<List<Map<String, dynamic>>> getAllUtilisateurs() async {
  final headers = await authHeaders();
  final response = await http
      .get(Uri.parse('${ApiConfig.apiBaseUrl}/utilisateurs'), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.cast<Map<String, dynamic>>();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}
