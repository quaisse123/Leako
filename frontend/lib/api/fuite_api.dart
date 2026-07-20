import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/fuite.dart';

/// Récupère toutes les fuites d'une campagne.
Future<List<Fuite>> getFuitesByCampagne(int campagneId) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse('${ApiConfig.apiBaseUrl}/fuites?campagneId=$campagneId'),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => Fuite.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère toutes les fuites (par campagne, utilisateur ou projet).
Future<List<Fuite>> getFuites({
  int? campagneId,
  int? utilisateurId,
  int? projetId,
}) async {
  final headers = await authHeaders();
  String url = '${ApiConfig.apiBaseUrl}/fuites';
  if (projetId != null) {
    url = '$url?projetId=$projetId';
  } else if (campagneId != null) {
    url = '$url?campagneId=$campagneId';
  } else if (utilisateurId != null) {
    url = '$url?utilisateurId=$utilisateurId';
  }
  final response = await http
      .get(Uri.parse(url), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => Fuite.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère une fuite par son ID.
Future<Fuite> getFuiteById(int id) async {
  final headers = await authHeaders();
  final response = await http
      .get(Uri.parse('${ApiConfig.apiBaseUrl}/fuites/$id'), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Fuite.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Crée une nouvelle fuite.
Future<Fuite> createFuite({
  String? numeroTag,
  required String dateDetection,
  required String statut,
  double? pressionBar,
  double? diametreOrifice,
  String? typeVapeur,
  double? gpsLatitude,
  double? gpsLongitude,
  String? zone,
  String? description,
  double? coutAnnuelEstime,
  required int campagneId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/fuites'),
        headers: headers,
        body: jsonEncode({
          'numeroTag': numeroTag,
          'dateDetection': dateDetection,
          'statut': statut,
          'pressionBar': pressionBar,
          'diametreOrifice': diametreOrifice,
          'typeVapeur': typeVapeur,
          'gpsLatitude': gpsLatitude,
          'gpsLongitude': gpsLongitude,
          'zone': zone,
          'description': description,
          'coutAnnuelEstime': coutAnnuelEstime,
          'campagneId': campagneId,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 201) {
    return Fuite.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Met à jour une fuite existante.
Future<Fuite> updateFuite({
  required int id,
  String? numeroTag,
  required String dateDetection,
  required String statut,
  double? pressionBar,
  double? diametreOrifice,
  String? typeVapeur,
  double? gpsLatitude,
  double? gpsLongitude,
  String? zone,
  String? description,
  double? coutAnnuelEstime,
  required int campagneId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .put(
        Uri.parse('${ApiConfig.apiBaseUrl}/fuites/$id'),
        headers: headers,
        body: jsonEncode({
          'numeroTag': numeroTag,
          'dateDetection': dateDetection,
          'statut': statut,
          'pressionBar': pressionBar,
          'diametreOrifice': diametreOrifice,
          'typeVapeur': typeVapeur,
          'gpsLatitude': gpsLatitude,
          'gpsLongitude': gpsLongitude,
          'zone': zone,
          'description': description,
          'coutAnnuelEstime': coutAnnuelEstime,
          'campagneId': campagneId,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Fuite.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Supprime une fuite.
Future<void> deleteFuite(int id) async {
  final headers = await authHeaders();
  final response = await http
      .delete(Uri.parse('${ApiConfig.apiBaseUrl}/fuites/$id'), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 204) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}
