import { request } from './request'
import { getUser } from './jwtService'
import type {
  ProjetRequestDto,
  ProjetResponseDto,
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
