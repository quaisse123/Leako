# 📋 Rapport d'avancement — LEAKO

**Application :** LEAKO (Leak Overview) — Inspection des fuites de vapeur OCP  
**Architecture :** 100% mobile (Flutter) — Base de données locale SQLite — Aucun serveur requis  
**Dernière mise à jour :** 06/07/2026

---

## ✅ Fonctionnalités réalisées

### 🔐 Authentification
- Création de compte technicien (nom, email, mot de passe)
- Connexion / Déconnexion
- Session persistante (l'app reste connectée même après fermeture)

### 🏠 Page d'accueil
- Barre de navigation inférieure (4 onglets)
- Menu latéral avec profil utilisateur
- Logo OCP

### 📊 Tableau de bord
- Statistiques : pertes financières (MAD/an), émissions CO₂ (tonnes/an), fuites actives, taux de réparation
- Tableau des dernières fuites avec statuts colorés

### 📋 Gestion des campagnes
- **CRUD complet** : Créer, modifier, supprimer des campagnes
- Liste avec recherche, filtre (actives uniquement), tri
- Statut visuel : Active (vert) / Clôturée (gris)
- Suppression d'une campagne avec suppression en cascade (fuites + photos)

### 💧 Gestion des fuites
- **CRUD complet** : Créer, modifier, supprimer des fuites
- Création de fuite avec :
  - Sélection de campagne
  - Tag, date/heure, statut, type de vapeur, pression
  - Localisation (zone texte)
  - **Capture GPS** (coordonnées précises, fonctionne sans Internet)
  - **Google Maps** (ouvre la position sur la carte — nécessite Internet)
  - Description
  - Photos (appareil photo ou galerie, multi-sélection)
  - Vidéo (max 30 secondes)
- Modification de fuite avec re-capture GPS possible
- Sélection multiple pour suppression ou changement de statut en lot
- Recherche, filtre par statut, tri

### ⚙️ Configuration OCP (Pas encore utilise pour faire le calcul)
- Heures de fonctionnement par jour
- Jours de fonctionnement par an
- Coût du kWh (MAD)

### 🗺️ GPS
- Capture de position avec haute précision
- Vérification de la permission et activation du GPS
- Sauvegarde des coordonnées en base de données
- Ouverture dans Google Maps avec vérification de connexion

### 🎤 Saisie vocale
- Bouton micro sur le formulaire de création de campagne
- Reconnaissance vocale en français
- Arrêt automatique au silence

### 📸 Photos & Vidéos
- Prise de photo (caméra)
- Sélection multi-photos (galerie)
- Enregistrement et sélection de vidéo
- Compression automatique des images
- Aperçu avec suppression

### 🗄️ Base de données locale
- 6 tables : utilisateurs, campagnes, fuites, photos, audio, paramètres
- Toutes les données sont stockées localement sur l'appareil
- Fonctionne 100% sans Internet

---

## ❌ Non fonctionnel / À faire

| Fonctionnalité | Statut |
|---|---|
| **Page Rapports & Analyses** | Page vide (placeholder) |
| **Commentaires audio** | Table en base mais pas d'interface |
| **Annotations / dessins sur photos** | Champ prévu en base mais pas d'UI |
| **Synchronisation vers un serveur** | Non démarré (app 100% locale) |
| **Reconnaissance vocale sur Xiaomi/MIUI** | Problème connu — la permission micro ne s'affiche pas correctement |

---

## 📦 Technologies utilisées

- **Flutter** 3.41.2 — Framework mobile
- **SQLite** (sqflite) — Base de données locale
- **Geolocator** — GPS
- **Google Maps** (url_launcher) — Visualisation carte
- **speech_to_text** — Reconnaissance vocale
- **image_picker** — Photos / Vidéos
- **permission_handler** — Gestion des permissions
- **flutter_secure_storage** — Stockage sécurisé de session
