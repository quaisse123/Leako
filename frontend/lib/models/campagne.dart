// 📦 Modèle Campagne
// Adapté au schéma SQLite local : plus de ManyToMany, plus de liste d'utilisateurs.
// Chaque campagne appartient à un seul utilisateur (via utilisateurId).

class Campagne {
  final int id;
  final String nom;
  final String? description;
  final String? zone;
  final bool estCloturee;
  final String dateCreation;
  final int utilisateurId;
  final int nombreFuites;

  Campagne({
    required this.id,
    required this.nom,
    this.description,
    this.zone,
    required this.estCloturee,
    required this.dateCreation,
    required this.utilisateurId,
    this.nombreFuites = 0,
  });

  /// Crée une Campagne depuis un JSON (réponse API backend).
  factory Campagne.fromJson(Map<String, dynamic> json) {
    return Campagne(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      zone: json['zone'] as String?,
      estCloturee: json['estCloturee'] as bool,
      dateCreation: json['dateCreation'] as String,
      utilisateurId: json['utilisateurId'] as int? ?? 0,
    );
  }

  /// Crée une Campagne depuis une ligne de la DB SQLite.
  factory Campagne.fromMap(Map<String, dynamic> map) {
    return Campagne(
      id: map['id'] as int,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      zone: map['zone'] as String?,
      estCloturee: (map['est_cloturee'] as int) == 1,
      dateCreation: map['date_creation'] as String,
      utilisateurId: map['utilisateur_id'] as int,
      nombreFuites: (map['nombre_fuites'] as int?) ?? 0,
    );
  }

  /// Convertit en Map pour insertion dans SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'zone': zone,
      'est_cloturee': estCloturee ? 1 : 0,
      'date_creation': dateCreation,
      'utilisateur_id': utilisateurId,
    };
  }
}
