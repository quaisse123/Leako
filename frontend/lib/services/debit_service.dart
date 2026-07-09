// 📊 Service de calcul du débit de fuite (formule de Napier)
// Utilise les paramètres globaux pour estimer le coût annuel.

import '../models/config_app.dart';
import 'local_db_service.dart';

class DebitService {
  /// Calcule le débit massique avec la formule de Napier.
  /// [pressionRel] : pression relative lue au manomètre (bars)
  /// [diametreMm]  : diamètre estimé de l'orifice (mm)
  ///
  /// Formule : Débit (kg/h) = 0.262 × D² × P_abs
  /// avec P_abs = P_rel + 1
  static double calculerDebit({
    required double pressionRel,
    required double diametreMm,
  }) {
    final pAbs = pressionRel + 1.0;
    return 0.262 * (diametreMm * diametreMm) * pAbs;
  }

  /// Calcule le coût annuel estimé de la fuite en MAD.
  /// Utilise les paramètres globaux de l'application.
  ///
  /// [debitKgh]    : débit en kg/h
  /// [pressionRel] : pression relative (bar) pour le calcul d'enthalpie
  ///
  /// Formule :
  ///   heures_annuelles = heures_par_jour × jours_par_an
  ///   enthalpie (kWh/kg) = (2700 + pression × 8) / 3600
  ///   perte_energie_kWh = débit × enthalpie × heures_annuelles
  ///   coût_MAD = perte_energie_kWh × cout_kwh
  static Future<double> calculerCoutAnnuel({
    required double debitKgh,
    required double pressionRel,
  }) async {
    final db = LocalDbService();
    final config = await db.getConfig();

    final heuresAnnuelles =
        config.heuresActiviteParJour * config.joursActiviteParAn;

    // Enthalpie dynamique selon la pression (thermodynamique simplifiée)
    final enthalpieKwhParKg = (2700.0 + (pressionRel * 8.0)) / 3600.0;

    final perteEnergieKwh = debitKgh * enthalpieKwhParKg * heuresAnnuelles;
    return perteEnergieKwh * config.coutKwhEnDiram;
  }

  /// Calcule le coût annuel à partir d'un `ConfigApp` déjà chargé.
  static double calculerCoutAnnuelDepuisConfig({
    required double debitKgh,
    required double pressionRel,
    required ConfigApp config,
  }) {
    final heuresAnnuelles =
        config.heuresActiviteParJour * config.joursActiviteParAn;

    // Enthalpie dynamique selon la pression (thermodynamique simplifiée)
    final enthalpieKwhParKg = (2700.0 + (pressionRel * 8.0)) / 3600.0;

    final perteEnergieKwh = debitKgh * enthalpieKwhParKg * heuresAnnuelles;
    return perteEnergieKwh * config.coutKwhEnDiram;
  }

  /// Formate un nombre avec séparateur de milliers.
  static String formater(double valeur) {
    final parties = valeur.toStringAsFixed(2).split('.');
    final intPart = parties[0];
    final decPart = parties[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(intPart[i]);
    }

    return '${buffer.toString()},$decPart';
  }
}
