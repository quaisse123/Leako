import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/audio_commentaire.dart';

/// Récupère les commentaires audio d'une fuite.
Future<List<AudioCommentaire>> getAudioCommentairesByFuite(int fuiteId) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/audio-commentaires?fuiteId=$fuiteId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => AudioCommentaire.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère un commentaire audio par son ID.
Future<AudioCommentaire> getAudioCommentaireById(int id) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse('${ApiConfig.apiBaseUrl}/audio-commentaires/$id'),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return AudioCommentaire.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Crée un nouveau commentaire audio.
Future<AudioCommentaire> createAudioCommentaire({
  required String cheminFichier,
  int? dureeSecondes,
  required int fuiteId,
}) async {
  final headers = await authHeaders();
  final response = await http
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/audio-commentaires'),
        headers: headers,
        body: jsonEncode({
          'cheminFichier': cheminFichier,
          'dureeSecondes': dureeSecondes,
          'fuiteId': fuiteId,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 201) {
    return AudioCommentaire.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Supprime un commentaire audio.
Future<void> deleteAudioCommentaire(int id) async {
  final headers = await authHeaders();
  final response = await http
      .delete(
        Uri.parse('${ApiConfig.apiBaseUrl}/audio-commentaires/$id'),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 204) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}
