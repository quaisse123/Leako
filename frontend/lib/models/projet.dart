class ProjetMembre {
  final int id;
  final int utilisateurId;
  final String utilisateurNom;
  final String utilisateurEmail;
  final String statut;
  final String? dateInvitation;
  final String? dateReponse;

  ProjetMembre({
    required this.id,
    required this.utilisateurId,
    required this.utilisateurNom,
    this.utilisateurEmail = '',
    required this.statut,
    this.dateInvitation,
    this.dateReponse,
  });

  factory ProjetMembre.fromJson(Map<String, dynamic> json) {
    return ProjetMembre(
      id: json['id'] as int,
      utilisateurId: json['utilisateurId'] as int,
      utilisateurNom: json['utilisateurNom'] as String? ?? '',
      utilisateurEmail: json['utilisateurEmail'] as String? ?? '',
      statut: json['statut'] as String? ?? 'INVITE',
      dateInvitation: json['dateInvitation'] as String?,
      dateReponse: json['dateReponse'] as String?,
    );
  }
}

class Projet {
  final int id;
  final String nom;
  final String? description;
  final String dateCreation;
  final int createurId;
  final String createurNom;
  final int membresCount;
  final List<ProjetMembre> membres;

  Projet({
    required this.id,
    required this.nom,
    this.description,
    required this.dateCreation,
    required this.createurId,
    required this.createurNom,
    this.membresCount = 0,
    this.membres = const [],
  });

  factory Projet.fromJson(Map<String, dynamic> json) {
    return Projet(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      dateCreation: json['dateCreation'] as String? ?? '',
      createurId: json['createurId'] as int,
      createurNom: json['createurNom'] as String? ?? '',
      membresCount: json['membresCount'] as int? ?? 0,
      membres:
          (json['membres'] as List<dynamic>?)
              ?.map((e) => ProjetMembre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
