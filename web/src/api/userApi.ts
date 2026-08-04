import { request } from './request'
import type {
  ChangerMotDePasseRequestDto,
  UpdateProfilRequestDto,
  UtilisateurResponseDto,
} from '../types'

/** Récupère le profil complet de l'utilisateur connecté (GET /utilisateurs/me). */
export async function getMe(): Promise<UtilisateurResponseDto> {
  return request<UtilisateurResponseDto>('/utilisateurs/me')
}

/** Met à jour nom / prénom / email de l'utilisateur connecté (PUT /utilisateurs/me). */
export async function updateProfil(
  payload: UpdateProfilRequestDto,
): Promise<UtilisateurResponseDto> {
  return request<UtilisateurResponseDto>('/utilisateurs/me', {
    method: 'PUT',
    body: JSON.stringify(payload),
  })
}

/** Change le mot de passe de l'utilisateur connecté (PUT /utilisateurs/me/mot-de-passe). */
export async function changerMotDePasse(
  payload: ChangerMotDePasseRequestDto,
): Promise<{ message?: string }> {
  return request<{ message?: string }>('/utilisateurs/me/mot-de-passe', {
    method: 'PUT',
    body: JSON.stringify(payload),
  })
}
