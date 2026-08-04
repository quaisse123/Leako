class Utilisateur {
  final int id;
  final String nom;
  final String prenom;
  final String email;

  const Utilisateur({
    required this.id,
    required this.nom,
    this.prenom = '',
    required this.email,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String,
    );
  }

  /// Nom complet affiché : "Prénom Nom" (fallback : nom seul).
  String get nomComplet => prenom.isNotEmpty ? '$prenom $nom' : nom;

  /// Initiales pour l'avatar (ex: "MQ" pour Marouane Quaisse).
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }
}
