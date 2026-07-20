class FuiteMessage {
  final int id;
  final int utilisateurId;
  final String? nomUtilisateur;
  final String? contenuTexte;
  final String? cheminAudio;
  final int? dureeAudioSecondes;
  final String? dateEnvoi;
  final int fuiteId;

  FuiteMessage({
    required this.id,
    required this.utilisateurId,
    this.nomUtilisateur,
    this.contenuTexte,
    this.cheminAudio,
    this.dureeAudioSecondes,
    this.dateEnvoi,
    required this.fuiteId,
  });

  factory FuiteMessage.fromJson(Map<String, dynamic> json) {
    return FuiteMessage(
      id: json['id'] as int,
      utilisateurId: json['utilisateurId'] as int,
      nomUtilisateur: json['nomUtilisateur'] as String?,
      contenuTexte: json['contenuTexte'] as String?,
      cheminAudio: json['cheminAudio'] as String?,
      dureeAudioSecondes: json['dureeAudioSecondes'] as int?,
      dateEnvoi: json['dateEnvoi'] as String?,
      fuiteId: json['fuiteId'] as int,
    );
  }
}
