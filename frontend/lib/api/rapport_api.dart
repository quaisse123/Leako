import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'jwt_service.dart';

/// Modèle local pour le rapport (DTO)
class RapportResponse {
  final String periodeLibelle;
  final String dateDebut;
  final String dateFin;

  // Top priority
  final double coutFuitesActives;
  final double economiesRealisees;

  // Nombres
  final int totalFuites;
  final Map<String, int> fuitesParCampagne;
  final Map<String, List<FuiteDetail>> fuitesDetailleesParCampagne;

  // Pertes vs Économies par campagne
  final Map<String, double> pertesParCampagne;
  final Map<String, double> economiesParCampagne;

  // Coût par statut
  final Map<String, double> coutParStatut;

  // Taux de réparation
  final double tauxReparationGlobal;
  final Map<String, double> tauxReparationParCampagne;

  // Top 5
  final List<FuiteResume> top5Actives;
  final List<FuiteResume> top5Reparees;

  // Diagrammes
  final Map<String, int> repartitionNbrCampagnes;
  final Map<String, double> repartitionPertesCampagnes;
  final Map<String, double> repartitionEconomiesCampagnes;

  RapportResponse({
    required this.periodeLibelle,
    required this.dateDebut,
    required this.dateFin,
    required this.coutFuitesActives,
    required this.economiesRealisees,
    required this.totalFuites,
    required this.fuitesParCampagne,
    required this.fuitesDetailleesParCampagne,
    required this.pertesParCampagne,
    required this.economiesParCampagne,
    required this.coutParStatut,
    required this.tauxReparationGlobal,
    required this.tauxReparationParCampagne,
    required this.top5Actives,
    required this.top5Reparees,
    required this.repartitionNbrCampagnes,
    required this.repartitionPertesCampagnes,
    required this.repartitionEconomiesCampagnes,
  });

  factory RapportResponse.fromJson(Map<String, dynamic> json) {
    return RapportResponse(
      periodeLibelle: json['periodeLibelle'] as String? ?? '',
      dateDebut: json['dateDebut'] as String? ?? '',
      dateFin: json['dateFin'] as String? ?? '',
      coutFuitesActives: (json['coutFuitesActives'] as num?)?.toDouble() ?? 0.0,
      economiesRealisees:
          (json['economiesRealisees'] as num?)?.toDouble() ?? 0.0,
      totalFuites: json['totalFuites'] as int? ?? 0,
      fuitesParCampagne: _mapStringInt(json['fuitesParCampagne']),
      fuitesDetailleesParCampagne: _mapFuiteDetails(
        json['fuitesDetailleesParCampagne'],
      ),
      pertesParCampagne: _mapStringDouble(json['pertesParCampagne']),
      economiesParCampagne: _mapStringDouble(json['economiesParCampagne']),
      coutParStatut: _mapStringDouble(json['coutParStatut']),
      tauxReparationGlobal:
          (json['tauxReparationGlobal'] as num?)?.toDouble() ?? 0.0,
      tauxReparationParCampagne: _mapStringDouble(
        json['tauxReparationParCampagne'],
      ),
      top5Actives:
          (json['top5Actives'] as List<dynamic>?)
              ?.map((e) => FuiteResume.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      top5Reparees:
          (json['top5Reparees'] as List<dynamic>?)
              ?.map((e) => FuiteResume.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      repartitionNbrCampagnes: _mapStringInt(json['repartitionNbrCampagnes']),
      repartitionPertesCampagnes: _mapStringDouble(
        json['repartitionPertesCampagnes'],
      ),
      repartitionEconomiesCampagnes: _mapStringDouble(
        json['repartitionEconomiesCampagnes'],
      ),
    );
  }

  static Map<String, int> _mapStringInt(dynamic map) {
    if (map is! Map) return {};
    return (map as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
  }

  static Map<String, double> _mapStringDouble(dynamic map) {
    if (map is! Map) return {};
    return (map as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
  }

  static Map<String, List<FuiteDetail>> _mapFuiteDetails(dynamic map) {
    if (map is! Map) return {};
    return (map as Map<String, dynamic>).map(
      (k, v) => MapEntry(
        k,
        (v as List<dynamic>)
            .map((e) => FuiteDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }
}

class FuiteResume {
  final int id;
  final String? numeroTag;
  final String campagneNom;
  final double coutAnnuelEstime;
  final String statut;

  FuiteResume({
    required this.id,
    this.numeroTag,
    required this.campagneNom,
    required this.coutAnnuelEstime,
    required this.statut,
  });

  factory FuiteResume.fromJson(Map<String, dynamic> json) {
    return FuiteResume(
      id: json['id'] as int,
      numeroTag: json['numeroTag'] as String?,
      campagneNom: json['campagneNom'] as String? ?? '',
      coutAnnuelEstime: (json['coutAnnuelEstime'] as num?)?.toDouble() ?? 0.0,
      statut: json['statut'] as String? ?? '',
    );
  }
}

class FuiteDetail {
  final String numeroTag;
  final String localisation;
  final String dateDetection;

  FuiteDetail({
    required this.numeroTag,
    required this.localisation,
    required this.dateDetection,
  });

  factory FuiteDetail.fromJson(Map<String, dynamic> json) {
    return FuiteDetail(
      numeroTag: json['numeroTag'] as String? ?? '',
      localisation: json['localisation'] as String? ?? '',
      dateDetection: json['dateDetection'] as String? ?? '',
    );
  }
}

/// Récupère le rapport depuis le backend.
Future<RapportResponse> getRapport({
  required int utilisateurId,
  String periode = 'ALL',
}) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/rapports?utilisateurId=$utilisateurId&periode=$periode',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return RapportResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Récupère le rapport centralisé pour un projet.
Future<RapportResponse> getRapportByProjet({
  required int projetId,
  String periode = 'ALL',
}) async {
  final headers = await authHeaders();
  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/rapports/projet?projetId=$projetId&periode=$periode',
        ),
        headers: headers,
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return RapportResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Retourne l'URL directe du PDF backend.
/// [metrics] : liste d'IDs de métriques à inclure (null = toutes).
String getPdfUrl({required int projetId, String periode = 'ALL', Set<String>? metrics}) {
  final params = 'projetId=$projetId&periode=$periode${_metricsParam(metrics)}';
  return '${ApiConfig.apiBaseUrl}/rapports/projet/pdf?$params';
}

/// Télécharge le PDF du rapport personnalisé pour un projet.
/// [metrics] : ensemble d'IDs de métriques à inclure (null = toutes).
Future<Uint8List> getPdfBytes({
  required int projetId,
  String periode = 'ALL',
  Set<String>? metrics,
}) async {
  final headers = await authHeaders();
  headers['Accept'] = 'application/pdf';
  final params = 'projetId=$projetId&periode=$periode${_metricsParam(metrics)}';
  final response = await http
      .get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/rapports/projet/pdf?$params',
        ),
        headers: headers,
      )
      .timeout(const Duration(seconds: 30));

  if (response.statusCode != 200) {
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }

  return response.bodyBytes;
}

/// Construit le paramètre query "&metrics=id1,id2,id3" à partir d'un Set.
/// Retourne une chaîne vide si metrics est null ou vide.
String _metricsParam(Set<String>? metrics) {
  if (metrics == null || metrics.isEmpty) return '';
  return '&metrics=${metrics.join(',')}';
}
