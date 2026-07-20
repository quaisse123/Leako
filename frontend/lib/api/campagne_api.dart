import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/campagne.dart';

/// Récupère toutes les campagnes (par utilisateur ou par projet).
Future<List<Campagne>> getCampagnes({int? utilisateurId, int? projetId}) async {
  final headers = await authHeaders();
  String url = '${ApiConfig.apiBaseUrl}/campagnes';
  if (projetId != null) {
    url = '$url?projetId=$projetId';
  } else if (utilisateurId != null) {
    url = '$url?utilisateurId=$utilisateurId';
  }
  final response = await http
      .get(Uri.parse(url), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => Campagne.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère une campagne par son ID.
Future<Campagne> getCampagneById(int id) async {
  final headers = await authHeaders();
  final response = await http
      .get(Uri.parse('${ApiConfig.apiBaseUrl}/campagnes/$id'), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Campagne.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Crée une nouvelle campagne.
Future<Campagne> createCampagne({
  required String nom,
  String? description,
  String? zone,
  required int createurId,
  int? projetId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/campagnes'),
        headers: headers,
        body: jsonEncode({
          'nom': nom,
          'description': description,
          'zone': zone,
          'createurId': createurId,
          'projetId': projetId,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 201) {
    return Campagne.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Met à jour une campagne existante (PUT — tous les champs requis).
Future<Campagne> updateCampagne({
  required int id,
  required String nom,
  String? description,
  String? zone,
  bool? estCloturee,
  required int createurId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .put(
        Uri.parse('${ApiConfig.apiBaseUrl}/campagnes/$id'),
        headers: headers,
        body: jsonEncode({
          'nom': nom,
          'description': description,
          'zone': zone,
          'estCloturee': estCloturee,
          'createurId': createurId,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Campagne.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Met à jour partiellement une campagne (PATCH — seuls les champs fournis sont modifiés).
Future<Campagne> patchCampagne({
  required int id,
  String? nom,
  String? description,
  String? zone,
  bool? estCloturee,
}) async {
  final headers = await authHeaders();
  final body = <String, dynamic>{};
  if (nom != null) body['nom'] = nom;
  if (description != null) body['description'] = description;
  if (zone != null) body['zone'] = zone;
  if (estCloturee != null) body['estCloturee'] = estCloturee;

  final response = await http
      .patch(
        Uri.parse('${ApiConfig.apiBaseUrl}/campagnes/$id'),
        headers: headers,
        body: jsonEncode(body),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Campagne.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Supprime une campagne.
Future<void> deleteCampagne(int id) async {
  final headers = await authHeaders();
  final response = await http
      .delete(
        Uri.parse('${ApiConfig.apiBaseUrl}/campagnes/$id'),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 204) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}
