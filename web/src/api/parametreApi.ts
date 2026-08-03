import { request } from './request'
import type {
  ParametreGlobalRequestDto,
  ParametreGlobalResponseDto,
} from '../types'

/** Récupère les paramètres globaux (objet unique). */
export async function getParametres(): Promise<ParametreGlobalResponseDto> {
  return request<ParametreGlobalResponseDto>('/parametres')
}

/** Met à jour les paramètres globaux. */
export async function updateParametres(
  payload: ParametreGlobalRequestDto,
): Promise<ParametreGlobalResponseDto> {
  return request<ParametreGlobalResponseDto>('/parametres', {
    method: 'PUT',
    body: JSON.stringify(payload),
  })
}
