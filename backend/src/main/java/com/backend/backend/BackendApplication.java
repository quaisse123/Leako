package com.backend.backend;

import com.backend.backend.dao.entities.*;
import com.backend.backend.dao.repositories.*;
import com.backend.backend.service.PasswordService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.*;

@SpringBootApplication
public class BackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

	/**
	 * Helper : crée une date à J-{daysAgo} depuis aujourd'hui (2026-07-15)
	 */
	private static Date ilYAJours(int daysAgo) {
		Calendar cal = Calendar.getInstance();
		cal.add(Calendar.DAY_OF_YEAR, -daysAgo);
		cal.set(Calendar.HOUR_OF_DAY, 8);
		cal.set(Calendar.MINUTE, 0);
		cal.set(Calendar.SECOND, 0);
		cal.set(Calendar.MILLISECOND, 0);
		return cal.getTime();
	}

	@Bean
	CommandLineRunner initDatabase(
			UtilisateurRepository utilisateurRepository,
			CampagneRepository campagneRepository,
			FuiteRepository fuiteRepository,
			ParametreGlobalRepository parametreGlobalRepository,
			ProjetRepository projetRepository,
			ProjetMembreRepository projetMembreRepository,
			PhotoRepository photoRepository,
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
			// 3. PROJET PAR DÉFAUT
			// =========================================================
			Projet projet = new Projet();
			projet.setNom("Projet OCP Vapeur");
			projet.setDescription("Projet principal de surveillance des fuites de vapeur — Jorf Lasfar & Safi");
			projet.setDateCreation(new Date());
			projet.setCreateur(marouane);
			projet = projetRepository.save(projet);

			// Ajouter les membres (Marouane owner + Ahmed & Fatima invités acceptés)
			Date maintenant = new Date();
			ProjetMembre m1 = new ProjetMembre(null, projet, marouane, StatutInvitation.ACCEPTE,
				maintenant, maintenant);
			ProjetMembre m2 = new ProjetMembre(null, projet, ahmed, StatutInvitation.ACCEPTE,
				maintenant, maintenant);
			ProjetMembre m3 = new ProjetMembre(null, projet, fatima, StatutInvitation.ACCEPTE,
				maintenant, maintenant);
			projetMembreRepository.saveAll(java.util.List.of(m1, m2, m3));

			// ═══════════════════════════════════════════════════════════════
			// 4. CAMPAGNES (dates étalées sur +12 mois, liées au projet)
			// ═══════════════════════════════════════════════════════════════
			// Campagne 1 → J-30 (dans le dernier mois)     → visible 1M/3M/6M/1Y/ALL
			// Campagne 2 → J-90  (entre 1M et 3M)          → visible 3M/6M/1Y/ALL
			// Campagne 3 → J-160 (entre 3M et 6M)          → visible 6M/1Y/ALL
			// Campagne 4 → J-300 (entre 6M et 1Y)          → visible 1Y/ALL

			Campagne camp1 = new Campagne(null,
				"Inspection Jorf Lasfar T1",
				"Inspection trimestrielle des lignes de vapeur — Unité Sulfurique",
				"Jorf Lasfar - Ligne 3",
				false, ilYAJours(30), marouane, projet, null);

			Campagne camp2 = new Campagne(null,
				"Audit Safi Complexe",
				"Audit annuel des pertes thermiques — Complexe Chimique",
				"Safi - Complexe Chimique",
				false, ilYAJours(90), ahmed, projet, null);

			Campagne camp3 = new Campagne(null,
				"Survey Jorf Lasfar T2",
				"Campagne de détection des fuites de vapeur — Unité Acide Phosphorique",
				"Jorf Lasfar - Unité Acide",
				false, ilYAJours(160), marouane, projet, null);

			Campagne camp4 = new Campagne(null,
				"Révision Safi Ligne Vapeur",
				"Révision complète du réseau vapeur haute pression",
				"Safi - Ligne principale HP",
				true, ilYAJours(300), fatima, projet, null); // clôturée

			camp1 = campagneRepository.save(camp1);
			camp2 = campagneRepository.save(camp2);
			camp3 = campagneRepository.save(camp3);
			camp4 = campagneRepository.save(camp4);

			// ═══════════════════════════════════════════════════════════════
			// 4. FUITS (dates de détection étalées)
			// ═══════════════════════════════════════════════════════════════
			//
			//   PÉRIODE      | JOURS | CAMPAGNES VISIBLES
			//   ─────────────┼───────┼──────────────────────────
			//   1M (30j)     │ 0-30  | Camp1 (6 fuites)
			//   3M (90j)     │ 0-90  | Camp1 + Camp2 (11 fuites)
			//   6M (180j)    │0-180  | Camp1 + Camp2 + Camp3 (15 fuites)
			//   1Y (365j)    │0-365  | Toutes (18 fuites)
			//   ALL          │∞      | Toutes (18 fuites)
			//
			// ═══════════════════════════════════════════════════════════════

			// ─── Campagne 1 : Jorf Lasfar T1 (J-25 à J-5) → visible 1M/3M/6M/1Y/ALL ───
			Fuite f1 = new Fuite(null, "TAG-JL-001", ilYAJours(25),
				StatutFuite.A_REPARER,
				10.5, 8.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.111, -8.611,
				"Jorf Lasfar - Unité Sulfurique",
				"Fuite importante sur bride de vanne V-102. Sifflement audible à 10 mètres. Perte de vapeur surchauffée continue.",
				45000.0, camp1, null, null, null);

			Fuite f2 = new Fuite(null, "TAG-JL-002", ilYAJours(20),
				StatutFuite.EN_COURS,
				5.0, 3.5, TypeVapeur.VAPEUR_SATUREE, 33.112, -8.612,
				"Jorf Lasfar - Ligne de transfert",
				"Fuite sur joint de bride B-45. Légère humidité visible. Réparation programmée pour le prochain arrêt.",
				12000.0, camp1, null, null, null);

			Fuite f3 = new Fuite(null, "TAG-JL-003", ilYAJours(30),
				StatutFuite.REPAREE,
				7.2, 5.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.115, -8.609,
				"Jorf Lasfar - Échangeur E-201",
				"Fuite sur purgeur P-12. Remplacé le 15/03/2025. Vérification OK après réparation.",
				22000.0, camp1, null, null, null);

			Fuite f4 = new Fuite(null, "TAG-JL-004", ilYAJours(14),
				StatutFuite.A_REPARER,
				12.0, 15.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.108, -8.615,
				"Jorf Lasfar - Conduite principale DN200",
				"Percement sur la conduite principale de vapeur. Zone chaude détectée à la caméra thermique. Intervention urgente requise.",
				95000.0, camp1, null, null, null);

			Fuite f5 = new Fuite(null, "TAG-JL-005", ilYAJours(10),
				StatutFuite.ANNULEE,
				3.0, 1.5, TypeVapeur.VAPEUR_SATUREE, 33.120, -8.605,
				"Jorf Lasfar - Station de décompression",
				"Fuite sur raccord capteur pression. Fausse alerte — condensation normale.",
				0.0, camp1, null, null, null);

			Fuite f6 = new Fuite(null, "TAG-JL-006", ilYAJours(27),
				StatutFuite.EN_COURS,
				8.0, 6.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.110, -8.613,
				"Jorf Lasfar - Turbine T-301",
				"Fuite au niveau du joint d'étanchéité de la turbine. Surveillance renforcée en attendant les pièces de rechange.",
				38000.0, camp1, null, null, null);

			// ─── Campagne 2 : Safi Complexe (J-85 à J-65) → visible 3M/6M/1Y/ALL, PAS 1M ───
			Fuite f7 = new Fuite(null, "TAG-SA-001", ilYAJours(82),
				StatutFuite.REPAREE,
				15.0, 12.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.266, -9.233,
				"Safi - Unité Phosphorique",
				"Purgeur P-09 réparé. Fuite sur le corps du purgeur. Soudure effectuée et test pression OK.",
				80000.0, camp2, null, null, null);

			Fuite f8 = new Fuite(null, "TAG-SA-002", ilYAJours(70),
				StatutFuite.A_REPARER,
				12.0, 10.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.267, -9.234,
				"Safi - Ligne principale",
				"Raccord R-12 à surveiller. Fuite mineure sur joint spiralé. Perte estimée à 12 tonnes/an.",
				65000.0, camp2, null, null, null);

			Fuite f9 = new Fuite(null, "TAG-SA-003", ilYAJours(85),
				StatutFuite.EN_COURS,
				6.5, 4.0, TypeVapeur.VAPEUR_SATUREE, 32.270, -9.230,
				"Safi - Réseau vapeur basse pression",
				"Fuite diffuse sur plusieurs points de la ligne BP. Investigation en cours pour localiser précisément.",
				28000.0, camp2, null, null, null);

			Fuite f10 = new Fuite(null, "TAG-SA-004", ilYAJours(75),
				StatutFuite.A_REPARER,
				9.0, 7.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.263, -9.236,
				"Safi - Sécheur S-105",
				"Fuite sur le joint du dôme du sécheur. Impact sur l'efficacité thermique du procédé.",
				52000.0, camp2, null, null, null);

			Fuite f11 = new Fuite(null, "TAG-SA-005", ilYAJours(78),
				StatutFuite.REPAREE,
				4.0, 2.0, TypeVapeur.VAPEUR_SATUREE, 32.275, -9.228,
				"Safi - Local pompes",
				"Fuite sur presse-étoupe de pompe P-401. Garniture remplacée. Opérationnel.",
				8500.0, camp2, null, null, null);

			// ─── Campagne 3 : Jorf Lasfar T2 (J-155 à J-140) → visible 6M/1Y/ALL, PAS 3M ───
			Fuite f12 = new Fuite(null, "TAG-JL-007", ilYAJours(145),
				StatutFuite.A_REPARER,
				11.0, 9.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.200, -8.550,
				"Jorf Lasfar - Unité Acide Phosphorique",
				"Fuite sur vanne de régulation V-405. Érosion du siège de vanne constatée.",
				55000.0, camp3, null, null, null);

			Fuite f13 = new Fuite(null, "TAG-JL-008", ilYAJours(155),
				StatutFuite.EN_COURS,
				6.0, 4.5, TypeVapeur.VAPEUR_SATUREE, 33.205, -8.548,
				"Jorf Lasfar - Réseau BP",
				"Fuite sur bride DN80 au niveau du réchauffeur. Perte modérée. Plan d'action en cours.",
				18000.0, camp3, null, null, null);

			Fuite f14 = new Fuite(null, "TAG-JL-009", ilYAJours(160),
				StatutFuite.A_REPARER,
				14.0, 11.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.198, -8.555,
				"Jorf Lasfar - Conduite HP DN150",
				"Fuite importante sur souduure de la conduite HP. Zone dangereuse balisée. Intervention rapide nécessaire.",
				110000.0, camp3, null, null, null);

			Fuite f15 = new Fuite(null, "TAG-JL-010", ilYAJours(140),
				StatutFuite.REPAREE,
				3.5, 2.0, TypeVapeur.VAPEUR_SATUREE, 33.210, -8.545,
				"Jorf Lasfar - Aérocondenseur",
				"Fuite sur tube d'aérocondenseur. Piquage effectué. Test d'étanchéité passé.",
				15000.0, camp3, null, null, null);

			// ─── Campagne 4 : Safi Révision (J-310 à J-290) → visible 1Y/ALL, PAS 6M ───
			Fuite f16 = new Fuite(null, "TAG-SR-001", ilYAJours(305),
				StatutFuite.REPAREE,
				13.0, 10.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.300, -9.200,
				"Safi - Ligne principale HP",
				"Fuite sur vanne d'isolement V-601. Siège et clapet remplacés. Test OK.",
				72000.0, camp4, null, null, null);

			Fuite f17 = new Fuite(null, "TAG-SR-002", ilYAJours(295),
				StatutFuite.REPAREE,
				7.0, 5.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.305, -9.195,
				"Safi - Détenteur HP/BP",
				"Fuite interne sur le détendeur. Kit de réparation installé. Pression aval stabilisée.",
				35000.0, camp4, null, null, null);

			Fuite f18 = new Fuite(null, "TAG-SR-003", ilYAJours(290),
				StatutFuite.REPAREE,
				5.5, 3.0, TypeVapeur.VAPEUR_SATUREE, 32.310, -9.205,
				"Safi - Réseau condensation",
				"Fuite sur purgeur thermodynamique. Purgeur remplacé par modèle plus performant.",
				12000.0, camp4, null, null, null);

			List<Fuite> fuites = fuiteRepository.saveAll(Arrays.asList(
				f1, f2, f3, f4, f5, f6, f7, f8, f9, f10,
				f11, f12, f13, f14, f15, f16, f17, f18
			));

			// ═══════════════════════════════════════════════════════════════
			// 5. INJECTION MÉDIAS (photos/vidéos aléatoires pour chaque fuite)
			// ═══════════════════════════════════════════════════════════════
			// Source : backend/Fuites Media/Images/{1..8}.jpg
			//          backend/Fuites Media/Videos/{1..8}.mp4
			// Destination : uploads/photos/ (déjà copiées)
			// Chaque fuite reçoit un mélange aléatoire de 2 à 5 médias
			// ═══════════════════════════════════════════════════════════════
			Random rand = new Random();
			List<Photo> toutesLesPhotos = new ArrayList<>();
			Path uploadPath = Paths.get("uploads/photos").toAbsolutePath().normalize();

			for (Fuite fuite : fuites) {
				int nbMedias = 2 + rand.nextInt(4); // 2 à 5 médias par fuite
				for (int i = 0; i < nbMedias; i++) {
					boolean estImage = rand.nextBoolean();
					int numFichier = 1 + rand.nextInt(8);
					String nomFichier;
					String thumbnailName;

					if (estImage) {
						nomFichier = numFichier + ".jpg";
						// Générer une vraie miniature redimensionnée (comme le fait FileStorageService)
						thumbnailName = generateThumbnail(uploadPath, nomFichier, 300);
						if (thumbnailName == null) thumbnailName = nomFichier;
					} else {
						nomFichier = numFichier + ".mp4";
						// Pour les vidéos : copier une image aléatoire comme miniature
						int thumbNum = 1 + rand.nextInt(8);
						thumbnailName = numFichier + "_thumb.jpg";
						Path sourceImage = uploadPath.resolve(thumbNum + ".jpg");
						Path thumbPath = uploadPath.resolve(thumbnailName);
						try {
							Files.copy(sourceImage, thumbPath, StandardCopyOption.REPLACE_EXISTING);
						} catch (IOException e) {
							thumbnailName = thumbNum + ".jpg"; // fallback
						}
					}

					Photo photo = new Photo();
					photo.setCheminFichier(nomFichier);
					photo.setThumbnailUrl(thumbnailName);
					photo.setDatePrise(fuite.getDateDetection());
					photo.setAnnotationsDessin(null);
					photo.setFuite(fuite);
					toutesLesPhotos.add(photo);
				}
			}
			photoRepository.saveAll(toutesLesPhotos);

			System.out.println("=========================================================");
			System.out.println("✅ Données OCP simulées injectées avec succès !");
			System.out.println("   - 1 Paramètre global");
			System.out.println("   - 3 Utilisateurs (Marouane, Ahmed, Fatima)");
			System.out.println("   - 1 Projet par défaut (OCP Vapeur) avec 3 membres");
			System.out.println("   - 4 Campagnes (3 actives, 1 clôturée) liées au projet");
			System.out.println("   - 18 Fuites réparties sur +12 mois");
			System.out.println("   - " + toutesLesPhotos.size() + " médias (photos/vidéos) injectés aléatoirement");
			System.out.println("=========================================================");
			System.out.println("📅 Aujourd'hui : 2026-07-15");
			System.out.println("   Campagne 1 (Jorf T1)    → J-30   → visible 1M/3M/6M/1Y/ALL");
			System.out.println("   Campagne 2 (Safi Audit) → J-90   → visible 3M/6M/1Y/ALL");
			System.out.println("   Campagne 3 (Jorf T2)    → J-160  → visible 6M/1Y/ALL");
			System.out.println("   Campagne 4 (Safi Révis) → J-300  → visible 1Y/ALL");
			System.out.println("=========================================================");
			System.out.println("🔑 API Projets:");
			System.out.println("   POST   /api/projets?createurId=1");
			System.out.println("   GET    /api/projets?utilisateurId=1");
			System.out.println("   POST   /api/projets/1/invitations?createurId=1");
			System.out.println("   GET    /api/projets/invitations?utilisateurId=2");
			System.out.println("   PUT    /api/projets/invitations/1?accepte=true&utilisateurId=2");
			System.out.println("   GET    /api/rapports/projet?projetId=1&periode=ALL");
			System.out.println("=========================================================");
		};
	}

	/**
	 * Génère une miniature redimensionnée pour une image (copie de FileStorageService.generateThumbnail).
	 */
	private static String generateThumbnail(Path uploadPath, String filename, int maxSize) {
		try {
			Path sourcePath = uploadPath.resolve(filename);
			BufferedImage original = ImageIO.read(sourcePath.toFile());
			if (original == null) return null;

			int width = original.getWidth();
			int height = original.getHeight();

			if (width <= maxSize && height <= maxSize) {
				return filename;
			}

			double ratio = (double) maxSize / Math.max(width, height);
			int newWidth = (int) (width * ratio);
			int newHeight = (int) (height * ratio);

			java.awt.Image scaled = original.getScaledInstance(newWidth, newHeight, java.awt.Image.SCALE_SMOOTH);
			BufferedImage thumbnail = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
			thumbnail.getGraphics().drawImage(scaled, 0, 0, null);

			int dot = filename.lastIndexOf('.');
			String thumbFilename = (dot > 0 ? filename.substring(0, dot) : filename) + "_thumb.jpg";
			Path thumbPath = uploadPath.resolve(thumbFilename);

			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			ImageIO.write(thumbnail, "JPEG", baos);
			Files.write(thumbPath, baos.toByteArray());

			return thumbFilename;
		} catch (IOException e) {
			return null;
		}
	}
}
