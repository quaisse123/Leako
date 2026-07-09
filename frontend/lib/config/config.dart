// ⚙️ Configuration centralisée de l'application
// Toutes les URLs et constantes sont ici, modifiables en un seul endroit.

class AppConfig {
  // ─── Backend API ───────────────────────────────────────────────
  // 🔧 Change l'URL selon ton environnement :
  //   - http://localhost:8080/api  → pour navigateur (web) ✅
  //   - http://10.0.2.2:8080/api  → pour émulateur Android
  //   - http://<IP_PC>:8080/api   → pour vrai téléphone sur le même réseau
  static const String apiBaseUrl = 'http://localhost:8080/api';

  // ─── Utilisateur par défaut (pour le développement) ────────────
  // Plus tard, ce sera l'ID de l'utilisateur connecté après login
  static const int defaultUtilisateurId = 1;
}
