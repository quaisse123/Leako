import 'dart:convert';
import 'api_client.dart';
import 'api_config.dart';
import 'jwt_service.dart';
import '../models/config_app.dart';

/// Récupère les paramètres globaux.
Future<ConfigApp> getParametresGlobaux() async {
  final headers = await authHeaders();
  final response = await ApiClient.instance
      .get(Uri.parse('${ApiConfig.apiBaseUrl}/parametres'), headers: headers)
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return ConfigApp.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}

/// Met à jour les paramètres globaux.
Future<ConfigApp> updateParametresGlobaux({
  required String devise,
  required double coutVapeurParTonne,
  required int heuresFonctionnementAnnuelles,
  required double facteurEmissionCO2,
  required String langue,
  required int heuresActiviteParJour,
  required int joursActiviteParAn,
  required double coutKwhDiram,
}) async {
  final headers = await authHeaders();
  final response = await ApiClient.instance
      .put(
        Uri.parse('${ApiConfig.apiBaseUrl}/parametres'),
        headers: headers,
        body: jsonEncode({
          'devise': devise,
          'coutVapeurParTonne': coutVapeurParTonne,
          'heuresFonctionnementAnnuelles': heuresFonctionnementAnnuelles,
          'facteurEmissionCO2': facteurEmissionCO2,
          'langue': langue,
          'heuresActiviteParJour': heuresActiviteParJour,
          'joursActiviteParAn': joursActiviteParAn,
          'coutKwhDiram': coutKwhDiram,
        }),
      )
      .timeout(ApiConfig.timeout);

  if (response.statusCode == 200) {
    return ConfigApp.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Erreur ${response.statusCode}: ${response.body}');
}
