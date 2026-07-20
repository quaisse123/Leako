# 📊 Métriques du Rapport — LEAKO

> Document de référence pour l'implémentation de la page **Rapports & Analyses**.

---

## 🎯 Top Priority — 2 infos clés

| # | Métrique | Description | Source |
|---|---|---|---|
| 1 | **Coût estimé des fuites actives** | Somme des `coutAnnuelEstime` des fuites non réparées (A_REPARER + EN_COURS) sur la période | `Fuite.coutAnnuelEstime` |
| 2 | **Économies réalisées** | Somme des `coutAnnuelEstime` des fuites réparées (REPAREE) sur la période | `Fuite.coutAnnuelEstime` |

---

## 📋 Métriques détaillées

### 1. Nombre total de fuites + Nombre par campagne

| Champ | Description |
|---|---|
| Total fuites (période) | Nombre de fuites dans la période sélectionnée |
| Par campagne | Liste : `Campagne.nom` → `count(fuites)` |

### 2. Pertes financières estimées par campagne vs Économies par campagne

| Champ | Description |
|---|---|
| Pertes par campagne | Somme des `coutAnnuelEstime` des fuites actives, groupée par `campagneNom` |
| Économies par campagne | Somme des `coutAnnuelEstime` des fuites réparées, groupée par `campagneNom` |

### 3. Coût total des fuites par statut

| Statut | Calcul |
|---|---|
| `A_REPARER` | Somme des `coutAnnuelEstime` |
| `EN_COURS` | Somme des `coutAnnuelEstime` |
| `REPAREE` | Somme des `coutAnnuelEstime` |
| `ANNULEE` | Somme des `coutAnnuelEstime` |

### 4. Taux de réparation

| Champ | Calcul |
|---|---|
| Taux global | `(nbReparées / nbTotal) × 100` |
| Par campagne | `(nbReparéesCampagne / nbTotalCampagne) × 100` |

### 5. Top 5 fuites actives les plus coûteuses

- Filtrer : statut = `A_REPARER` ou `EN_COURS`
- Trier par `coutAnnuelEstime` descendant
- Prendre les 5 premières

### 6. Top 5 fuites réparées les plus coûteuses

- Filtrer : statut = `REPAREE`
- Trier par `coutAnnuelEstime` descendant
- Prendre les 5 premières

---

## 🥧 Diagrammes circulaires (par campagne)

| Diagramme | Description |
|---|---|
| **Répartition du nombre de fuites** | `count` par campagne → camembert |
| **Répartition des pertes estimées** | Somme `coutAnnuelEstime` (actives) par campagne → camembert |
| **Répartition des économies** | Somme `coutAnnuelEstime` (réparées) par campagne → camembert |

---

## ⚙️ Filtres

| Filtre | Valeurs |
|---|---|
| **Période** | 1 mois · 3 mois · 6 mois · 1 an · Tout |
| **Métriques sélectionnables** | L'utilisateur peut cocher/décocher chaque métrique |

---

## 📐 Structure des données (RapportCalculé)

```dart
class RapportCalcule {
  // Période
  final String periodeLibelle;
  final DateTime dateDebut;
  final DateTime dateFin;

  // Top priority
  final double coutFuitesActives;
  final double economiesRealisees;

  // Compteurs
  final int totalFuites;
  final Map<String, int> fuitesParCampagne;

  // Par campagne
  final Map<String, double> pertesParCampagne;
  final Map<String, double> economiesParCampagne;

  // Par statut
  final Map<String, double> coutParStatut;

  // Taux
  final double tauxReparationGlobal;
  final Map<String, double> tauxReparationParCampagne;

  // Top 5
  final List<Fuite> top5Actives;
  final List<Fuite> top5Reparees;

  // Diagrammes (Map campagne → valeur)
  final Map<String, int> repartitionNbrCampagnes;
  final Map<String, double> repartitionPertesCampagnes;
  final Map<String, double> repartitionEconomiesCampagnes;
}
```

---

## 🖼️ Maquette UI

```
┌──────────────────────────────────────┐
│  🔬 Rapports & Analyses              │
├──────────────────────────────────────┤
│  📅 Période                          │
│  [1 mois] [3 mois] [6 mois] [1 an] [Tout] │
├──────────────────────────────────────┤
│  ☑ Toutes les métriques              │
├──────────────────────────────────────┤
│  💰 COÛT FUITES ACTIVES    🌿 ÉCONOMIES  │
│  2 450 000 MAD             890 000 MAD   │
├──────────────────────────────────────┤
│  📊 Nombre total : 47 fuites         │
│  Campagne A : 12 · Campagne B : 8 …  │
├──────────────────────────────────────┤
│  💸 Pertes vs Économies par campagne  │
│  Campagne A : 1.2M ▼ | 0.5M ▲        │
│  Campagne B : 800k ▼ | 300k ▲        │
├──────────────────────────────────────┤
│  📋 Coût par statut                   │
│  ████ À réparer : 1.5M               │
│  ██ En cours : 950k                  │
│  ██████ Réparée : 890k               │
│  █ Annulée : 50k                     │
├──────────────────────────────────────┤
│  ✅ Taux réparation : 38%             │
│  Campagne A : 45% · Campagne B : 30% │
├──────────────────────────────────────┤
│  🔴 Top 5 fuites actives              │
│  1. Tag #045 — 450 000 MAD           │
│  2. Tag #032 — 320 000 MAD           │
│  ...                                 │
├──────────────────────────────────────┤
│  🟢 Top 5 fuites réparées             │
│  1. Tag #012 — 280 000 MAD           │
│  2. Tag #008 — 195 000 MAD           │
│  ...                                 │
├──────────────────────────────────────┤
│  🥧 Répartition par campagne          │
│  [Camembert Nbr] [Camembert Pertes] [Camembert Éco] │
├──────────────────────────────────────┤
│  [📄 Générer le rapport]             │
└──────────────────────────────────────┘
```



le user utilise les badge pour choisir la periode 
un shimmer (squelette ) pour un loading userflriendly 
un menu pop up pour la checkliste des metrics (tous coche par defaut )
et on affiche la data pour dans le ui pour le user pour la voir et confimer enfin "Genrer le pdf " (implemetaiton pdf apres) 