/** ─── DTOs — correspondance avec le backend Spring Boot ─── */

// ─── Auth ──────────────────────────────────────────────────────────
export interface LoginRequestDto {
  email: string;
  motDePasse: string;
}

export interface RegisterRequestDto {
  nom: string;
  prenom: string;
  email: string;
  motDePasse: string;
  role?: string;
}

export interface LoginResponseDto {
  accessToken: string;
  refreshToken?: string;
  userId?: string;
  userNom?: string;
  userEmail?: string;
  error?: string;
}

// ─── Utilisateur ───────────────────────────────────────────────────
export interface UtilisateurResponseDto {
  id: number;
  nom: string;
  prenom: string;
  email: string;
  role: string;
}

// ─── Projet ────────────────────────────────────────────────────────
export interface ProjetRequestDto {
  nom: string;
  description?: string;
}

export interface ProjetMembreDto {
  id: number;
  utilisateurId: number;
  utilisateurNom: string;
  utilisateurEmail: string;
  statut: string;
  dateInvitation?: string;
  dateReponse?: string;
}

export interface ProjetResponseDto {
  id: number;
  nom: string;
  description?: string;
  dateCreation?: string;
  createurId?: number;
  createurNom?: string;
  membresCount?: number;
  membres?: ProjetMembreDto[];
}

// ─── Campagne ──────────────────────────────────────────────────────
export interface CampagneRequestDto {
  nom: string;
  description?: string;
  zone?: string;
  estCloturee?: boolean;
  createurId?: number;
  projetId?: number;
}

export interface CampagneResponseDto {
  id: number;
  nom: string;
  dateCreation?: string;
  description?: string;
  zone?: string;
  estCloturee?: boolean;
  createurId?: number;
  createurNom?: string;
  projetId?: number;
  fuiteIds?: number[];
  nombreFuites?: number;
}

// ─── Fuite ─────────────────────────────────────────────────────────
export type StatutFuite = 'A_REPARER' | 'EN_COURS' | 'REPAREE' | 'ANNULEE'

export type TypeVapeur =
  | 'VAPEUR_SATUREE'
  | 'VAPEUR_SURCHAUFFEE'
  | 'VAPEUR_HAUTE_PRESSION'
  | 'VAPEUR_BASSE_PRESSION'
  | 'VAPEUR_RESIDUELLE'

export interface FuiteRequestDto {
  numeroTag?: string;
  dateDetection: string;
  statut: StatutFuite;
  pressionBar?: number;
  diametreOrifice?: number;
  typeVapeur?: TypeVapeur;
  gpsLatitude?: number;
  gpsLongitude?: number;
  zone?: string;
  description?: string;
  coutAnnuelEstime?: number;
  campagneId: number;
}

export interface FuiteResponseDto {
  id: number;
  numeroTag?: string;
  dateDetection?: string;
  statut?: StatutFuite;
  pressionBar?: number;
  diametreOrifice?: number;
  typeVapeur?: TypeVapeur;
  gpsLatitude?: number;
  gpsLongitude?: number;
  zone?: string;
  description?: string;
  coutAnnuelEstime?: number;
  campagneId?: number;
  campagneNom?: string;
  photoIds?: number[];
  audioCommentaireIds?: number[];
}

// ─── Photo ─────────────────────────────────────────────────────────
export interface PhotoResponseDto {
  id: number;
  cheminFichier?: string;
  thumbnailUrl?: string;
  datePrise?: string;
  annotationsDessin?: string;
  fuiteId?: number;
}

// ─── Message de fuite ──────────────────────────────────────────────
export interface FuiteMessageRequestDto {
  fuiteId: number;
  utilisateurId: number;
  contenuTexte?: string;
  dureeAudioSecondes?: number;
}

export interface FuiteMessageResponseDto {
  id: number;
  fuiteId: number;
  utilisateurId: number;
  utilisateur?: UtilisateurResponseDto;
  contenuTexte?: string;
  audioUrl?: string;
  dureeAudioSecondes?: number;
  createdAt: string;
}

// ─── Paramètre global ──────────────────────────────────────────────
export interface ParametreGlobalResponseDto {
  id: number;
  devise?: string;
  coutVapeurParTonne?: number;
  heuresFonctionnementAnnuelles?: number;
  facteurEmissionCO2?: number;
  langue?: string;
  heuresActiviteParJour?: number;
  joursActiviteParAn?: number;
  coutKwhDiram?: number;
}

export interface ParametreGlobalRequestDto {
  devise?: string;
  coutVapeurParTonne?: number;
  heuresFonctionnementAnnuelles?: number;
  facteurEmissionCO2?: number;
  langue?: string;
  heuresActiviteParJour?: number;
  joursActiviteParAn?: number;
  coutKwhDiram?: number;
}

// ─── Rapport ───────────────────────────────────────────────────────
export interface RapportResponseDto {
  id: number;
  titre: string;
  url?: string;
  campagneId?: number;
  createdAt?: string;
}

// ─── Statistiques dashboard ────────────────────────────────────────
export interface DashboardStatsDto {
  totalFuites: number;
  fuitesResolues: number;
  fuitesEnCours: number;
  fuitesCritiques: number;
  totalCampagnes: number;
  totalProjets: number;
}
