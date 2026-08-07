import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/photo.dart';
import '../services/upload_progress_service.dart';

/// Récupère les photos d'une fuite.
/// [limit] optionnel : limite le nombre de photos retournées.
Future<List<Photo>> getPhotosByFuite(int fuiteId, {int? limit}) async {
  final headers = await authHeaders();
  var url = '${ApiConfig.apiBaseUrl}/photos?fuiteId=$fuiteId';
  if (limit != null && limit > 0) url += '&limit=$limit';
  final response = await http
      .get(Uri.parse(url), headers: headers)
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

/// Crée une nouvelle photo (upload multipart).
/// [thumbnailPath] optionnel : chemin local vers la miniature (pour les vidéos).
/// [onProgress] optionnel : callback appelé régulièrement avec la fraction
/// (0.0 → 1.0) envoyée. Permet d'afficher une barre de progression réelle.
Future<Photo> createPhoto({
  required String cheminFichier,
  String? datePrise,
  String? annotationsDessin,
  required int fuiteId,
  String? thumbnailPath,
  void Function(double progress)? onProgress,
}) async {
  final headers = await authHeaders();
  // On enlève Content-Type pour que http package mette multipart/form-data
  headers.remove('Content-Type');

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConfig.apiBaseUrl}/photos/upload'),
  );
  request.headers.addAll(headers);
  request.fields['fuiteId'] = fuiteId.toString();
  if (datePrise != null) request.fields['datePrise'] = datePrise;
  if (annotationsDessin != null) {
    request.fields['annotationsDessin'] = annotationsDessin;
  }

  // Fichier principal avec suivi de progression réel :
  // on compte les octets lus depuis le fichier pendant l'envoi.
  final file = File(cheminFichier);
  final totalBytes = await file.length();
  var sentBytes = 0;

  if (onProgress != null && totalBytes > 0) {
    // Stream du fichier avec comptage des octets pour la progression
    final stream = file.openRead().transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) {
          sentBytes += data.length;
          onProgress((sentBytes / totalBytes).clamp(0.0, 1.0).toDouble());
          sink.add(data);
        },
      ),
    );
    request.files.add(
      http.MultipartFile(
        'file',
        stream,
        totalBytes,
        filename: file.uri.pathSegments.last,
      ),
    );
  } else {
    request.files.add(await http.MultipartFile.fromPath('file', cheminFichier));
  }

  if (thumbnailPath != null) {
    request.files.add(
      await http.MultipartFile.fromPath('thumbnail', thumbnailPath),
    );
  }

  // Marquage upload en cours → le ConnectivityService ne ping pas
  UploadProgressService.instance.beginUpload();
  try {
    final streamedResponse = await request.send().timeout(
      const Duration(minutes: 15),
    );
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201) {
      return Photo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  } finally {
    UploadProgressService.instance.endUpload();
  }
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
