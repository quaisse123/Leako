// 📤 UploadProgressService — Suivi des uploads en cours
// Permet au ConnectivityService de ne PAS déclencher de fausse alerte
// "Aucune connexion" pendant qu'un gros fichier (vidéo) est en cours
// d'envoi : la bande passante étant saturée, un ping échouerait à tort.
// Singleton : une seule instance dans toute l'app.

class UploadProgressService {
  UploadProgressService._();
  static final UploadProgressService instance = UploadProgressService._();

  int _activeUploads = 0;

  /// true si au moins un upload est en cours.
  bool get isUploading => _activeUploads > 0;

  /// À appeler juste AVANT de commencer un upload.
  void beginUpload() => _activeUploads++;

  /// À appeler dès que l'upload est terminé (succès OU échec).
  void endUpload() {
    if (_activeUploads > 0) _activeUploads--;
  }
}
