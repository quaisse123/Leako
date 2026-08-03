import { request } from './request'
import type {
  CampagneRequestDto,
  CampagneResponseDto,
} from '../types'

/** Liste les campagnes d'un projet (le backend exige projetId). */
export async function getCampagnes(projetId: number): Promise<CampagneResponseDto[]> {
  return request<CampagneResponseDto[]>(`/campagnes?projetId=${projetId}`)
}

/** Récupère une campagne par ID. */
export async function getCampagneById(id: number): Promise<CampagneResponseDto> {
  return request<CampagneResponseDto>(`/campagnes/${id}`)
}

/** Crée une campagne. */
export async function createCampagne(payload: CampagneRequestDto): Promise<CampagneResponseDto> {
  return request<CampagneResponseDto>('/campagnes', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

/** Met à jour une campagne. */
export async function updateCampagne(id: number, payload: CampagneRequestDto): Promise<CampagneResponseDto> {
  return request<CampagneResponseDto>(`/campagnes/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  })
}

/** Supprime une campagne. */
export async function deleteCampagne(id: number): Promise<void> {
  await request<unknown>(`/campagnes/${id}`, { method: 'DELETE' })
}

/** Met à jour partiellement une campagne (ex: clôturer / réouvrir). */
export async function patchCampagne(
  id: number,
  payload: { estCloturee: boolean },
): Promise<CampagneResponseDto> {
  return request<CampagneResponseDto>(`/campagnes/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  })
}
