package com.backend.backend;

import com.backend.backend.dao.entities.*;
import com.backend.backend.dao.repositories.*;
import com.backend.backend.service.PasswordService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.util.Arrays;
import java.util.Date;

@SpringBootApplication
public class BackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

	@Bean
	CommandLineRunner initDatabase(
			UtilisateurRepository utilisateurRepository,
			CampagneRepository campagneRepository,
			FuiteRepository fuiteRepository,
			ParametreGlobalRepository parametreGlobalRepository,
			PasswordService passwordService
	) {
		return args -> {
			if (utilisateurRepository.count() > 0) {
				System.out.println("=========================================================");
				System.out.println("ℹ️ Données déjà présentes en base. Injection annulée.");
				System.out.println("=========================================================");
				return;
			}

			// =========================================================
			// 1. PARAMÈTRES GLOBAUX
			// =========================================================
			ParametreGlobal parametres = new ParametreGlobal(
				null,           // id
				"MAD",          // devise
				150.0,          // coutVapeurParTonne (MAD/tonne)
				8000,           // heuresFonctionnementAnnuelles
				0.2,            // facteurEmissionCO2 (kg CO2/kWh)
				"fr",           // langue
				24,             // heuresActiviteParJour
				365,            // joursActiviteParAn
				0.0             // coutKwhDiram
			);
			parametreGlobalRepository.save(parametres);

			// =========================================================
			// 2. UTILISATEURS
			// =========================================================
			Utilisateur marouane = new Utilisateur(
				null,
				"Marouane Quaisse",
				"marouane@gmail.com",
				passwordService.hashPassword("123")
			);
			Utilisateur ahmed = new Utilisateur(
				null,
				"Ahmed Inspecteur",
				"ahmed@ocpgroup.ma",
				passwordService.hashPassword("password123")
			);
			Utilisateur fatima = new Utilisateur(
				null,
				"Fatima Technicienne",
				"fatima@ocpgroup.ma",
				passwordService.hashPassword("password123")
			);
			marouane = utilisateurRepository.save(marouane);
			ahmed = utilisateurRepository.save(ahmed);
			fatima = utilisateurRepository.save(fatima);

			// =========================================================
			// 3. CAMPAGNES
			// =========================================================
			Campagne camp1 = new Campagne(null,
				"Inspection Jorf Lasfar T1",
				"Inspection trimestrielle des lignes de vapeur — Unité Sulfurique",
				"Jorf Lasfar - Ligne 3",
				false, new Date(), marouane, null);

			Campagne camp2 = new Campagne(null,
				"Audit Safi Complexe",
				"Audit annuel des pertes thermiques — Complexe Chimique",
				"Safi - Complexe Chimique",
				false, new Date(), ahmed, null);

			Campagne camp3 = new Campagne(null,
				"Survey Jorf Lasfar T2",
				"Campagne de détection des fuites de vapeur — Unité Acide Phosphorique",
				"Jorf Lasfar - Unité Acide",
				false, new Date(), marouane, null);

			Campagne camp4 = new Campagne(null,
				"Révision Safi Ligne Vapeur",
				"Révision complète du réseau vapeur haute pression",
				"Safi - Ligne principale HP",
				true, new Date(), fatima, null); // clôturée

			camp1 = campagneRepository.save(camp1);
			camp2 = campagneRepository.save(camp2);
			camp3 = campagneRepository.save(camp3);
			camp4 = campagneRepository.save(camp4);

			// =========================================================
			// 4. FUITS
			// =========================================================
			// --- Campagne 1 : Jorf Lasfar T1 (6 fuites) ---
			Fuite f1 = new Fuite(null, "TAG-JL-001", new Date(), StatutFuite.A_REPARER,
				10.5, 8.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.111, -8.611,
				"Jorf Lasfar - Unité Sulfurique",
				"Fuite importante sur bride de vanne V-102. Sifflement audible à 10 mètres. Perte de vapeur surchauffée continue.",
				45000.0, camp1, null, null);

			Fuite f2 = new Fuite(null, "TAG-JL-002", new Date(), StatutFuite.EN_COURS,
				5.0, 3.5, TypeVapeur.VAPEUR_SATUREE, 33.112, -8.612,
				"Jorf Lasfar - Ligne de transfert",
				"Fuite sur joint de bride B-45. Légère humidité visible. Réparation programmée pour le prochain arrêt.",
				12000.0, camp1, null, null);

			Fuite f3 = new Fuite(null, "TAG-JL-003", new Date(), StatutFuite.REPAREE,
				7.2, 5.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.115, -8.609,
				"Jorf Lasfar - Échangeur E-201",
				"Fuite sur purgeur P-12. Remplacé le 15/03/2025. Vérification OK après réparation.",
				22000.0, camp1, null, null);

			Fuite f4 = new Fuite(null, "TAG-JL-004", new Date(), StatutFuite.A_REPARER,
				12.0, 15.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.108, -8.615,
				"Jorf Lasfar - Conduite principale DN200",
				"Percement sur la conduite principale de vapeur. Zone chaude détectée à la caméra thermique. Intervention urgente requise.",
				95000.0, camp1, null, null);

			Fuite f5 = new Fuite(null, "TAG-JL-005", new Date(), StatutFuite.ANNULEE,
				3.0, 1.5, TypeVapeur.VAPEUR_SATUREE, 33.120, -8.605,
				"Jorf Lasfar - Station de décompression",
				"Fuite sur raccord capteur pression. Fausse alerte — condensation normale.",
				0.0, camp1, null, null);

			Fuite f6 = new Fuite(null, "TAG-JL-006", new Date(), StatutFuite.EN_COURS,
				8.0, 6.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.110, -8.613,
				"Jorf Lasfar - Turbine T-301",
				"Fuite au niveau du joint d'étanchéité de la turbine. Surveillance renforcée en attendant les pièces de rechange.",
				38000.0, camp1, null, null);

			// --- Campagne 2 : Safi Complexe (5 fuites) ---
			Fuite f7 = new Fuite(null, "TAG-SA-001", new Date(), StatutFuite.REPAREE,
				15.0, 12.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.266, -9.233,
				"Safi - Unité Phosphorique",
				"Purgeur P-09 réparé. Fuite sur le corps du purgeur. Soudure effectuée et test pression OK.",
				80000.0, camp2, null, null);

			Fuite f8 = new Fuite(null, "TAG-SA-002", new Date(), StatutFuite.A_REPARER,
				12.0, 10.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.267, -9.234,
				"Safi - Ligne principale",
				"Raccord R-12 à surveiller. Fuite mineure sur joint spiralé. Perte estimée à 12 tonnes/an.",
				65000.0, camp2, null, null);

			Fuite f9 = new Fuite(null, "TAG-SA-003", new Date(), StatutFuite.EN_COURS,
				6.5, 4.0, TypeVapeur.VAPEUR_SATUREE, 32.270, -9.230,
				"Safi - Réseau vapeur basse pression",
				"Fuite diffuse sur plusieurs points de la ligne BP. Investigation en cours pour localiser précisément.",
				28000.0, camp2, null, null);

			Fuite f10 = new Fuite(null, "TAG-SA-004", new Date(), StatutFuite.A_REPARER,
				9.0, 7.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.263, -9.236,
				"Safi - Sécheur S-105",
				"Fuite sur le joint du dôme du sécheur. Impact sur l'efficacité thermique du procédé.",
				52000.0, camp2, null, null);

			Fuite f11 = new Fuite(null, "TAG-SA-005", new Date(), StatutFuite.REPAREE,
				4.0, 2.0, TypeVapeur.VAPEUR_SATUREE, 32.275, -9.228,
				"Safi - Local pompes",
				"Fuite sur presse-étoupe de pompe P-401. Garniture remplacée. Opérationnel.",
				8500.0, camp2, null, null);

			// --- Campagne 3 : Jorf Lasfar T2 (4 fuites) ---
			Fuite f12 = new Fuite(null, "TAG-JL-007", new Date(), StatutFuite.A_REPARER,
				11.0, 9.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.200, -8.550,
				"Jorf Lasfar - Unité Acide Phosphorique",
				"Fuite sur vanne de régulation V-405. Érosion du siège de vanne constatée.",
				55000.0, camp3, null, null);

			Fuite f13 = new Fuite(null, "TAG-JL-008", new Date(), StatutFuite.EN_COURS,
				6.0, 4.5, TypeVapeur.VAPEUR_SATUREE, 33.205, -8.548,
				"Jorf Lasfar - Réseau BP",
				"Fuite sur bride DN80 au niveau du réchauffeur. Perte modérée. Plan d'action en cours.",
				18000.0, camp3, null, null);

			Fuite f14 = new Fuite(null, "TAG-JL-009", new Date(), StatutFuite.A_REPARER,
				14.0, 11.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.198, -8.555,
				"Jorf Lasfar - Conduite HP DN150",
				"Fuite importante sur souduure de la conduite HP. Zone dangereuse balisée. Intervention rapide nécessaire.",
				110000.0, camp3, null, null);

			Fuite f15 = new Fuite(null, "TAG-JL-010", new Date(), StatutFuite.REPAREE,
				3.5, 2.0, TypeVapeur.VAPEUR_SATUREE, 33.210, -8.545,
				"Jorf Lasfar - Aérocondenseur",
				"Fuite sur tube d'aérocondenseur. Piquage effectué. Test d'étanchéité passé.",
				15000.0, camp3, null, null);

			// --- Campagne 4 : Safi Révision (clôturée, 3 fuites toutes réparées) ---
			Fuite f16 = new Fuite(null, "TAG-SR-001", new Date(), StatutFuite.REPAREE,
				13.0, 10.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.300, -9.200,
				"Safi - Ligne principale HP",
				"Fuite sur vanne d'isolement V-601. Siège et clapet remplacés. Test OK.",
				72000.0, camp4, null, null);

			Fuite f17 = new Fuite(null, "TAG-SR-002", new Date(), StatutFuite.REPAREE,
				7.0, 5.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.305, -9.195,
				"Safi - Détenteur HP/BP",
				"Fuite interne sur le détendeur. Kit de réparation installé. Pression aval stabilisée.",
				35000.0, camp4, null, null);

			Fuite f18 = new Fuite(null, "TAG-SR-003", new Date(), StatutFuite.REPAREE,
				5.5, 3.0, TypeVapeur.VAPEUR_SATUREE, 32.310, -9.205,
				"Safi - Réseau condensation",
				"Fuite sur purgeur thermodynamique. Purgeur remplacé par modèle plus performant.",
				12000.0, camp4, null, null);

			fuiteRepository.saveAll(Arrays.asList(
				f1, f2, f3, f4, f5, f6, f7, f8, f9, f10,
				f11, f12, f13, f14, f15, f16, f17, f18
			));

			System.out.println("=========================================================");
			System.out.println("✅ Données OCP simulées injectées avec succès !");
			System.out.println("   - 1 Paramètre global");
			System.out.println("   - 3 Utilisateurs (Marouane, Ahmed, Fatima)");
			System.out.println("   - 4 Campagnes (3 actives, 1 clôturée)");
			System.out.println("   - 18 Fuites réparties sur les 4 campagnes");
			System.out.println("=========================================================");
		};
	}
}
