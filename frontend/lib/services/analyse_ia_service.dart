// Service d'appel à l'API IA via Spring Boot (backend).
// Envoie les photoIds au lieu des fichiers bruts — Spring Boot se charge
// de charger les médias depuis le disque et d'appeler OpenRouter.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/api_config.dart';

// ---------------------------------------------------------------------------
// Modèle de retour
// ---------------------------------------------------------------------------

/// Analyse d'un seul média par l'IA.
class AnalyseIAMedia {
  final String fichier;
  final bool fuiteVisible;
  final String typeFuite; // "liquide" | "vapeur" | "mixte"
  final String intensite; // "faible" | "moyenne" | "forte"
  final double diametreEstimeMm;
  final double confiance;
  final String observation;

  const AnalyseIAMedia({
    required this.fichier,
    required this.fuiteVisible,
    required this.typeFuite,
    required this.intensite,
    required this.diametreEstimeMm,
    required this.confiance,
    required this.observation,
  });

  factory AnalyseIAMedia.fromJson(Map<String, dynamic> json) {
    return AnalyseIAMedia(
      fichier: json['fichier'] as String? ?? '',
      fuiteVisible: json['fuiteVisible'] as bool? ?? true,
      typeFuite: json['typeFuite'] as String? ?? 'vapeur',
      intensite: json['intensite'] as String? ?? 'moyenne',
      diametreEstimeMm: (json['diametreEstimeMm'] as num?)?.toDouble() ?? 5.0,
      confiance: (json['confiance'] as num?)?.toDouble() ?? 0.5,
      observation: json['observation'] as String? ?? '',
    );
  }
}

/// Résumé global calculé par l'API.
class AnalyseIAResume {
  final String typeFuite;
  final String intensite;
  final double diametreMoyenMm;
  final double confianceMoyenne;

  const AnalyseIAResume({
    required this.typeFuite,
    required this.intensite,
    required this.diametreMoyenMm,
    required this.confianceMoyenne,
  });

  factory AnalyseIAResume.fromJson(Map<String, dynamic> json) {
    return AnalyseIAResume(
      typeFuite: json['typeFuite'] as String? ?? 'inconnu',
      intensite: json['intensite'] as String? ?? 'inconnue',
      diametreMoyenMm: (json['diametreMoyenMm'] as num?)?.toDouble() ?? 5.0,
      confianceMoyenne: (json['confianceMoyenne'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Réponse complète de l'API.
class AnalyseIAReponse {
  final bool success;
  final List<AnalyseIAMedia> resultats;
  final AnalyseIAResume resume;
  final String? synthese;
  final List<String> warnings;

  const AnalyseIAReponse({
    required this.success,
    required this.resultats,
    required this.resume,
    this.synthese,
    this.warnings = const [],
  });

  factory AnalyseIAReponse.fromJson(Map<String, dynamic> json) {
    final resultatsList =
        (json['resultats'] as List<dynamic>?)
            ?.map((e) => AnalyseIAMedia.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final resumeJson = json['resume'] as Map<String, dynamic>? ?? {};
    final warningsList =
        (json['warnings'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return AnalyseIAReponse(
      success: json['success'] as bool? ?? true,
      resultats: resultatsList,
      resume: AnalyseIAResume.fromJson(resumeJson),
      synthese: json['synthese'] as String?,
      warnings: warningsList,
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class AnalyseIAService {
  /// URL du backend Spring Boot (défini dans ApiConfig).
  static String get _baseUrl => '${ApiConfig.apiBaseUrl}/analyse-ia';

  /// Timeout long car l'IA peut prendre du temps.
  static const Duration _timeout = Duration(seconds: 180);

  // ── Appel principal ───────────────────────────────────

  /// Envoie le [fuiteId] à l'API d'analyse IA via Spring Boot.
  ///
  /// Spring Boot charge toutes les photos de la fuite depuis le disque.
  /// Retourne [AnalyseIAReponse] ou lève une exception avec un message clair.
  static Future<AnalyseIAReponse> analyserParFuite({
    required int fuiteId,
  }) async {
    final uri = Uri.parse(_baseUrl);
    final body = jsonEncode({'fuiteId': fuiteId});

    try {
      final response = await ApiClient.instance
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_timeout);

      // ── Gestion des erreurs HTTP ──
      if (response.statusCode != 200) {
        String message = _erreurDepuisStatut(response.statusCode);

        if (response.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map && decoded.containsKey('message')) {
              message = decoded['message'].toString();
            }
          } catch (_) {}
        }

        throw AnalyseIAException(message);
      }

      // ── Parsing ──
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalyseIAReponse.fromJson(decoded);
    } on http.ClientException catch (_) {
      throw AnalyseIAException(
        'Impossible de contacter le serveur ($_baseUrl). '
        'Vérifie que Spring Boot est lancé sur le port 8080.',
      );
    } on AnalyseIAException {
      rethrow;
    } catch (e) {
      throw AnalyseIAException(
        'Erreur inattendue : ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}',
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────

  /// Charge la dernière analyse IA persistée pour une fuite (si elle existe
  /// et si les photos n'ont pas changé depuis l'analyse).
  ///
  /// Retourne `null` si aucune analyse à jour (404/204) ou en cas d'erreur.
  static Future<AnalyseIAReponse?> getDerniereAnalyse({
    required int fuiteId,
  }) async {
    final uri = Uri.parse('$_baseUrl/$fuiteId');

    try {
      final response = await ApiClient.instance.get(uri).timeout(_timeout);

      // 204 = aucune analyse à jour pour cette fuite
      if (response.statusCode == 204 || response.statusCode == 404) {
        debugPrint(
          '🔍 [DEBUG] getDerniereAnalyse fuite#$fuiteId → '
          '${response.statusCode} (aucune analyse à jour)',
        );
        return null;
      }
      if (response.statusCode != 200) {
        debugPrint(
          '🔍 [DEBUG] getDerniereAnalyse fuite#$fuiteId → '
          'statut inattendu ${response.statusCode}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint(
        '🔍 [DEBUG] getDerniereAnalyse fuite#$fuiteId → '
        '200 OK, analyse persistée trouvée',
      );
      return AnalyseIAReponse.fromJson(decoded);
    } catch (e) {
      debugPrint(
        '🔍 [DEBUG] getDerniereAnalyse fuite#$fuiteId → '
        'erreur: $e',
      );
      // Silencieux : l'absence d'analyse n'est pas une erreur bloquante.
      return null;
    }
  }

  static String _erreurDepuisStatut(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide. Vérifie que les photos existent.';
      case 429:
        return 'Service IA surchargé. Attends quelques secondes et réessaie.';
      case 502:
        return 'L\'IA n\'a pas pu analyser les fichiers.';
      case 503:
        return 'Service IA indisponible. Vérifie ta connexion Internet.';
      case 504:
        return 'L\'analyse a pris trop de temps. Réessaie avec moins de photos.';
      default:
        return 'Erreur du serveur ($statusCode). Réessaie dans un instant.';
    }
  }
}

/// Exception personnalisée avec message user-friendly.
class AnalyseIAException implements Exception {
  final String message;
  const AnalyseIAException(this.message);

  @override
  String toString() => message;
}
