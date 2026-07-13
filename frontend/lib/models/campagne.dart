class Campagne {
  final int id;
  final String nom;
  final String? description;
  final String? zone;
  final bool estCloturee;
  final String dateCreation;
  final int createurId;
  final String? createurNom;
  final int nombreFuites;

  Campagne({
    required this.id,
    required this.nom,
    this.description,
    this.zone,
    required this.estCloturee,
    required this.dateCreation,
    required this.createurId,
    this.createurNom,
    this.nombreFuites = 0,
  });

  factory Campagne.fromJson(Map<String, dynamic> json) {
    return Campagne(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      zone: json['zone'] as String?,
      estCloturee: json['estCloturee'] as bool,
      dateCreation: json['dateCreation'] as String,
      createurId: json['createurId'] as int,
      createurNom: json['createurNom'] as String?,
      nombreFuites: json['nombreFuites'] as int? ?? 0,
    );
  }
}
