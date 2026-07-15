class Photo {
  final int id;
  final int fuiteId;
  final String cheminFichier;
  final String? thumbnailUrl;
  final String? datePrise;
  final String? annotationsDessin;

  Photo({
    required this.id,
    required this.fuiteId,
    required this.cheminFichier,
    this.thumbnailUrl,
    this.datePrise,
    this.annotationsDessin,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int,
      fuiteId: json['fuiteId'] as int,
      cheminFichier: json['cheminFichier'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      datePrise: json['datePrise'] as String?,
      annotationsDessin: json['annotationsDessin'] as String?,
    );
  }
}
