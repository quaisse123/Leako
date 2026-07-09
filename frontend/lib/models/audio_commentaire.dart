// 🎙️ Modèle AudioCommentaire
// Stocke le chemin du fichier audio dans le stockage local du téléphone.

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

  factory AudioCommentaire.fromMap(Map<String, dynamic> map) {
    return AudioCommentaire(
      id: map['id'] as int,
      fuiteId: map['fuite_id'] as int,
      cheminFichier: map['chemin_fichier'] as String,
      dureeSecondes: map['duree_secondes'] as int?,
      dateEnregistrement: map['date_enregistrement'] as String?,
      transcription: map['transcription'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fuite_id': fuiteId,
      'chemin_fichier': cheminFichier,
      'duree_secondes': dureeSecondes,
      'date_enregistrement': dateEnregistrement,
      'transcription': transcription,
    };
  }
}
