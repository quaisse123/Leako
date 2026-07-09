// 🔐 SessionService — Maintient la session utilisateur de façon sécurisée
// Utilise flutter_secure_storage (chiffré au niveau OS)
// Pas de mot de passe en clair stocké, seulement l'ID, nom et email

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static final SessionService _instance = SessionService._();
  factory SessionService() => _instance;
  SessionService._();

  final _storage = const FlutterSecureStorage();

  static const _keyUserId = 'session_user_id';
  static const _keyUserNom = 'session_user_nom';
  static const _keyUserEmail = 'session_user_email';

  /// Sauvegarde la session après connexion ou inscription
  Future<void> sauvegarderSession({
    required int userId,
    required String nom,
    required String email,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: userId.toString()),
      _storage.write(key: _keyUserNom, value: nom),
      _storage.write(key: _keyUserEmail, value: email),
    ]);
  }

  /// Vérifie si une session existe et retourne les infos user
  Future<Map<String, dynamic>?> getSession() async {
    final id = await _storage.read(key: _keyUserId);
    if (id == null) return null;

    final nom = await _storage.read(key: _keyUserNom);
    final email = await _storage.read(key: _keyUserEmail);

    if (nom == null || email == null) {
      await effacerSession();
      return null;
    }

    return {'id': int.parse(id), 'nom': nom, 'email': email};
  }

  /// Efface la session (logout)
  Future<void> effacerSession() async {
    await Future.wait([
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUserNom),
      _storage.delete(key: _keyUserEmail),
    ]);
  }
}
