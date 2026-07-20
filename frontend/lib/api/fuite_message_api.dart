import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/fuite_message.dart';

/// Récupère tous les messages d'une fuite.
Future<List<FuiteMessage>> getMessagesByFuite(int fuiteId) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse('${ApiConfig.apiBaseUrl}/fuites/$fuiteId/messages'),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList
        .map((json) => FuiteMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Crée un message texte pour une fuite.
Future<FuiteMessage> createTextMessage({
  required int fuiteId,
  required int utilisateurId,
  required String contenuTexte,
}) async {
  final headers = await authHeaders();
  headers['Content-Type'] = 'application/json';
  final response = await http
      .post(
        Uri.parse('${ApiConfig.apiBaseUrl}/fuites/$fuiteId/messages'),
        headers: headers,
        body: jsonEncode({
          'utilisateurId': utilisateurId,
          'contenuTexte': contenuTexte,
          'fuiteId': fuiteId,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 201) {
    return FuiteMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Crée un message avec fichier audio pour une fuite.
Future<FuiteMessage> createAudioMessage({
  required int fuiteId,
  required int utilisateurId,
  String? contenuTexte,
  required File audioFile,
  int? dureeAudioSecondes,
}) async {
  final headers = await authHeaders();
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConfig.apiBaseUrl}/fuites/$fuiteId/messages/with-audio'),
  );
  request.headers.addAll(headers);
  request.fields['utilisateurId'] = utilisateurId.toString();
  request.fields['fuiteId'] = fuiteId.toString();
  if (contenuTexte != null) {
    request.fields['contenuTexte'] = contenuTexte;
  }
  if (dureeAudioSecondes != null) {
    request.fields['dureeAudioSecondes'] = dureeAudioSecondes.toString();
  }
  request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

  final streamedResponse = await request.send().timeout(ApiConfig.timeout);
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 201) {
    return FuiteMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Supprime un message.
Future<void> deleteMessage(int fuiteId, int messageId) async {
  final headers = await authHeaders();
  final response = await http
      .delete(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/fuites/$fuiteId/messages/$messageId',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode != 204) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }
}
