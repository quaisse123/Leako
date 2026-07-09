import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';
import '../models/config_app.dart';

/// Service de base de données SQLite locale.
/// Schéma relationnel complet adapté du backend, sans le multi-utilisateur.
/// Chaque technicien a son propre fichier DB (ou on filtre par utilisateur_id).
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._();
  factory LocalDbService() => _instance;
  LocalDbService._();

  Database? _db;

  /// Dossier de stockage des photos
  Future<Directory> getPhotosDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'leaks_survey.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE fuites ADD COLUMN zone TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE fuites ADD COLUMN description TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('''
            ALTER TABLE fuites ADD COLUMN cout_annuel_estime REAL
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            ALTER TABLE fuites ADD COLUMN diametre_orifice REAL
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            ALTER TABLE parametres_globaux ADD COLUMN langue TEXT NOT NULL DEFAULT 'fr'
          ''');
          await db.execute('''
            ALTER TABLE parametres_globaux ADD COLUMN heures_activite_par_jour INTEGER NOT NULL DEFAULT 24
          ''');
          await db.execute('''
            ALTER TABLE parametres_globaux ADD COLUMN jours_activite_par_an INTEGER NOT NULL DEFAULT 365
          ''');
          await db.execute('''
            ALTER TABLE parametres_globaux ADD COLUMN cout_kwh_diram REAL NOT NULL DEFAULT 0.0
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // ── Utilisateurs (login local) ──
    await db.execute('''
      CREATE TABLE utilisateurs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        mot_de_passe TEXT NOT NULL
      )
    ''');

    // ── Campagnes ──
    await db.execute('''
      CREATE TABLE campagnes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT,
        zone TEXT,
        est_cloturee INTEGER NOT NULL DEFAULT 0,
        date_creation TEXT NOT NULL,
        utilisateur_id INTEGER NOT NULL,
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
      )
    ''');

    // ── Fuites ──
    await db.execute('''
      CREATE TABLE fuites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campagne_id INTEGER NOT NULL,
        numero_tag TEXT,
        date_detection TEXT NOT NULL,
        statut TEXT NOT NULL DEFAULT 'A_REPARER',
        pression_bar REAL,
        type_vapeur TEXT,
        gps_latitude REAL,
        gps_longitude REAL,
        zone TEXT,
        description TEXT,
        cout_annuel_estime REAL,
        FOREIGN KEY (campagne_id) REFERENCES campagnes(id) ON DELETE CASCADE
      )
    ''');

    // ── Photos ──
    await db.execute('''
      CREATE TABLE photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fuite_id INTEGER NOT NULL,
        chemin_fichier TEXT NOT NULL,
        date_prise TEXT,
        annotations_dessin TEXT,
        FOREIGN KEY (fuite_id) REFERENCES fuites(id) ON DELETE CASCADE
      )
    ''');

    // ── Audio Commentaires ──
    await db.execute('''
      CREATE TABLE audio_commentaires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fuite_id INTEGER NOT NULL,
        chemin_fichier TEXT NOT NULL,
        duree_secondes INTEGER,
        date_enregistrement TEXT,
        transcription TEXT,
        FOREIGN KEY (fuite_id) REFERENCES fuites(id) ON DELETE CASCADE
      )
    ''');

    // ── Paramètres globaux (préférences du technicien) ──
    await db.execute('''
      CREATE TABLE parametres_globaux (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        devise TEXT NOT NULL DEFAULT 'MAD',
        cout_vapeur_par_tonne REAL,
        heures_fonctionnement_annuelles INTEGER,
        facteur_emission_co2 REAL,
        langue TEXT NOT NULL DEFAULT 'fr',
        heures_activite_par_jour INTEGER NOT NULL DEFAULT 24,
        jours_activite_par_an INTEGER NOT NULL DEFAULT 365,
        cout_kwh_diram REAL NOT NULL DEFAULT 0.0
      )
    ''');
  }

  // ═══════════════════════════════════════════════
  // 🔐 UTILISATEURS
  // ═══════════════════════════════════════════════

  /// Crée un nouveau compte technicien.
  Future<int> creerUtilisateur(
    String nom,
    String email,
    String motDePasse,
  ) async {
    final db = await database;
    return await db.insert('utilisateurs', {
      'nom': nom,
      'email': email,
      'mot_de_passe': motDePasse,
    });
  }

  /// Vérifie les credentials et retourne l'utilisateur si OK.
  Future<Map<String, dynamic>?> connexion(
    String email,
    String motDePasse,
  ) async {
    final db = await database;
    final result = await db.query(
      'utilisateurs',
      where: 'email = ? AND mot_de_passe = ?',
      whereArgs: [email, motDePasse],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Récupère un utilisateur par son ID.
  Future<Map<String, dynamic>?> getUtilisateur(int id) async {
    final db = await database;
    final result = await db.query(
      'utilisateurs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  // ═══════════════════════════════════════════════
  // 📋 CAMPAGNES
  // ═══════════════════════════════════════════════

  /// Toutes les campagnes d'un utilisateur.
  Future<List<Map<String, dynamic>>> getCampagnes(int utilisateurId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT c.*, COUNT(f.id) AS nombre_fuites
      FROM campagnes c
      LEFT JOIN fuites f ON f.campagne_id = c.id
      WHERE c.utilisateur_id = ?
      GROUP BY c.id
      ORDER BY c.date_creation DESC
    ''',
      [utilisateurId],
    );
  }

  /// Une campagne par son ID.
  Future<Map<String, dynamic>?> getCampagne(int id) async {
    final db = await database;
    final result = await db.query(
      'campagnes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Crée une nouvelle campagne.
  Future<int> creerCampagne(Map<String, dynamic> campagne) async {
    final db = await database;
    return await db.insert('campagnes', campagne);
  }

  /// Met à jour une campagne.
  Future<void> updateCampagne(int id, Map<String, dynamic> valeurs) async {
    final db = await database;
    await db.update('campagnes', valeurs, where: 'id = ?', whereArgs: [id]);
  }

  /// Supprime une campagne (CASCADE supprime les fuites, photos, etc.)
  Future<void> supprimerCampagne(int id) async {
    final db = await database;
    await db.delete('campagnes', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  // 💧 FUITES
  // ═══════════════════════════════════════════════

  /// Toutes les fuites d'une campagne.
  Future<List<Map<String, dynamic>>> getFuites(int campagneId) async {
    final db = await database;
    return await db.query(
      'fuites',
      where: 'campagne_id = ?',
      whereArgs: [campagneId],
      orderBy: 'date_detection DESC',
    );
  }

  /// Toutes les fuites d'un utilisateur (avec nom de campagne).
  Future<List<Map<String, dynamic>>> getFuitesUtilisateur(
    int utilisateurId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT f.*, c.nom AS nom_campagne
      FROM fuites f
      INNER JOIN campagnes c ON f.campagne_id = c.id
      WHERE c.utilisateur_id = ?
      ORDER BY f.date_detection DESC
    ''',
      [utilisateurId],
    );
  }

  /// Une fuite par son ID.
  Future<Map<String, dynamic>?> getFuite(int id) async {
    final db = await database;
    final result = await db.query('fuites', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Crée une nouvelle fuite.
  Future<int> creerFuite(Map<String, dynamic> fuite) async {
    final db = await database;
    return await db.insert('fuites', fuite);
  }

  /// Met à jour une fuite.
  Future<void> updateFuite(int id, Map<String, dynamic> valeurs) async {
    final db = await database;
    await db.update('fuites', valeurs, where: 'id = ?', whereArgs: [id]);
  }

  /// Supprime une fuite (CASCADE supprime les photos et audios liés).
  Future<void> supprimerFuite(int id) async {
    final db = await database;
    await db.delete('fuites', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  // 📸 PHOTOS
  // ═══════════════════════════════════════════════

  /// Toutes les photos d'une fuite.
  Future<List<Photo>> getPhotos(int fuiteId) async {
    final db = await database;
    final rows = await db.query(
      'photos',
      where: 'fuite_id = ?',
      whereArgs: [fuiteId],
      orderBy: 'date_prise ASC',
    );
    return rows.map((row) => Photo.fromMap(row)).toList();
  }

  /// Ajoute une photo.
  Future<int> ajouterPhoto(Map<String, dynamic> photo) async {
    final db = await database;
    return await db.insert('photos', photo);
  }

  /// Supprime une photo.
  Future<void> supprimerPhoto(int id) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  // 🎙️ AUDIO COMMENTAIRES
  // ═══════════════════════════════════════════════

  /// Tous les audios d'une fuite.
  Future<List<Map<String, dynamic>>> getAudios(int fuiteId) async {
    final db = await database;
    return await db.query(
      'audio_commentaires',
      where: 'fuite_id = ?',
      whereArgs: [fuiteId],
      orderBy: 'date_enregistrement ASC',
    );
  }

  /// Ajoute un audio.
  Future<int> ajouterAudio(Map<String, dynamic> audio) async {
    final db = await database;
    return await db.insert('audio_commentaires', audio);
  }

  /// Supprime un audio.
  Future<void> supprimerAudio(int id) async {
    final db = await database;
    await db.delete('audio_commentaires', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════
  // ⚙️ PARAMÈTRES GLOBAUX
  // ═══════════════════════════════════════════════

  /// Récupère les paramètres (ou les crée par défaut).
  Future<Map<String, dynamic>> getParametres() async {
    final db = await database;
    final result = await db.query('parametres_globaux', limit: 1);
    if (result.isNotEmpty) return result.first;
    // Crée les paramètres par défaut
    await db.insert('parametres_globaux', {
      'devise': 'MAD',
      'cout_vapeur_par_tonne': null,
      'heures_fonctionnement_annuelles': null,
      'facteur_emission_co2': null,
    });
    return (await db.query('parametres_globaux', limit: 1)).first;
  }

  /// Met à jour les paramètres.
  Future<void> updateParametres(Map<String, dynamic> valeurs) async {
    final db = await database;
    await db.update(
      'parametres_globaux',
      valeurs,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ═══════════════════════════════════════════════
  // 🧹 MÉTHODES UTILITAIRES
  // ═══════════════════════════════════════════════

  /// Statistiques globales pour le dashboard d'un utilisateur.
  Future<Map<String, dynamic>> getStatistiquesDashboard(
    int utilisateurId,
  ) async {
    final db = await database;
    final anneeCourante = DateTime.now().year.toString(); // ex: "2026"

    // Compter par statut (uniquement fuites de l'année courante)
    final countResult = await db.rawQuery(
      '''
      SELECT f.statut, COUNT(*) as total
      FROM fuites f
      INNER JOIN campagnes c ON f.campagne_id = c.id
      WHERE c.utilisateur_id = ?
        AND substr(f.date_detection, 1, 4) = ?
      GROUP BY f.statut
    ''',
      [utilisateurId, anneeCourante],
    );

    int aReparer = 0, enCours = 0, reparees = 0, annulees = 0;
    for (final row in countResult) {
      final statut = row['statut'] as String;
      final total = row['total'] as int;
      switch (statut) {
        case 'A_REPARER':
          aReparer = total;
          break;
        case 'EN_COURS':
          enCours = total;
          break;
        case 'REPAREE':
          reparees = total;
          break;
        case 'ANNULEE':
          annulees = total;
          break;
      }
    }
    final totalFuites = aReparer + enCours + reparees + annulees;

    // Somme des coûts des fuites actives (A_REPARER + EN_COURS) — année courante
    final sommeActive = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(f.cout_annuel_estime), 0) as total
      FROM fuites f
      INNER JOIN campagnes c ON f.campagne_id = c.id
      WHERE c.utilisateur_id = ?
        AND f.statut IN ('A_REPARER', 'EN_COURS')
        AND substr(f.date_detection, 1, 4) = ?
    ''',
      [utilisateurId, anneeCourante],
    );

    // Somme des coûts des fuites réparées (économies réalisées) — année courante
    final sommeReparees = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(f.cout_annuel_estime), 0) as total
      FROM fuites f
      INNER JOIN campagnes c ON f.campagne_id = c.id
      WHERE c.utilisateur_id = ?
        AND f.statut = 'REPAREE'
        AND substr(f.date_detection, 1, 4) = ?
    ''',
      [utilisateurId, anneeCourante],
    );

    return {
      'total_fuites': totalFuites,
      'a_reparer': aReparer,
      'en_cours': enCours,
      'reparees': reparees,
      'annulees': annulees,
      'somme_couts_actives_kdh':
          ((sommeActive.first['total'] as num?)?.toDouble() ?? 0) / 1000,
      'somme_couts_reparees_kdh':
          ((sommeReparees.first['total'] as num?)?.toDouble() ?? 0) / 1000,
    };
  }

  /// Compte le nombre de fuites par statut pour une campagne.
  Future<Map<String, int>> compterFuitesParStatut(int campagneId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT statut, COUNT(*) as total
      FROM fuites
      WHERE campagne_id = ?
      GROUP BY statut
    ''',
      [campagneId],
    );

    final Map<String, int> compteur = {};
    for (final row in result) {
      compteur[row['statut'] as String] = row['total'] as int;
    }
    return compteur;
  }

  /// Supprime toutes les données d'un utilisateur.
  Future<void> supprimerDonneesUtilisateur(int utilisateurId) async {
    final db = await database;
    // Récupère les campagnes de l'utilisateur
    final campagnes = await db.query(
      'campagnes',
      columns: ['id'],
      where: 'utilisateur_id = ?',
      whereArgs: [utilisateurId],
    );
    for (final c in campagnes) {
      await db.delete('campagnes', where: 'id = ?', whereArgs: [c['id']]);
    }
  }

  // ═══════════════════════════════════════════════
  // ⚙️ CONFIGURATION
  // ═══════════════════════════════════════════════

  /// Récupère la configuration (ou la crée par défaut si elle n'existe pas).
  Future<ConfigApp> getConfig() async {
    final db = await database;
    final rows = await db.query('parametres_globaux', limit: 1);
    if (rows.isEmpty) {
      final config = ConfigApp();
      await db.insert('parametres_globaux', config.toMap());
      return config;
    }
    return ConfigApp.fromMap(rows.first);
  }

  /// Sauvegarde la configuration (remplace la ligne existante).
  Future<void> sauvegarderConfig(ConfigApp config) async {
    final db = await database;
    final rows = await db.query('parametres_globaux', limit: 1);
    if (rows.isEmpty) {
      await db.insert('parametres_globaux', config.toMap());
    } else {
      await db.update(
        'parametres_globaux',
        config.toMap(),
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
    }
  }
}
