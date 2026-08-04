import { requestMultipart, request } from './request'
import type { PhotoResponseDto } from '../types'

/**
 * Upload une photo/vidéo pour une fuite.
 * Endpoint backend : POST /api/photos/upload (multipart).
 */
export async function uploadPhoto(
  fuiteId: number,
  file: File,
  datePrise?: string,
): Promise<PhotoResponseDto> {
  const formData = new FormData()
  formData.append('file', file)
  formData.append('fuiteId', String(fuiteId))
  if (datePrise) formData.append('datePrise', datePrise)
  return requestMultipart<PhotoResponseDto>('/photos/upload', formData)
}

/** Liste les photos d'une fuite (limit optionnelle, comme le mobile). */
export async function getPhotosByFuite(
  fuiteId: number,
  limit?: number,
): Promise<PhotoResponseDto[]> {
  const qs = limit && limit > 0 ? `&limit=${limit}` : ''
  return request<PhotoResponseDto[]>(`/photos?fuiteId=${fuiteId}${qs}`)
}

/** Récupère une photo par ID. */
export async function getPhotoById(id: number): Promise<PhotoResponseDto> {
  return request<PhotoResponseDto>(`/photos/${id}`)
}

/** Supprime une photo. */
export async function deletePhoto(photoId: number): Promise<void> {
  await request<unknown>(`/photos/${photoId}`, { method: 'DELETE' })
}
