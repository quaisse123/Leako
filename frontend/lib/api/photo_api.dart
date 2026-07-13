import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/photo.dart';

/// Récupère les photos d'une fuite.
Future<List<Photo>> getPhotosByFuite(int fuiteId) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse('${ApiConfig.apiBaseUrl}/photos?fuiteId=$fuiteId'),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => Photo.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère une photo par son ID.
Future<Photo> getPhotoById(int id) async {
  final headers = await authHeaders();
  final response = await http
      .get(Uri.parse('${ApiConfig.apiBaseUrl}/photos/$id'), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return Photo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Crée une nouvelle photo.
Future<Photo> createPhoto({
  required String cheminFichier,
  String? datePrise,
  String? annotationsDessin,
  required int fuiteId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/photos'),
        headers: headers,
        body: jsonEncode({
          'cheminFichier': cheminFichier,
          'datePrise': datePrise,
          'annotationsDessin': annotationsDessin,
          'fuiteId': fuiteId,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 201) {
    return Photo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Supprime une photo.
Future<void> deletePhoto(int id) async {
  final headers = await authHeaders();
  final response = await http
      .delete(Uri.parse('${ApiConfig.apiBaseUrl}/photos/$id'), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 204) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}
