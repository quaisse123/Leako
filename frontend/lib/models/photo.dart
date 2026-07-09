// 📸 Modèle Photo
// Stocke le chemin du fichier image dans le stockage local du téléphone.

class Photo {
  final int id;
  final int fuiteId;
  final String cheminFichier;
  final String? datePrise;
  final String? annotationsDessin; // JSON des annotations dessinées

  Photo({
    required this.id,
    required this.fuiteId,
    required this.cheminFichier,
    this.datePrise,
    this.annotationsDessin,
  });

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as int,
      fuiteId: map['fuite_id'] as int,
      cheminFichier: map['chemin_fichier'] as String,
      datePrise: map['date_prise'] as String?,
      annotationsDessin: map['annotations_dessin'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fuite_id': fuiteId,
      'chemin_fichier': cheminFichier,
      'date_prise': datePrise,
      'annotations_dessin': annotationsDessin,
    };
  }
}
