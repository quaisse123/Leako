package com.backend.backend;

import com.backend.backend.dao.entities.*;
import com.backend.backend.dao.repositories.*;
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
			ParametreGlobalRepository parametreGlobalRepository
	) {
		return args -> {
			if (utilisateurRepository.count() > 0) {
				System.out.println("=========================================================");
				System.out.println("ℹ️ Données déjà présentes en base. Injection annulée.");
				System.out.println("=========================================================");
				return;
			}

			// Paramètres globaux
			ParametreGlobal parametres = new ParametreGlobal(
				null, "MAD", 150.0, 8000, 0.2,
				"fr", 24, 365, 0.0
			);
			parametreGlobalRepository.save(parametres);

			// Utilisateurs
			Utilisateur user1 = new Utilisateur(null, "Ahmed Inspecteur", "ahmed@ocpgroup.ma", "password123");
			Utilisateur user2 = new Utilisateur(null, "Fatima Technicienne", "fatima@ocpgroup.ma", "password123");
			user1 = utilisateurRepository.save(user1);
			user2 = utilisateurRepository.save(user2);

			// Campagnes (avec createur = FK simple)
			Campagne camp1 = new Campagne(null, "Inspection Jorf Lasfar T1",
				"Inspection trimestrielle des lignes de vapeur", "Jorf Lasfar - Ligne 3",
				false, new Date(), user1, null);
			Campagne camp2 = new Campagne(null, "Audit Safi Complexe",
				"Audit annuel des pertes thermiques", "Safi - Complexe Chimique",
				false, new Date(), user2, null);
			camp1 = campagneRepository.save(camp1);
			camp2 = campagneRepository.save(camp2);

			// Fuites (sans temperatureC, diametreOrifice, descriptionLocalisation)
			Fuite f1 = new Fuite(null, "TAG-JL-001", new Date(), StatutFuite.A_REPARER,
				10.5, TypeVapeur.SURCHAUFFEE, 33.111, -8.611,
				"Jorf Lasfar - Unité Sulfurique",
				"Fuite importante près de la vanne V-102",
				45000.0, camp1, null, null);
			Fuite f2 = new Fuite(null, "TAG-JL-002", new Date(), StatutFuite.EN_COURS,
				5.0, TypeVapeur.SATUREE, 33.112, -8.612,
				"Jorf Lasfar - Ligne de transfert",
				"Fuite sur bride B-45",
				12000.0, camp1, null, null);
			Fuite f3 = new Fuite(null, "TAG-SA-001", new Date(), StatutFuite.REPAREE,
				15.0, TypeVapeur.SURCHAUFFEE, 32.266, -9.233,
				"Safi - Unité Phosphorique",
				"Purgeur P-09 réparé",
				80000.0, camp2, null, null);
			Fuite f4 = new Fuite(null, "TAG-SA-002", new Date(), StatutFuite.A_REPARER,
				12.0, TypeVapeur.SURCHAUFFEE, 32.267, -9.234,
				"Safi - Ligne principale",
				"Raccord R-12 à surveiller",
				65000.0, camp2, null, null);
			fuiteRepository.saveAll(Arrays.asList(f1, f2, f3, f4));

			System.out.println("=========================================================");
			System.out.println("✅ Données OCP simulées injectées avec succès !");
			System.out.println("=========================================================");
		};
	}
}
