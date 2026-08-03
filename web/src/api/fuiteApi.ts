import { request } from './request'
import type {
  FuiteRequestDto,
  FuiteResponseDto,
} from '../types'

/** Liste les fuites (par projet ou campagne — le backend exige l'un des deux). */
export async function getFuites(params?: {
  campagneId?: number
  projetId?: number
}): Promise<FuiteResponseDto[]> {
  const query = new URLSearchParams()
  if (params?.campagneId != null) query.set('campagneId', String(params.campagneId))
  if (params?.projetId != null) query.set('projetId', String(params.projetId))
  const qs = query.toString()
  return request<FuiteResponseDto[]>(`/fuites${qs ? `?${qs}` : ''}`)
}

/** Récupère une fuite par ID. */
export async function getFuiteById(id: number): Promise<FuiteResponseDto> {
  return request<FuiteResponseDto>(`/fuites/${id}`)
}

/** Crée une fuite. */
export async function createFuite(payload: FuiteRequestDto): Promise<FuiteResponseDto> {
  return request<FuiteResponseDto>('/fuites', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

/** Met à jour une fuite. */
export async function updateFuite(id: number, payload: FuiteRequestDto): Promise<FuiteResponseDto> {
  return request<FuiteResponseDto>(`/fuites/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  })
}

/** Supprime une fuite. */
export async function deleteFuite(id: number): Promise<void> {
  await request<unknown>(`/fuites/${id}`, { method: 'DELETE' })
}

/** Génère le prochain tag de fuite pour une campagne. */
export async function getProchainTag(
  campagneNom: string,
  campagneId?: number,
): Promise<string> {
  const query = new URLSearchParams({ campagneNom })
  if (campagneId != null) query.set('campagneId', String(campagneId))
  return request<string>(`/fuites/prochain-tag?${query.toString()}`)
}
