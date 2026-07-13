class Utilisateur {
  final int id;
  final String nom;
  final String email;

  Utilisateur({required this.id, required this.nom, required this.email});

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] as int,
      nom: json['nom'] as String,
      email: json['email'] as String,
    );
  }
}
