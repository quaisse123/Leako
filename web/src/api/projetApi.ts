import { request } from './request'
import { getUser } from './jwtService'
import type {
  ProjetRequestDto,
  ProjetResponseDto,
  InvitationResponseDto,
  UtilisateurResponseDto,
} from '../types'

/** ID de l'utilisateur connecté (depuis localStorage). */
function getUtilisateurId(): number {
  return getUser()?.id ?? 0
}

/** Liste les projets de l'utilisateur connecté. */
export async function getProjets(): Promise<ProjetResponseDto[]> {
  return request<ProjetResponseDto[]>(`/projets?utilisateurId=${getUtilisateurId()}`)
}

/** Récupère un projet par ID. */
export async function getProjetById(id: number): Promise<ProjetResponseDto> {
  return request<ProjetResponseDto>(`/projets/${id}?utilisateurId=${getUtilisateurId()}`)
}

/** Crée un projet. */
export async function createProjet(payload: ProjetRequestDto): Promise<ProjetResponseDto> {
  return request<ProjetResponseDto>(`/projets?createurId=${getUtilisateurId()}`, {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

/** Met à jour un projet. */
export async function updateProjet(id: number, payload: ProjetRequestDto): Promise<ProjetResponseDto> {
  return request<ProjetResponseDto>(`/projets/${id}?utilisateurId=${getUtilisateurId()}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  })
}

/** Supprime un projet. */
export async function deleteProjet(id: number): Promise<void> {
  await request<unknown>(`/projets/${id}?utilisateurId=${getUtilisateurId()}`, { method: 'DELETE' })
}

/** Récupère les invitations en attente de l'utilisateur connecté. */
export async function getMesInvitations(): Promise<InvitationResponseDto[]> {
  return request<InvitationResponseDto[]>(`/projets/invitations?utilisateurId=${getUtilisateurId()}`)
}

/** Répond à une invitation (accepter/refuser). */
export async function repondreInvitation(invitationId: number, accepte: boolean): Promise<InvitationResponseDto> {
  return request<InvitationResponseDto>(
    `/projets/invitations/${invitationId}?accepte=${accepte}&utilisateurId=${getUtilisateurId()}`,
    { method: 'PUT' },
  )
}

/** Invite un utilisateur dans un projet (owner). */
export async function inviterMembre(projetId: number, utilisateurIdInvite: number): Promise<InvitationResponseDto> {
  return request<InvitationResponseDto>(`/projets/${projetId}/invitations?createurId=${getUtilisateurId()}`, {
    method: 'POST',
    body: JSON.stringify({ utilisateurId: utilisateurIdInvite }),
  })
}

/** Récupère les invitations en attente pour un projet donné (owner). */
export async function getInvitationsByProjet(projetId: number): Promise<InvitationResponseDto[]> {
  return request<InvitationResponseDto[]>(`/projets/${projetId}/invitations?utilisateurId=${getUtilisateurId()}`)
}

/** Retire un membre du projet (owner only). */
export async function retirerMembre(projetId: number, membreId: number): Promise<void> {
  await request<unknown>(`/projets/${projetId}/membres/${membreId}?createurId=${getUtilisateurId()}`, {
    method: 'DELETE',
  })
}

/** Quitte un projet (member only). */
export async function quitterProjet(projetId: number): Promise<void> {
  await request<unknown>(`/projets/${projetId}/quitter?utilisateurId=${getUtilisateurId()}`, {
    method: 'POST',
  })
}

/** Liste tous les utilisateurs (pour l'autocomplétion d'invitation). */
export async function getAllUtilisateurs(): Promise<UtilisateurResponseDto[]> {
  return request<UtilisateurResponseDto[]>('/utilisateurs')
}
