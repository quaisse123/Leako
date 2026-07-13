class AudioCommentaire {
  final int id;
  final int fuiteId;
  final String cheminFichier;
  final int? dureeSecondes;
  final String? dateEnregistrement;
  final String? transcription;

  AudioCommentaire({
    required this.id,
    required this.fuiteId,
    required this.cheminFichier,
    this.dureeSecondes,
    this.dateEnregistrement,
    this.transcription,
  });

  factory AudioCommentaire.fromJson(Map<String, dynamic> json) {
    return AudioCommentaire(
      id: json['id'] as int,
      fuiteId: json['fuiteId'] as int,
      cheminFichier: json['cheminFichier'] as String,
      dureeSecondes: json['dureeSecondes'] as int?,
      dateEnregistrement: json['dateEnregistrement'] as String?,
      transcription: json['transcription'] as String?,
    );
  }
}
