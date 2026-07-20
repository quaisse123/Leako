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
			FuiteMessageRepository fuiteMessageRepository,
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

			// ─── Campagne 1 : "Inspection Jorf Lasfar T1" → initiales "IJL" ───
			Fuite f1 = new Fuite(null, "TAG-IJL-001", ilYAJours(25),
				StatutFuite.A_REPARER,
				10.5, 8.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.111, -8.611,
				"Jorf Lasfar - Unité Sulfurique",
				"Fuite importante sur bride de vanne V-102. Sifflement audible à 10 mètres. Perte de vapeur surchauffée continue.",
				45000.0, camp1, null, null, null);

			Fuite f2 = new Fuite(null, "TAG-IJL-002", ilYAJours(20),
				StatutFuite.EN_COURS,
				5.0, 3.5, TypeVapeur.VAPEUR_SATUREE, 33.112, -8.612,
				"Jorf Lasfar - Ligne de transfert",
				"Fuite sur joint de bride B-45. Légère humidité visible. Réparation programmée pour le prochain arrêt.",
				12000.0, camp1, null, null, null);

			Fuite f3 = new Fuite(null, "TAG-IJL-003", ilYAJours(30),
				StatutFuite.REPAREE,
				7.2, 5.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.115, -8.609,
				"Jorf Lasfar - Échangeur E-201",
				"Fuite sur purgeur P-12. Remplacé le 15/03/2025. Vérification OK après réparation.",
				22000.0, camp1, null, null, null);

			Fuite f4 = new Fuite(null, "TAG-IJL-004", ilYAJours(14),
				StatutFuite.A_REPARER,
				12.0, 15.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.108, -8.615,
				"Jorf Lasfar - Conduite principale DN200",
				"Percement sur la conduite principale de vapeur. Zone chaude détectée à la caméra thermique. Intervention urgente requise.",
				95000.0, camp1, null, null, null);

			Fuite f5 = new Fuite(null, "TAG-IJL-005", ilYAJours(10),
				StatutFuite.ANNULEE,
				3.0, 1.5, TypeVapeur.VAPEUR_SATUREE, 33.120, -8.605,
				"Jorf Lasfar - Station de décompression",
				"Fuite sur raccord capteur pression. Fausse alerte — condensation normale.",
				0.0, camp1, null, null, null);

			Fuite f6 = new Fuite(null, "TAG-IJL-006", ilYAJours(27),
				StatutFuite.EN_COURS,
				8.0, 6.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.110, -8.613,
				"Jorf Lasfar - Turbine T-301",
				"Fuite au niveau du joint d'étanchéité de la turbine. Surveillance renforcée en attendant les pièces de rechange.",
				38000.0, camp1, null, null, null);

			// ─── Campagne 2 : "Audit Safi Complexe" → initiales "ASC" ───
			Fuite f7 = new Fuite(null, "TAG-ASC-001", ilYAJours(82),
				StatutFuite.REPAREE,
				15.0, 12.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.266, -9.233,
				"Safi - Unité Phosphorique",
				"Purgeur P-09 réparé. Fuite sur le corps du purgeur. Soudure effectuée et test pression OK.",
				80000.0, camp2, null, null, null);

			Fuite f8 = new Fuite(null, "TAG-ASC-002", ilYAJours(70),
				StatutFuite.A_REPARER,
				12.0, 10.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.267, -9.234,
				"Safi - Ligne principale",
				"Raccord R-12 à surveiller. Fuite mineure sur joint spiralé. Perte estimée à 12 tonnes/an.",
				65000.0, camp2, null, null, null);

			Fuite f9 = new Fuite(null, "TAG-ASC-003", ilYAJours(85),
				StatutFuite.EN_COURS,
				6.5, 4.0, TypeVapeur.VAPEUR_SATUREE, 32.270, -9.230,
				"Safi - Réseau vapeur basse pression",
				"Fuite diffuse sur plusieurs points de la ligne BP. Investigation en cours pour localiser précisément.",
				28000.0, camp2, null, null, null);

			Fuite f10 = new Fuite(null, "TAG-ASC-004", ilYAJours(75),
				StatutFuite.A_REPARER,
				9.0, 7.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.263, -9.236,
				"Safi - Sécheur S-105",
				"Fuite sur le joint du dôme du sécheur. Impact sur l'efficacité thermique du procédé.",
				52000.0, camp2, null, null, null);

			Fuite f11 = new Fuite(null, "TAG-ASC-005", ilYAJours(78),
				StatutFuite.REPAREE,
				4.0, 2.0, TypeVapeur.VAPEUR_SATUREE, 32.275, -9.228,
				"Safi - Local pompes",
				"Fuite sur presse-étoupe de pompe P-401. Garniture remplacée. Opérationnel.",
				8500.0, camp2, null, null, null);

			// ─── Campagne 3 : "Survey Jorf Lasfar T2" → initiales "SJL" ───
			Fuite f12 = new Fuite(null, "TAG-SJL-001", ilYAJours(145),
				StatutFuite.A_REPARER,
				11.0, 9.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.200, -8.550,
				"Jorf Lasfar - Unité Acide Phosphorique",
				"Fuite sur vanne de régulation V-405. Érosion du siège de vanne constatée.",
				55000.0, camp3, null, null, null);

			Fuite f13 = new Fuite(null, "TAG-SJL-002", ilYAJours(155),
				StatutFuite.EN_COURS,
				6.0, 4.5, TypeVapeur.VAPEUR_SATUREE, 33.205, -8.548,
				"Jorf Lasfar - Réseau BP",
				"Fuite sur bride DN80 au niveau du réchauffeur. Perte modérée. Plan d'action en cours.",
				18000.0, camp3, null, null, null);

			Fuite f14 = new Fuite(null, "TAG-SJL-003", ilYAJours(160),
				StatutFuite.A_REPARER,
				14.0, 11.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 33.198, -8.555,
				"Jorf Lasfar - Conduite HP DN150",
				"Fuite importante sur souduure de la conduite HP. Zone dangereuse balisée. Intervention rapide nécessaire.",
				110000.0, camp3, null, null, null);

			Fuite f15 = new Fuite(null, "TAG-SJL-004", ilYAJours(140),
				StatutFuite.REPAREE,
				3.5, 2.0, TypeVapeur.VAPEUR_SATUREE, 33.210, -8.545,
				"Jorf Lasfar - Aérocondenseur",
				"Fuite sur tube d'aérocondenseur. Piquage effectué. Test d'étanchéité passé.",
				15000.0, camp3, null, null, null);

			// ─── Campagne 4 : "Révision Safi Ligne Vapeur" → initiales "RSL" ───
			Fuite f16 = new Fuite(null, "TAG-RSL-001", ilYAJours(305),
				StatutFuite.REPAREE,
				13.0, 10.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.300, -9.200,
				"Safi - Ligne principale HP",
				"Fuite sur vanne d'isolement V-601. Siège et clapet remplacés. Test OK.",
				72000.0, camp4, null, null, null);

			Fuite f17 = new Fuite(null, "TAG-RSL-002", ilYAJours(295),
				StatutFuite.REPAREE,
				7.0, 5.0, TypeVapeur.VAPEUR_SURCHAUFFEE, 32.305, -9.195,
				"Safi - Détenteur HP/BP",
				"Fuite interne sur le détendeur. Kit de réparation installé. Pression aval stabilisée.",
				35000.0, camp4, null, null, null);

			Fuite f18 = new Fuite(null, "TAG-RSL-003", ilYAJours(290),
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

			// ═══════════════════════════════════════════════════════════════
			// 6. CONVERSATIONS SIMULÉES AUTOUR DE CHAQUE FUITE
			// ═══════════════════════════════════════════════════════════════
			// 4 à 7 messages par fuite — discussions réalistes entre techniciens
			// ═══════════════════════════════════════════════════════════════
			List<FuiteMessage> tousLesMessages = new ArrayList<>();

			// ─── Fuite 1 (TAG-JL-001) : bride vanne V-102, sifflement audible ───
			tousLesMessages.addAll(creerMessages(f1, marouane, ahmed, fatima, Arrays.asList(
				msg(marouane, "J'ai entendu un sifflement en arrivant près de la vanne V-102. On dirait une fuite sérieuse.", -25),
				msg(ahmed,   "Je confirme, je suis sur place. Le bruit est clairement audible à plus de 10 mètres. Je vais mesurer au sonomètre.", -25),
				msg(fatima,  "Faites attention en approchant, la vapeur surchauffée peut causer des brûlures graves. Portez les EPI.", -24),
				msg(ahmed,   "Mesure prise : 95 dB à 5 mètres. Perte estimée à 10-11 tonnes/heure. Je note ça dans le rapport.", -24),
				msg(marouane, "OK, je crée le TAG et je planifie l'intervention. Il faut commander un joint spiralé Inconel.", -23),
				msg(fatima,  "Le joint Inconel 625 DN150 est en stock au magasin central. Je le réserve.", -23),
				msg(ahmed,   "Parfait. Intervention à programmer pendant le prochain arrêt programmé.", -22)
			)));

			// ─── Fuite 2 (TAG-JL-002) : joint de bride B-45, légère humidité ───
			tousLesMessages.addAll(creerMessages(f2, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "J'ai repéré une zone humide sur la bride B-45 de la ligne de transfert. Ça suinte légèrement.", -20),
				msg(marouane, "Tu penses que c'est de la vapeur ou de la condensation ?", -20),
				msg(ahmed,   "Plutôt de la vapeur saturée, j'ai senti la chaleur au dos de la main. Pas de condensation à cet endroit.", -19),
				msg(fatima,  "Si c'est de la vapeur saturée, il faut resserrer les boulons à couple. Je passe avec la clé dynamométrique.", -19),
				msg(ahmed,   "Resserrage effectué. Le suintement a diminué mais n'a pas complètement disparu.", -18),
				msg(marouane, "On le programme pour le prochain arrêt alors. On met le joint dans la liste.", -18)
			)));

			// ─── Fuite 3 (TAG-JL-003) : purgeur P-12 remplacé ───
			tousLesMessages.addAll(creerMessages(f3, marouane, ahmed, fatima, Arrays.asList(
				msg(fatima,  "Purgeur P-12 sur l'échangeur E-201 : le thermostat est mort. Je propose de le remplacer.", -30),
				msg(marouane, "Tu as la référence en stock ? C'est un purgeur thermodynamique TD42 ?", -30),
				msg(fatima,  "Oui, TD42. J'en ai un au magasin. Je commence le remplacement.", -29),
				msg(ahmed,   "Je viens te donner un coup de main. Il faut purger la ligne avant d'ouvrir.", -29),
				msg(fatima,  "Ancien purgeur déposé. Le siège est légèrement érodé, mais le nouveau corps est OK.", -28),
				msg(ahmed,   "Test d'étanchéité passé. Plus de fuite. Je mets à jour le statut.", -28),
				msg(marouane, "Parfait, belle intervention. Je clos le ticket.", -27)
			)));

			// ─── Fuite 4 (TAG-JL-004) : percement conduite DN200, urgence ───
			tousLesMessages.addAll(creerMessages(f4, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "URGENT ! Percement sur la conduite principale DN200. Zone très chaude à la caméra thermique.", -14),
				msg(marouane, "Est-ce que la ligne est balisée ? Il faut interdire l'accès immédiatement.", -14),
				msg(ahmed,   "Oui, ruban de signalisation posé. Personne ne passe à moins de 5 mètres.", -13),
				msg(fatima,  "J'arrive avec l'équipe de soudure. Il va falloir by-passer le tronçon.", -13),
				msg(marouane, "Je préviens la production pour un arrêt partiel de la ligne. Combien de temps vous estimez ?", -12),
				msg(fatima,  "2 à 3 heures si tout va bien. On prépare le by-pass et la plaque d'obturation.", -12),
				msg(ahmed,   "By-pass installé, soudure terminée. Test pression à 40 bars : OK. Plus de fuite.", -11)
			)));

			// ─── Fuite 5 (TAG-JL-005) : fausse alerte ───
			tousLesMessages.addAll(creerMessages(f5, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Signalement : léger dégagement près du capteur pression de la station de décompression.", -10),
				msg(marouane, "Tu as vérifié si c'est de la vapeur ou de la condensation ?", -10),
				msg(ahmed,   "Je viens de vérifier. C'est de la condensation normale sur le raccord. Pas de fuite.", -9),
				msg(fatima,  "Le capteur a probablement été nettoyé récemment et l'eau s'accumule sur le filetage.", -9),
				msg(marouane, "OK, je classe en annulé. Merci d'avoir vérifié.", -8)
			)));

			// ─── Fuite 6 (TAG-JL-006) : joint d'étanchéité turbine T-301 ───
			tousLesMessages.addAll(creerMessages(f6, marouane, ahmed, fatima, Arrays.asList(
				msg(fatima,  "Inspection de la turbine T-301 : le joint d'étanchéité côté HP présente une micro-fuite.", -27),
				msg(marouane, "Quelle est la tendance ? Ça empire ou c'est stable ?", -27),
				msg(fatima,  "C'est stable pour l'instant, mais il faudra le changer dans les 3 mois.", -26),
				msg(ahmed,   "Les pièces de rechange ont un délai de 6 semaines. Je les commande aujourd'hui.", -26),
				msg(marouane, "OK, commandez. En attendant, on renforce la surveillance : check hebdomadaire.", -25),
				msg(fatima,  "Noté. Je passe tous les lundis matin pour vérifier l'évolution.", -25)
			)));

			// ─── Fuite 7 (TAG-SA-001) : purgeur P-09 réparé ───
			tousLesMessages.addAll(creerMessages(f7, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Purgeur P-09 à l'unité phosphorique : fuite sur le corps du purgeur lui-même.", -82),
				msg(fatima,  "Le corps est fissuré ? Ou c'est le joint de couvercle ?", -82),
				msg(ahmed,   "Fissure sur le corps, côté sortie. Une micro-fissure de fatigue thermique.", -81),
				msg(marouane, "On peut le souder ou il faut le remplacer ?", -81),
				msg(fatima,  "Je peux le souder à l'Inconel. Je prépare le poste à souder.", -80),
				msg(ahmed,   "Soudure effectuée. Test pression à 25 bars : OK. Remis en service.", -79),
				msg(marouane, "Excellent. 80 000 MAD de perte annuelle évitée. Belle intervention !", -79)
			)));

			// ─── Fuite 8 (TAG-SA-002) : raccord R-12, joint spiralé ───
			tousLesMessages.addAll(creerMessages(f8, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Raccord R-12 sur la ligne principale : petite fuite au joint spiralé.", -70),
				msg(marouane, "Tu as une idée du débit ?", -70),
				msg(ahmed,   "Environ 12 tonnes/an. C'est mineur mais ça s'aggrave avec les cycles thermiques.", -69),
				msg(fatima,  "Je note pour le prochain arrêt. On changera le joint à ce moment-là.", -69),
				msg(marouane, "OK, on surveille. Ajoute ça dans la liste des interventions différées.", -68)
			)));

			// ─── Fuite 9 (TAG-SA-003) : fuite diffuse réseau BP ───
			tousLesMessages.addAll(creerMessages(f9, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Je détecte une fuite diffuse sur le réseau basse pression. Impossible de localiser précisément.", -85),
				msg(marouane, "Tu as essayé la caméra thermique ?", -85),
				msg(ahmed,   "Oui, mais le réseau BP est mal isolé, la chaleur se diffuse partout.", -84),
				msg(fatima,  "On pourrait faire un test d'isolement : fermer les sections une par une.", -84),
				msg(ahmed,   "Bonne idée. Je commence par la section sud demain matin.", -83),
				msg(marouane, "Tiens-moi au courant. Si on ne trouve pas, on prendra un acousticien.", -83)
			)));

			// ─── Fuite 10 (TAG-SA-004) : joint du dôme sécheur S-105 ───
			tousLesMessages.addAll(creerMessages(f10, marouane, ahmed, fatima, Arrays.asList(
				msg(fatima,  "Le joint du dôme du sécheur S-105 fuit. Ça impacte le rendement thermique.", -75),
				msg(marouane, "Quelle est la perte estimée ?", -75),
				msg(fatima,  "Environ 9 tonnes/heure. Le sécheur peine à maintenir la température.", -74),
				msg(ahmed,   "Le joint est accessible ? On peut le changer sans démonter le dôme ?", -74),
				msg(fatima,  "Oui, c'est un joint à lèvres. Je l'ai déjà changé l'année dernière.", -73),
				msg(marouane, "OK, planifie le changement cette semaine. Je priorise.", -73)
			)));

			// ─── Fuite 11 (TAG-SA-005) : presse-étoupe pompe P-401 ───
			tousLesMessages.addAll(creerMessages(f11, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Pompe P-401 au local pompes : le presse-étoupe fuit. Garniture usée.", -78),
				msg(fatima,  "Je passe la remplacer. C'est une garniture tressée graphite 12x12 ?", -78),
				msg(ahmed,   "Oui, exact. J'ai la référence dans l'armoire.", -77),
				msg(fatima,  "Garniture remplacée. Serrage progressif effectué. Plus de fuite.", -77),
				msg(marouane, "Parfait. 8 500 MAD/an de perte évitée. Bien joué.", -76)
			)));

			// ─── Fuite 12 (TAG-JL-007) : vanne de régulation V-405 ───
			tousLesMessages.addAll(creerMessages(f12, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Vanne V-405 à l'unité acide : le siège est érodé, la vanne ne ferme plus correctement.", -145),
				msg(marouane, "C'est une vanne de régulation ? Quel diamètre ?", -145),
				msg(ahmed,   "Oui, DN80. Fuite de 11 tonnes/heure à travers le siège.", -144),
				msg(fatima,  "Il faut démonter et re-usiner le siège. Je peux le faire à l'atelier.", -144),
				msg(marouane, "Combien de temps pour l'usinage ?", -143),
				msg(fatima,  "2 jours si j'ai le bon outil de coupe. Je vérifie le stock.", -143),
				msg(ahmed,   "En attendant, on by-passe la vanne pour ne pas perdre la production.", -142)
			)));

			// ─── Fuite 13 (TAG-JL-008) : bride DN80 réseau BP ───
			tousLesMessages.addAll(creerMessages(f13, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Bride DN80 au réchauffeur : fuite modérée. Perte de 6 tonnes/heure.", -155),
				msg(marouane, "C'est la bride d'entrée ou de sortie ?", -155),
				msg(ahmed,   "Côté entrée. Le joint est probablement déformé.", -154),
				msg(fatima,  "Je prépare un joint spiralé DN80 et je monte le remplacer.", -154),
				msg(ahmed,   "Joint remplacé. Resserrage en croix. Plus de fuite visible.", -153),
				msg(marouane, "OK, on laisse en observation 48h puis je valide la clôture.", -153)
			)));

			// ─── Fuite 14 (TAG-JL-009) : soudure conduite HP DN150 ───
			tousLesMessages.addAll(creerMessages(f14, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "ALERTE : Fuite importante sur soudure de la conduite HP DN150. Zone dangereuse.", -160),
				msg(marouane, "Évacuez la zone immédiatement. Je préviens la sécurité.", -160),
				msg(fatima,  "La soudure présente un craquement longitudinal de 3 cm. Perte estimée 14 t/h.", -159),
				msg(marouane, "Est-ce qu'on peut by-passer ou il faut arrêter la ligne ?", -159),
				msg(fatima,  "Arrêt nécessaire. La soudure est en zone critique. Je prépare le plan de soudure.", -158),
				msg(ahmed,   "Production prévenue. Arrêt programmé dans 2 heures. Je prépare le permis de feu.", -158),
				msg(fatima,  "Soudure réparée, contrôle radio effectué. Aucune indication. Remise en service OK.", -156)
			)));

			// ─── Fuite 15 (TAG-JL-010) : tube aérocondenseur ───
			tousLesMessages.addAll(creerMessages(f15, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Tube d'aérocondenseur percé. Petite fuite mais perte de vide.", -140),
				msg(fatima,  "Je localise le tube. C'est dans le faisceau central ?", -140),
				msg(ahmed,   "Oui, rangée 5, tube 12. Accessible par le côté.", -139),
				msg(fatima,  "Piquage effectué. Test d'étanchéité à l'hélium : OK.", -139),
				msg(marouane, "15 000 MAD/an de perte évitée. Bien joué les équipes !", -138)
			)));

			// ─── Fuite 16 (TAG-SR-001) : vanne d'isolement V-601 ───
			tousLesMessages.addAll(creerMessages(f16, marouane, ahmed, fatima, Arrays.asList(
				msg(fatima,  "Vanne V-601 sur la ligne HP : le siège est endommagé. Fuite de 13 t/h.", -305),
				msg(marouane, "C'est une vanne à opercule ?", -305),
				msg(fatima,  "Oui, DN200. On va démonter et remplacer le siège et le clapet.", -304),
				msg(ahmed,   "Je commande le kit de réparation. Délai : 2 semaines.", -304),
				msg(fatima,  "Kit reçu. Montage effectué. Test d'étanchéité : OK. Vanne opérationnelle.", -290),
				msg(marouane, "72 000 MAD/an de perte récupérée. Excellent travail.", -290)
			)));

			// ─── Fuite 17 (TAG-SR-002) : détendeur HP/BP ───
			tousLesMessages.addAll(creerMessages(f17, marouane, ahmed, fatima, Arrays.asList(
				msg(ahmed,   "Détendeur HP/BP : fuite interne. La pression aval est instable.", -295),
				msg(marouane, "Tu as essayé de régler le pilotage ?", -295),
				msg(ahmed,   "Oui, mais le clapet est usé. Il faut le changer.", -294),
				msg(fatima,  "Kit de réparation disponible au magasin. Je commence le démontage.", -294),
				msg(ahmed,   "Kit installé. Pression aval stabilisée à 8 bars. Plus de fuite.", -292),
				msg(marouane, "Parfait. 35 000 MAD/an de perte évitée.", -292)
			)));

			// ─── Fuite 18 (TAG-SR-003) : purgeur thermodynamique ───
			tousLesMessages.addAll(creerMessages(f18, marouane, ahmed, fatima, Arrays.asList(
				msg(fatima,  "Purgeur thermodynamique sur le réseau condensation : il reste ouvert en permanence.", -290),
				msg(marouane, "Donc il laisse passer de la vapeur vive ?", -290),
				msg(fatima,  "Exact. Je le remplace par un modèle plus performant, un TD42S.", -289),
				msg(ahmed,   "Bonne idée, le TD42S a une meilleure étanchéité à faible pression.", -289),
				msg(fatima,  "Purgeur remplacé. Test : cycle d'ouverture/fermeture OK. Plus de perte.", -288),
				msg(marouane, "12 000 MAD/an économisés. Simple et efficace !", -288)
			)));

			fuiteMessageRepository.saveAll(tousLesMessages);

			System.out.println("=========================================================");
			System.out.println("✅ Données OCP simulées injectées avec succès !");
			System.out.println("   - 1 Paramètre global");
			System.out.println("   - 3 Utilisateurs (Marouane, Ahmed, Fatima)");
			System.out.println("   - 1 Projet par défaut (OCP Vapeur) avec 3 membres");
			System.out.println("   - 4 Campagnes (3 actives, 1 clôturée) liées au projet");
			System.out.println("   - 18 Fuites réparties sur +12 mois");
			System.out.println("   - " + toutesLesPhotos.size() + " médias (photos/vidéos) injectés aléatoirement");
			System.out.println("   - " + tousLesMessages.size() + " messages de conversation répartis sur les 18 fuites");
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
	 * Helper : crée un message texte pour une fuite.
	 * @param auteur  l'utilisateur qui écrit
	 * @param texte   le contenu du message
	 * @param joursDecalage  nombre de jours avant aujourd'hui (négatif = dans le passé)
	 */
	private static FuiteMessage msg(Utilisateur auteur, String texte, int joursDecalage) {
		FuiteMessage m = new FuiteMessage();
		m.setUtilisateurId(auteur.getId());
		m.setContenuTexte(texte);
		m.setCheminAudio(null);
		m.setDureeAudioSecondes(null);
		m.setDateEnvoi(ilYAJours(-joursDecalage)); // ilYAJours(5) = J-5, donc -(-5)=+5 → correct
		return m;
	}

	/**
	 * Crée une liste de messages attachés à une fuite, en associant chaque message à la fuite.
	 */
	private static List<FuiteMessage> creerMessages(Fuite fuite, Utilisateur u1, Utilisateur u2, Utilisateur u3, List<FuiteMessage> messages) {
		for (FuiteMessage m : messages) {
			m.setFuite(fuite);
		}
		return messages;
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
